local inv_db = require("src.inv_db")

local contents = {}
contents.__index = contents

--==== INTERFACE ====--

function contents.new(filename, task_pool) end

function contents:is_loaded() end
function contents:scan() end
function contents:load() end
function contents:update(inv_id) end
function contents:save_to_file() end

-- Iteration
function contents:for_each_chest(func) end
function contents:for_each_slot_in
                    (inv_id, inv_data, func) end

--==== IMPLEMENTATION ====--

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
            db        = inv_db.new(),
            task_pool = task_pool,
            loaded    = false
        }, contents
    )
end

function contents:is_loaded()
    return self.loaded
end

local function read_from_file(self)
    local file = io.open(self.filename)
    if not file then
        error("cannot open file '" ..
            self.filename .. "' for reading", 0)
    end
    local file_data = file:read('a')
    file:close()
    local data = textutils.unserialize(file_data)
    for inv_id, inv_data in pairs(data) do
        local inv_size  = inv_data.size
        local inv_items = inv_data.items
        self.db:add_inv(inv_id, inv_size)
        for slot, item in pairs(inv_items) do
            self.db:add_item(inv_id, slot, item)
        end
    end
end

-- Reads chest contents directly
-- from the attached chests and
-- writes it into the contents file.
function contents:scan()
    local invs = { peripheral.find("inventory") }
    for _, inv in ipairs(invs) do
        local inv_id    = peripheral.getName(inv)
        local inv_size  = inv.size()
        local inv_items = inv.list()
        self.db:add_inv(inv_id, inv_size)
        for slot, item in pairs(inv_items) do
            self.db:add_item(inv_id, slot, item)
        end
    end
end

-- Tries to load contents from file,
-- if it fails, scans chests for data.
-- Calling this on an already loaded
-- object returns early without doing
-- any work.
function contents:load()
    if self:is_loaded() then return end
    if fs.exists(self.filename) then
        read_from_file(self)
    else
        self:scan()
        self:save_to_file()
    end
    self.loaded = true
end

-- Updates the in-memory representation
-- for a given inventory referred to
-- as an ID by scanning the peripheral.
function contents:update(inv_id)
    local inv = peripheral.wrap(inv_id)
    local inv_size  = inv.size()
    local inv_items = inv.list()
    self.db:del_inv(inv_id)
    self.db:add_inv(inv_id, inv_size)
    for slot, item in pairs(inv_items) do
        self.db:add_item(inv_id, slot, item)
    end
end

function contents:save_to_file()
    local file = io.open(self.filename, 'w')
    if not file then
        error("could not open file '" ..
            self.filename .. "' for writing", 0)
    end
    local data = textutils.serialize(
        self.db.data
    )
    file:write(data)
    file:close()
end

-- Iterates over each chest contained in the
-- contents database in memory,
-- and calls `func` for each one in parallel.
--
-- `func`: a function that takes these parameters:
--     -> `inv_id`   : inventory ID
--     -> `inv_size` : inventory slot count
--     -> `inv_items`: an associative table
--                     containing slots as keys
--                     and items as values
function contents:for_each_chest(func)
    local inv_ids = self.db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        local inv_size = self.db:get_size(inv_id)
        local inv_items = self.db:get_items(inv_id)
        func(inv_id, inv_size, inv_items)
    end
end

-- Iterates over `contents`'s items
-- (each filled slot),
-- calling `func` with each iteration
-- in parallel.
--
-- `func`: a function that takes these parameters:
--   -> `inv_id`  : inventory ID
--   -> `inv_size`: inventory slot count
--   -> `slot`    : slot's index
--   -> `item`    : item
function contents:for_each_slot_in
(inv_id, inv_size, inv_items, func)
    for slot, item in pairs(inv_items) do
        local task = function()
            func(inv_id, inv_size, slot, item)
        end
        self.task_pool:add(task)
    end
    self.task_pool:run()
end

return contents
