local tbl = require("utils.table_utils")

local iterator = {}
iterator.__index = iterator

--==== INTERFACE ====--
--
-- iterator:new(db)
--
-- iterator:first()
-- iterator:next()
-- iterator:get()
-- iterator:is_done()
--
--==== IMPLEMENTATION ====--

-- Constructs a new instance of iterator:
-- an iterator that traverses the contents of
-- the inventory state database.
--
-- Traversal order: each slot of each inventory.
--
-- Fields:
--     `db`      : Instance of inv_db
--     `inv_ids` : Array of inventory IDs
--                collected from data's keys.
--     `inv_size`: Size of current inventory ID.
--     `inv_i`   : Index of current inventory ID.
--     `slot`    : Current slot.
function iterator:new(db)
    local self = setmetatable(
        {
            db       = db,
            inv_ids  = db:get_inv_ids(),
            inv_size = nil,
            inv_i    = nil,
            slot     = nil
        }, self
    )
    return self
end

local function update_inv_size(self)
    if self.inv_i <= #self.inv_ids then
        local inv_id    = self.inv_ids[self.inv_i]
        local inv_items = self.db:get_items(inv_id)
        self.inv_size   = self.db:get_size(inv_id)
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
    local inv_id    = self.inv_ids[self.inv_i]
    local inv_items = self.db:get_items(inv_id)
    local item      = inv_items[self.slot]
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
