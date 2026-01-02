-- Class data members
local con = require("src.contents")
local inp = require("src.inputs")
local sta = require("src.stacks")

-- Utilities
local inv_db  = require("src.inv_db")
local iter    = require("src.iterator")
local fiter   = require("src.filter_iterator")
local plan    = require("src.plan")
local tbl     = require("utils.table_utils")
local tskp    = require("utils.task_pool")
local planner = require("src.move_planner")

-- Commands
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
    local affected = plan.affected_chests(plans)
    for _, id in ipairs(affected) do
        print("updating", id)
        self.contents:update(id)
    end

    -- Update chest database file
    if #affected > 0 then
        print(
            "saving to file", 
            self.contents.filename
        )
        self.contents:save_to_file()
    end
end

local function get_db_builder(db)
    local f = function(inv_id, inv_size, inv_items)
        db:add_inv(inv_id, inv_size)
        for slot, item in pairs(inv_items) do
            db:add_item(inv_id, slot, item)
        end
    end
    return f
end

function inventory:get_input_db()
    local db = inv_db.new()
    local builder = get_db_builder(db)
    self:for_each_input_chest(builder)
    return db
end

function inventory:get_output_db()
    local db = inv_db.new()
    local builder = get_db_builder(db)
    self:for_each_output_chest(builder)
    return db
end

-- Acquire an iterator that traverses input
-- inventory slots.
function inventory:get_input_iterator(predicate)
    local contents = self:get_input_db()
    if predicate then
        return fiter:new(contents, predicate)
    else
        return iter:new(contents)
    end
end

-- Acquire an iterator that traverses output
-- inventory slots.
function inventory:get_output_iterator(predicate)
    local contents = self:get_output_db()
    if predicate then
        return fiter:new(contents, predicate)
    else
        return iter:new(contents)
    end
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest
-- if it is an input chest.
function inventory:for_each_input_chest(func)
    local f = function(inv_id, inv_size, inv_items)
        if self.inputs:is_input_chest(inv_id) then
            func(inv_id, inv_size, inv_items)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper for `for_each_chest` that
-- only calls `func` for a given chest
-- if it is an output chest.
function inventory:for_each_output_chest(func)
    local f = function(inv_id, inv_size, inv_items)
        if not self.inputs:is_input_chest(inv_id)
        then
            func(inv_id, inv_size, inv_items)
        end
    end
    self.contents:for_each_chest(f)
end

-- Wrapper that iterates over
-- each input chest's slots.
function inventory:for_each_input_slot(func)
    local f = function(inv_id, inv_size, inv_items)
        self.contents:for_each_slot_in(
            inv_id, inv_size, inv_items, func
        )
    end
    self:for_each_input_chest(f)
end

-- Wrapper that iterates over
-- each output chest's slots.
function inventory:for_each_output_slot(func)
    local f = function(inv_id, inv_size, inv_items)
        self.contents:for_each_slot_in(
            inv_id, inv_size, inv_items, func
        )
    end
    self:for_each_output_chest(f)
end

-- Updates stack size database
-- with the items inside
-- the input inventory peripherals.
-- Parameters:
--     `incl_outputs`: Boolean flag, if provided
--                     and true, will scan output
--                     slots as well as input
--                     slots for stack sizes.
function inventory:update_stacksize(incl_outputs)
    self:load()
    local func = function(inv_id, inv_size,
                          slot, item)
        local inv  = peripheral.wrap(inv_id)
        local item = inv.getItemDetail(slot)
        if item then
            self.stacks:add(
                item.name, item.maxCount
            )
        end
    end
    self:for_each_input_slot(func)
    if incl_outputs == true then
        self:for_each_output_slot(func)
    end
    self.stacks:save_to_file()
end

local function get_dst_names(self)
    local dsts = {}
    local f = function(inv_id, inv_size, inv_items)
        if not tbl.contains(dsts, inv_id) then
            table.insert(dsts, inv_id)
        end
    end
    self:for_each_output_chest(f)
    return dsts
end

-- Push items from the input peripherals
-- into the output peripherals.
function inventory:push()
    self:update_stacksize()
    local plans = planner.move(
        tbl.deepcopy(self.contents.db),
        self.stacks,
        self.inputs.data,
        get_dst_names(self)
    )
    self:carry_out(plans)
end

-- Push items from the output peripherals
-- into the input peripherals.
function inventory:pull()
    self:load()
    local plans = planner.move(
        tbl.deepcopy(self.contents.db),
        self.stacks,
        get_dst_names(self),
        self.inputs.data
    )
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
    self:update_stacksize(true)
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
