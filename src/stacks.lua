local stack_db = require("src.stack_db")
local stacks = {}
stacks.__index = stacks

function stacks.new(filename)
    return setmetatable(
        {
            filename = filename,
            db       = stack_db.new(),
            loaded   = false
        }, stacks
    )
end

function stacks:is_loaded()
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
    for item_name, stack_size in pairs(data) do
        self.db:add(item_name, stack_size)
    end
end

function stacks:load()
    if self:is_loaded() then return end
    if fs.exists(self.filename) then
        read_from_file(self)
    end
    self.loaded = true
end

function stacks:save_to_file()
    local file = io.open(self.filename, 'w')
    if not file then
        error(
            "could not open file '" ..
            self.filename ..
            "' for writing."
        )
    end
    local data = textutils.serialize(self.db.data)
    file:write(data)
    file:close()
end

function stacks:get(item_name)
    return self.db:get(item_name)
end

function stacks:add(item_name, stack_size)
    self.db:add(item_name, stack_size)
end

return stacks
