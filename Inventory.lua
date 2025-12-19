local tbl          = require("utils.table_utils")
local chest_parser = require("utils.chest_parser")
local cfg          = require("utils.config_reader")
local configure    = require("configure")

local push      = require("cmd.push")
local pull      = require("cmd.pull")
local size      = require("cmd.size")
local usage     = require("cmd.usage")
local get       = require("cmd.get")
local count     = require("cmd.count")
local find      = require("cmd.find")

local Inventory = {}
Inventory.__index = Inventory

-- Constructs and returns a new instance of Inventory
-- Named fields:
--     `contents_path`: Filename of the document that
--                      lists the current state of the
--                      managed chest-system.
--     `contents`     : Table that keeps track of the current
--                      state of the managed chest-system.
--     `inputs_path`  : Filename of the document that
--                      lists the chest IDs of input chests.
--     `inputs`       : Array of input chest IDs.
--     `stacks_path`  : Filename of the document that
--                      describes the currently known items'
--                      stack sizes.
--     `stacks`       : Associative table that associates
--                      an item name with a stack size.
--                      (key: item name; value: stack size)
function Inventory.new(contents_path, inputs_path, stacks_path)
    local self = setmetatable({
        contents_path = contents_path,
        contents      = nil,
        inputs_path   = inputs_path,
        inputs        = nil,
        stacks_path   = stacks_path,
        stacks        = nil
    }, Inventory)
    self:load_inputs()
    return self
end

-- Try to load input file contents.
-- If the file doesn't exist or its format is unreadable,
-- prompts the user to reconfigure input chest bindings.
function Inventory:load_inputs()
    if not fs.exists(self.inputs_path)
    or not cfg.is_valid_seque_file(self.inputs_path) then
        configure.run(self.inputs_path)
    end
    self.inputs = cfg.read_seque(self.inputs_path, "")
end

-- TODO: clean up this
function Inventory:load_stack()
    if self.stacks then return end
    local file = io.open(self.stacks_path)
    if not file then self.stacks = {} return end
    local text = file:read('a')
    self.stacks = textutils.unserialize(text) or {}
end

function Inventory:load(noscan)
    self:load_stack()
    if self.contents then return end
    local file = io.open(self.contents_path)
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
    -- Move the specified items
    self:execute_plans(plans)
    
    -- Update affected chests in memory
    local affected = self:get_affected_chests(plans)
    for _, id in ipairs(affected) do
        print("updating", id)
        self:update_chest(id)
    end

    -- Update chest database file
    if #affected > 0 then
        print("saving to file", self.contents_path)
        self:save_contents()
    end
end

-- Iterates over each chest contained in the
-- contents database in memory,
-- and calls `func` for each one in parallel.
--
-- `func`: a function that takes two parameters:
--     -> `chest_id`: a string
--     -> `contents`: an associative table containing
--                    slots as keys and items as values
function Inventory:for_each_chest(func)
    local tasks = {}
    for chest_id, contents in pairs(self.contents) do
        table.insert(tasks,
            function()
                func(chest_id, contents)
            end
        )
    end
    parallel.waitForAll(table.unpack(tasks))
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest if it is an input chest.
function Inventory:for_each_input_chest(func)
    local f = function(chest_id, contents)
        if self:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self:for_each_chest(f)
end

-- Wrapper for `for_each_chest` that only calls
-- `func` for a given chest if it is an output chest.
function Inventory:for_each_output_chest(func)
    local f = function(chest_id, contents)
        if not self:is_input_chest(chest_id) then
            func(chest_id, contents)
        end
    end
    self:for_each_chest(f)
end

-- Iterates over `contents`'s items (each filled slot),
-- calling `func` with each iteration in parallel.
--
--     `func`: a function that takes three parameters:
--         -> `chest_id`: the current chest's id as context
--         -> `slot`    : the current slot's index
--         -> `item`    : the current item
function Inventory:for_each_slot_in(chest_id, contents, func)
    local tasks = {}
    for slot, item in pairs(contents.items) do
        table.insert(tasks,
            function()
                func(chest_id, slot, item)
            end
        )
    end
    parallel.waitForAll(table.unpack(tasks))
end

-- Wrapper that iterates over each input chest's slots.
function Inventory:for_each_input_slot(func)
    local f = function(chest_id, contents)
        self:for_each_slot_in(chest_id, contents, func)
    end
    self:for_each_input_chest(f)
end

-- Wrapper that iterates over each output chest's slots.
function Inventory:for_each_output_slot(func)
    local f = function(chest_id, contents)
        self:for_each_slot_in(chest_id, contents, func)
    end
    self:for_each_output_chest(f)
end

-- TODO: clean up this
function Inventory:update_stacksize()
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
end

-- Push items from the input chests into the output chests.
function Inventory:push()
    self:update_stacksize()
    local plans = push.get_push_plans(self)
    --self:carry_out(plans)
end

-- Pull items from the output chests into the input chests.
function Inventory:pull()
    local plans = pull.get_pull_plans(self)
    self:carry_out(plans)
end

function Inventory:size()
    local in_slots, out_slots = size.size(self)
    local full_slots = in_slots + out_slots
    print("[IN] :", in_slots)
    print("[OUT]:", out_slots)
    print("[ALL]:", full_slots)
end

function Inventory:usage()
    local total, used = usage.usage(self)
    local percent = (used / total) * 100
    print("[USED]:", used)
    print("[ALL] :", total)
    print("["..tostring(percent).."%]")
end

function Inventory:get(sought_items)
    local plans = get.get_get_plans(self, sought_items)
    self:carry_out(plans)
end

function Inventory:count(sought_items)
    for _, item in ipairs(sought_items) do
        local cnt = count.count(self, item)
        print(item, cnt)
    end
end

function Inventory:find(sought_items)
    for _, item in ipairs(sought_items) do
        local chests = find.find(self, item)
        for _, chest_id in ipairs(chests) do
            print(item, "->", chest_id)
        end
    end
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
    self:save_contents()
end

function Inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        self:update_chest(chest_name)
    end
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
    chest_parser.write_to_file(self.contents, self.contents_path)
end

return Inventory
