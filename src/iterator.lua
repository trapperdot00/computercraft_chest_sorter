local tbl = require("utils.table_utils")

local iterator = {}
iterator.__index = iterator

-- Constructs a new instance of iterator:
-- an iterator that traverses the contents of
-- the inventory state database.
-- The returned iterator is set to the first
-- element in the range.
-- Traversal order: each slot of each inventory.
-- Fields:
--     `data`    : Table of inventory contents.
--     `inv_ids` : Array of inventory IDs
--                collected from data's keys.
--     `inv_size`: Size of current inventory ID.
--     `inv_i`   : Index of current inventory ID.
--     `slot`    : Current slot.
function iterator.new(contents)
    local self = setmetatable(
        {
            data     = contents,
            inv_ids  = tbl.get_keys(contents),
            inv_size = nil,
            inv_i    = nil,
            slot     = nil
        }, iterator
    )
    self:first()
    return self
end

local function update_inv_size(self)
    if self.inv_i <= #self.inv_ids then
        local inv_id   = self.inv_ids[self.inv_i]
        local inv_data = self.data[inv_id]
        self.inv_size  = inv_data.size
    end
end

-- Set the iterator to denote the first possible
-- combination of inventory ID - slot pairing.
function iterator:first()
    self.inv_i = 1
    self.slot  = 1
    update_inv_size(self)
end

-- Advance the iterator to the next slot.
function iterator:next()
    if self.slot < self.inv_size then
        -- Advance by slot
        self.slot = self.slot + 1
    else
        -- Advance by chest
        self.inv_i = self.inv_i + 1
        self.slot  = 1
        update_inv_size(self)
    end
end

-- Get the denoted element as a table.
-- Returned fields:
--   `id`: Inventory ID.
--   `size`: Inventory size.
--   `slot`: Slot of inventory.
--   `item`: Nil if the slot is empty,
--           otherwise information about
--           the current item.
function iterator:get()
    local inv_id   = self.inv_ids[self.inv_i]
    local inv_data = self.data[inv_id]
    local items    = inv_data.items
    local item     = items[self.slot]
    return {
        id   = inv_id,
        size = self.inv_size,
        slot = self.slot,
        item = item
    }
end

function iterator:is_done()
    return self.inv_i > #self.inv_ids
        or self.slot  > self.inv_size
end

return iterator
