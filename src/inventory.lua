local cont  = require("src.contents")
local inp   = require("src.inputs")
local cfg   = require("utils.config_reader")
local plan  = require("src.plan")

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
--   `contents`   : An instance of contents
--                  that keeps track of the
--                  inventory contents.
--   `inputs`     : An instance of inputs
--                  that keeps track of the IDs
--                  of input peripherals.
--   `stacks_path`: Filename of the document that
--                  describes the known items'
--                  stack sizes.
--   `stacks`     : Associative table that maps
--                  an item name to a stack size.
function inventory.new
(contents_path, inputs_path, stacks_path)
    local self = setmetatable({
        contents      = cont.new(contents_path),
        inputs        = inp.new(inputs_path),
        stacks_path   = stacks_path,
        stacks        = nil
    }, inventory)
    self.inputs:load()
    return self
end

-- TODO: clean up this
function inventory:load_stack()
    if self.stacks then return end
    local file = io.open(self.stacks_path)
    if not file
        then self.stacks = {}
        return
    end
    local text = file:read('a')
    file:close()
    self.stacks = textutils.unserialize(text) or {}
end

function inventory:load(noscan)
    self:load_stack()
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
    plan.execute_plans(plans)
    
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

-- TODO: clean up this
function inventory:update_stacksize()
    self:load()
    local file = io.open(self.stacks_path, 'w')
    if not file then return end
    local item_equality = function(a, b)
        return a.name == b.name
    end
    local func = function(chest_id, slot, item)
        local chest = peripheral.wrap(chest_id)
        local item  = chest.getItemDetail(slot)
        self.stacks[item.name] = item.maxCount
    end
    self:for_each_input_slot(func)
    file:write(textutils.serialize(self.stacks))
    file:close()
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

return inventory
