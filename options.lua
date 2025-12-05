local str     = require("string_utils")
local options = {}

function options.parse(args)
    local self = {
        sort            = false,
        pull            = false,
        get_items       = {},
        print_rows      = false,
        print_items     = false,
        print_inputs    = false
    }
    setmetatable(self, options)
    for i = 1, #args do
        local arg = args[i]
        print(i, arg)
        if arg == "--sort" then
            self["sort"] = true
        elseif arg == "--pull" then
            self["pull"] = true
        elseif arg:find("--get-items", 1, true) then
            local equal_pos = arg:find('=', 1, true) + 1
            self["get_items"] = str.split(arg:sub(equal_pos), ',')
        elseif arg == "--print-rows" then
            self["print_rows"] = true
        elseif arg == "--print-items" then
            self["print_items"] = true
        elseif arg == "--print-inputs" then
            self["print_inputs"] = true
        end
    end
    return self
end

return options
