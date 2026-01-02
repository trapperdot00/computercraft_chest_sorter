local tbl = require("utils.table_utils")

local inv_db = {}
inv_db.__index = inv_db

--==== INTERFACE ====--
--
-- inv_db.new()
--
-- == Inventories ==
-- inv_db:inv_exists(inv_id)
-- inv_db:add_inv(inv_id, size)
-- inv_db:del_inv(inv_id)
-- inv_db:get_inv_ids()
-- inv_db:get_size(inv_id)
-- inv_db:occupied_slots(inv_id)
-- inv_db:free_slots(inv_id)
--
-- == Items ==
-- inv_db:item_exists(inv_id, slot)
-- inv_db:add_item(inv_id, slot, item)
-- inv_db:del_item(inv_id, slot)
-- inv_db:get_item(inv_id, slot)
-- inv_db:get_items(inv_id)

--==== IMPLEMENTATION ====--

function inv_db.new()
    local self = setmetatable(
        {
            data = {}
        }, inv_db
    )
    return self
end

function inv_db:inv_exists(inv_id)
    return self.data[inv_id] ~= nil
end

local function
throw_if_inv_exists(self, inv_id)
    if self:inv_exists(inv_id) then
        error("inventory " ..
            inv_id .. " already exists", 0)
    end
end

local function
throw_if_inv_doesnt_exist(self, inv_id)
    if not self:inv_exists(inv_id) then
        error("inventory " ..
            inv_id .. " doesn't exist", 0)
    end
end

function inv_db:add_inv(inv_id, size)
    self.data[inv_id] = {
        size  = size,
        items = {}
    }
end

function inv_db:del_inv(inv_id)
    self.data[inv_id] = nil
end

function inv_db:get_inv_ids()
    return tbl.get_keys(self.data)
end

function inv_db:get_size(inv_id)
    throw_if_inv_doesnt_exist(self, inv_id)
    return self.data[inv_id].size
end

function inv_db:occupied_slots(inv_id)
    throw_if_inv_doesnt_exist(self, inv_id)
    local inv_items = self:get_items(inv_id)
    return tbl.size(inv_items)
end

function inv_db:free_slots(inv_id)
    throw_if_inv_doesnt_exist(self, inv_id)
    local inv_size = self:get_size(inv_id)
    return inv_size - self:occupied_slots(inv_id)
end

local function
throw_if_slot_out_of_range(self, inv_id, slot)
    local inv_size = self:get_size(inv_id)
    if slot < 1 or slot > inv_size then
        error(
            "slot out of range for " ..
            "inventory '" .. inv_id ..
            "' (size: " ..
            tostring(inv_size) ..
            ", got: " ..
            tostring(slot) .. ")"
            , 0
        )
    end
end

function inv_db:item_exists(inv_id, slot)
    throw_if_inv_doesnt_exist(self, inv_id)
    return self.data[inv_id].items[slot] ~= nil
end

local function
throw_if_item_exists(self, inv_id, slot)
    if self:item_exists(inv_id, slot) then
        error("item already exists " ..
            "in inventory '" .. inv_id ..
            "' at slot " .. tostring(slot), 0)
    end
end

local function
throw_if_item_doesnt_exist(self, inv_id, slot)
    if not self:item_exists(inv_id, slot) then
        error("item doesn't exist " ..
            "in inventory '" .. inv_id ..
            "' at slot " .. tostring(slot), 0)
    end
end

function inv_db:add_item(inv_id, slot, item)
    throw_if_slot_out_of_range(
        self, inv_id, slot
    )
    self.data[inv_id].items[slot] = item
end

function inv_db:del_item(inv_id, slot)
    self.data[inv_id].items[slot] = nil
end

function inv_db:get_item(inv_id, slot)
    throw_if_slot_out_of_range(
        self, inv_id, slot
    )
    throw_if_item_doesnt_exist(
        self, inv_id, slot
    )
    return self.data[inv_id].items[slot]
end

function inv_db:get_items(inv_id)
    throw_if_inv_doesnt_exist(
        self, inv_id
    )
    return self.data[inv_id].items
end

return inv_db
