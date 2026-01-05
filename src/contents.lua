local inv_db = require("src.inv_db")

local contents = {}
contents.__index = contents

--==== INTERFACE ====--
--
-- contents.new(filename, task_pool)
--
-- contents:is_loaded()
-- contents:scan()
-- contents:load()
-- contents:update(inv_id)
-- contents:save_to_file()
--
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
        local task = function()
            local inv_id    = peripheral.getName(inv)
            local inv_size  = inv.size()
            local inv_items = inv.list()
            self.db:add_inv(inv_id, inv_size)
            for slot, item in pairs(inv_items) do
                self.db:add_item(inv_id, slot, item)
            end
        end
        self.task_pool:add(task)
    end
    self.task_pool:run()
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
    local data = textutils.serialize(self.db.data)
    file:write(data)
    file:close()
end

return contents
