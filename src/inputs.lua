local cfg       = require("utils.config_reader")
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
    if fs.exists(self.filename) and
    cfg.is_valid_seque_file(self.filename) then
        self.data = cfg.read_seque(
            self.filename, ""
        )
    else
        self:configure()
    end
end

function inputs:configure()
    self.data = configure.run(self.filename)
    self:save_to_file()
end

function inputs:save_to_file()
    cfg.write_seque(self.data, self.filename)
end

-- Checks whether the given peripheral
-- referred to as an ID is an input
function inputs:is_input_chest(inv_id)
    return tbl.contains(self.data, inv_id)
end

return inputs
