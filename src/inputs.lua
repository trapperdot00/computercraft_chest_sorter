local tbl       = require("utils.table_utils")
local configure = require("src.configure")

local inputs = {}
inputs.__index = inputs

function inputs.new(filename)
    return setmetatable(
        {
            filename = filename,
            data     = nil
        }, inputs
    )
end

function inputs:is_loaded()
    return data ~= nil
end

-- Try to load input file contents.
-- If the file doesn't exist or
-- its format is unreadable,
-- prompts the user to configure bindings.
-- Does nothing if already loaded.
function inputs:load()
    if self:is_loaded() then return end
    local f = io.open(self.filename)
    if f then
        self.data = textutils.unserialize(
            f:read('a')
        )
    else
        self.data = {}
    end
end

function inputs:configure()
    local config = configure.run(self.filename)
    if #config == 0 then
        error("Invalid config: no inputs!", 0)
    end
    self.data = config
    self:save_to_file()
end

function inputs:save_to_file()
    local file = io.open(self.filename, "w")
    if not file then
        error(
            "cannot open file '" ..
            self.filename ..
            "' for writing", 0
        )
    end
    file:write(textutils.serialize(self.data))
    file:close()
end

function inputs:size()
    return #self.data
end

function inputs:is_empty()
    return self:size() == 0
end

-- Checks whether the given peripheral
-- referred to as an ID is an input
function inputs:is_input_chest(inv_id)
    return tbl.contains(self.data, inv_id)
end

return inputs
