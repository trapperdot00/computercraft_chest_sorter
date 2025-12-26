-- Class data members
local con = require("src.contents")
local inp = require("src.inputs")
local sta = require("src.stacks")

-- Utilities
local cfg  = require("utils.config_reader")
local tbl  = require("utils.table_utils")
local tskp = require("utils.task_pool")
local plan = require("src.plan")

-- Commands
local push  = require("src.cmd.push")
local pull  = require("src.cmd.pull")
local size  = require("src.cmd.size")
local usage = require("src.cmd.usage")
local get   = require("src.cmd.get")
local count = require("src.cmd.count")
local find  = require("src.cmd.find")

local inventory = {}
inventory.__index = inventory

-- Constructs and returns a new instance
-- of inventory
-- Fields:
--   `task_pool`  : An instance of task_pool,
--                  manages the parallelized
--                  execution of tasks.
--   `connected`  : Array of currently visible,
--                  connected inventory
--                  peripherals on the network.
--   `contents`   : An instance of contents
--                  that keeps track of the
--                  inventory contents.
--   `inputs`     : An instance of inputs
--                  that keeps track of the IDs
--                  of input peripherals.
--   `stacks`     : An instance of stacks
--                  that keeps track of each
--                  item's maximum stack size.
function inventory.new
(contents_path, inputs_path, stacks_path)
    local task_pool = tskp.new(500)
    local self = setmetatable({
        task_pool = task_pool,
        connected = {peripheral.find("inventory")},
        contents  = con.new(
                        contents_path, task_pool
                    ),
        inputs    = inp.new(inputs_path),
        stacks    = sta.new(stacks_path)
    }, inventory)
    if #self.connected == 0 then
        error("No chests found on the network!", 0)
    end
    self.inputs:load()
    return self
end

function inventory:load(noscan)
    local eq = function(p, id)
        return peripheral.getName(p) == id
    end
    for _, input in ipairs(self.inputs.data) do
        if not tbl.contains(
            self.connected, input, eq
        ) then
            error(
                "Input '" .. input ..
                "' not connected!",
                0
            )
        end
    end
    self.stacks:load()
    self.contents:load() 
    if not noscan then
        self:scan_inputs()
    end
end

-- Executes a given list of item-moving plans
-- and updates the affected
-- inventories' databases.
function inventory:carry_out(plans)
    -- Move the specified items
    plan.execute_plans(plans, self.task_pool)
    
    -- Update affected chests in memory
    local affected = plan.get_affected_chests(plans)
    for _, id in ipairs(affected) do
        print("updating", id)
        self.contents:update(id)
    end

    -- Update chest database file
    if #affected > 0 then
        print("saving to file", self.contents.filename)
        self.contents:save_to_file()
    end
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest if it is an input chest.
function inventory:for_each_input_chest(func)
    local f = function(chest_id, contents)
        if self.inputs:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper for `for_each_chest` that
-- only calls `func` for a given chest
-- if it is an output chest.
function inventory:for_each_output_chest(func)
    local f = function(chest_id, contents)
        if not self.inputs:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper that iterates over
-- each input chest's slots.
function inventory:for_each_input_slot(func)
    local f = function(chest_id, contents)
        self.contents:for_each_slot_in(
            chest_id, contents, func
        )
    end
    self:for_each_input_chest(f)
end

-- Wrapper that iterates over
-- each output chest's slots.
function inventory:for_each_output_slot(func)
    local f = function(chest_id, contents)
        self.contents:for_each_slot_in(
            chest_id, contents, func
        )
    end
    self:for_each_output_chest(f)
end

-- Updates stack size database
-- with the items inside
-- the input inventory peripherals.
function inventory:update_stacksize()
    self:load()
    local func = function(id, slot, item)
        local inv  = peripheral.wrap(id)
        local item = inv.getItemDetail(slot)
        self.stacks:update_or_add(
            item.name, item.maxCount
        )
    end
    self:for_each_input_slot(func)
    self.stacks:save_to_file()
end

-- Push items from the input peripherals
-- into the output peripherals.
function inventory:push()
    self:update_stacksize()
    local plans = push.get_plans(self)
    self:carry_out(plans)
end

-- Push items from the output peripherals
-- into the input peripherals.
function inventory:pull()
    local plans = pull.get_plans(self)
    self:carry_out(plans)
end

function inventory:size()
    local in_slots, out_slots = size.size(self)
    local full_slots = in_slots + out_slots
    print("[IN] :", in_slots)
    print("[OUT]:", out_slots)
    print("[ALL]:", full_slots)
end

function inventory:usage()
    local total, used = usage.usage(self)
    local percent = (used / total) * 100
    print("[USED]:", used)
    print("[ALL] :", total)
    print("["..tostring(percent).."%]")
end

function inventory:get(sought_items)
    local plans = get.get_plans(self, sought_items)
    self:carry_out(plans)
end

function inventory:count(sought_items)
    for _, item in ipairs(sought_items) do
        local cnt = count.count(self, item)
        print(item, cnt)
    end
end

function inventory:find(sought_items)
    for _, item in ipairs(sought_items) do
        local chests = find.find(self, item)
        for _, chest_id in ipairs(chests) do
            print(item, "->", chest_id)
        end
    end
end

function inventory:scan()
    self.contents:scan()
end

function inventory:scan_inputs()
    for _, inv_id in ipairs(self.inputs.data) do
        self.contents:update(inv_id)
    end
end

function inventory:configure()
    self.inputs:configure()
end

return inventory
