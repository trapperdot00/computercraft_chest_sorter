local stacks = {}
stacks.__index = stacks

function stacks.new(filename)
    return setmetatable(
        {
            filename = filename,
            data     = nil
        }, stacks
    )
end

function stacks:is_loaded()
    return self.data ~= nil
end

function stacks:load()
    if self:is_loaded() then return end
    local file = io.open(self.filename)
    if file then
        local text = file:read('a')
        file:close()
        self.data = textutils.unserialize(text)
    end
    if not self:is_loaded() then
        self.data = {}
    end
end

function stacks:save_to_file()
    local file = io.open(self.filename, 'w')
    if file then
        local serialized = textutils.serialize(
            self.data
        )
        file:write(serialized)
        file:close()
    else
        error(
            "could not open file '" ..
            self.filename ..
            "' for writing."
        )
    end
end

function stacks:get(item_name)
    return self.data[item_name]
end

function stacks:add(item_name, stack_size)
    self.data[item_name] = stack_size
end

return stacks
