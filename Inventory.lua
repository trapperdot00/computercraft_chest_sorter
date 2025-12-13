local tbl          = require("table_utils")
local chest_parser = require("chest_parser")

local push      = require("cmds.push")
local pull      = require("cmds.pull")
local get       = require("cmds.get")

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(inputs, filename)
    local self = setmetatable({}, Inventory)
    self.inputs   = inputs
    self.filename = filename
    self.contents = nil
    return self
end

function Inventory:load(noscan)
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
        if not noscan then
            self:scan_inputs()
        end
    else
        self:scan()
    end
end

-- Returns the capacity of the given
-- inventory entity referred to as an ID in slots
function Inventory:get_slot_size(chest_id)
    local chest_data = self.contents[chest_id]
    local chest_size = chest_data.size
    return chest_size
end

-- Returns the count of occupied slots
-- of the given inventory object referred to as an ID
function Inventory:get_full_slots(chest_id)
    local chest_data  = self.contents[chest_id]
    local chest_items = chest_data.items
    local full_slots = tbl.size(chest_items)
    return full_slots
end

-- Returns the non-occupied/free slots
-- of the given inventory entity referred to as an ID
function Inventory:get_free_slots(chest_id)
    local slot_size  = self:get_slot_size(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    local free_slots = slot_size - full_slots
    return free_slots
end

-- Returns whether the given inventory entity
-- referred to as an ID
--  -> has only occupied/full slots
--  -> has no more unoccupied/free slots
function Inventory:is_full(chest_id)
    local slot_size  = self:get_slot_size(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    return slot_size == full_slots
end

-- Returns whether the given inventory entity
-- referred to as an ID
--  -> has only unoccupied/free slots
--  -> has no occupied/full slots
function Inventory:is_empty(chest_id)
    local full_slots = self:get_full_slots(chest_id)
    return full_slots == 0
end

-- Checks whether the given inventory entity
-- referred to as an ID
-- is labeled as an input chest
function Inventory:is_input_chest(chest_id)
    return tbl.contains(self.inputs, chest_id)
end

-- Executes a plan to move an item between two chests
--
-- `plan` table's named members:
--   `src`: identifies the source chest by id
--   `dst`: identifies the destination chest by id
--   `src_slot`: identifies an item by its occupied slot
--               to be moved from `src` into `dst`
function Inventory:execute_plan(plan)
    local src      = plan.src
    local dst      = plan.dst
    local src_slot = plan.src_slot

    local src_chest = peripheral.wrap(src)
    src_chest.pushItems(dst, src_slot)
end

-- Execute a list of plans in parallel
function Inventory:execute_plans(plans)
    local tasks = {}
    for _, plan in ipairs(plans) do
        table.insert(tasks,
            function() self:execute_plan(plan) end
        )
    end
    parallel.waitForAll(table.unpack(tasks))
end

-- Returns an array-like table containing
-- the inventory IDs listed inside the given plan-list.
-- The IDs are listed only once.
--
-- `plan` table's named members:
--   `src`: identifies the source chest by id
--   `dst`: identifies the destination chest by id
--   `src_slot`: identifies an item by its occupied slot
--               to be moved from `src` into `dst`
function Inventory:get_affected_chests(plans)
    local affected = {}
    for _, plan in ipairs(plans) do
        if not tbl.contains(affected, plan.src) then
            table.insert(affected, plan.src)
        end
        if not tbl.contains(affected, plan.dst) then
            table.insert(affected, plan.dst)
        end
    end
    return affected
end

-- Executes a given list of item-moving plans
-- and updates the affected inventories' databases.
function Inventory:carry_out(plans)
    self:execute_plans(plans)
    
    -- Update affected chests in memory
    local affected = self:get_affected_chests(plans)
    for _, id in ipairs(affected) do
        print("updating", id)
        self:update_chest(id)
    end

    -- Update chest database file
    if #affected > 0 then
        print("saving to file", self.filename)
        self:save_contents()
    end
end

-- Push items from the input chests into the output chests.
function Inventory:push()
    local plans = push.get_push_plans(self)
    self:carry_out(plans)
end

-- Pull items from the output chests into the input chests.
function Inventory:pull()
    local plans = pull.get_pull_plans(self)
    self:carry_out(plans)
end

function Inventory:get(sought_items)
    local plans = get.get_get_plans(self, sought_items)
    self:carry_out(plans)
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
    self:save_contents()
end

function Inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        self:update_chest(chest_name)
    end
    self:save_contents()
end

function Inventory:update_chest(chest_id)
    local chest = peripheral.wrap(chest_id)
    local chest_data = { size = chest.size(), items = chest.list() }
    self.contents[chest_id] = chest_data
end

function Inventory:update_chests(chest_list, start_, end_)
    for i = start_, end_ do
        local chest_name = chest_list[i]
        print("Updating " .. chest_name)
        self:update_chest(chest_name)
    end
end

function Inventory:save_contents()
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:count(sought_items)
    self:load(true)
    
    local counts = {}
    for _, sought_item in ipairs(sought_items) do
        for chest_name, contents in pairs(self.contents) do
            for _, item in ipairs(contents.items) do
                if item.name ~= sought_item then goto continue end
                if sought_items[#counts] == sought_item then
                    counts[#counts] = counts[#counts] + item.count
                else
                    table.insert(counts, item.count)
                end
                ::continue::
            end
        end
    end

    for i = 1, #counts do
        print(sought_items[i], counts[i])
    end
end

return Inventory
