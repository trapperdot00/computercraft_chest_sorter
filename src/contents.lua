local chpr = require("utils.chest_parser")
local tbl  = require("utils.table_utils")

local contents = {}
contents.__index = contents

-- Constructs a new contents instance
-- Fields:
--     filename : File to read/write
--                contents from/into.
--     data     : In memory representation
--                of inventory contents.
--     task_pool: An instance of task_pool
--                that manages the parallelized
--                execution of tasks.
function contents.new(filename, task_pool)
    return setmetatable(
        {
            filename  = filename,
            data      = nil,
            task_pool = task_pool
        }, contents
    )
end

function contents:is_loaded()
    return data ~= nil
end

-- Tries to load contents from file,
-- if it fails, scans chests for data.
-- Calling this on an already loaded
-- object returns early without doing
-- any work.
function contents:load()
    if self:is_loaded() then return end
    local file = io.open(self.filename)
    if file then
        self.data = chpr.read_from_file(file)
        file:close()
    else
        self:scan()
    end
end

-- Reads chest contents directly
-- from the attached chests and
-- writes it into the contents file.
function contents:scan()
    self.data = chpr.read_from_chests()
    self:save_to_file()
end

-- Updates the in-memory representation
-- for a given inventory referred to
-- as an ID by scanning the peripheral.
function contents:update(inv_id)
    local inv      = peripheral.wrap(inv_id)
    local inv_data = {
        size  = inv.size(),
        items = inv.list()
    }
    self.data[inv_id] = inv_data
end

function contents:save_to_file()
    chpr.write_to_file(self.data, self.filename)
end

-- Returns the capacity of the given
-- inventory entity referred to
-- as an ID in slots
function contents:get_slot_size(inv_id)
    local inv  = self.data[inv_id]
    local size = inv.size
    return size
end

-- Returns the count of occupied slots
-- of the given inventory object
-- referred to as an ID
function contents:get_full_slots(inv_id)
    local inv   = self.data[inv_id]
    local items = inv.items
    local full  = tbl.size(items)
    return full
end

-- Returns the non-occupied/free slots
-- of the given inventory entity
-- referred to as an ID
function contents:get_free_slots(inv_id)
    local size = self:get_slot_size(inv_id)
    local full = self:get_full_slots(inv_id)
    local free = size - full
    return free
end

-- Returns whether the given inventory entity
-- referred to as an ID
--  -> has only occupied/full slots
--  -> has no more unoccupied/free slots
function contents:is_full(inv_id)
    local size = self:get_slot_size(inv_id)
    local full = self:get_full_slots(inv_id)
    return size == full
end

-- Returns whether the given inventory entity
-- referred to as an ID
--  -> has only unoccupied/free slots
--  -> has no occupied/full slots
function contents:is_empty(inv_id)
    local full = self:get_full_slots(inv_id)
    return full == 0
end

-- Iterates over each chest contained in the
-- contents database in memory,
-- and calls `func` for each one in parallel.
--
-- `func`: a function that takes two parameters:
--     -> `inv_id`: a string
--     -> `inv`   : an associative table
--                  containing slots as keys
--                  and items as values
function contents:for_each_chest(func)
    for inv_id, inv in pairs(self.data) do
        local task = function()
            func(inv_id, inv)
        end
    end
end

-- Iterates over `contents`'s items
-- (each filled slot),
-- calling `func` with each iteration
-- in parallel.
--
-- `func`: a function that takes three parameters:
--   -> `inv_id`: the current inventory's
--                ID as context to give to `func`
--   -> `slot`  : the current slot's index
--   -> `item`  : the current item
function contents:for_each_slot_in(inv_id, contents, func)
    for slot, item in pairs(contents.items) do
        local task = function()
            func(inv_id, slot, item)
        end
        self.task_pool:add(task)
    end
    self.task_pool:run()
end

return contents
