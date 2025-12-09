local str     = require("string_utils")
local options = {}

function options.parse()
    local opts = {
        push            = false,
        pull            = false,
        scan            = false,
        get             = {},
        count           = {},
        print_inputs    = false
    }
    for i = 1, #arg do
        local curr_arg = arg[i]
        if curr_arg == "--push" then
            opts.push = true
        elseif curr_arg == "--pull" then
            opts.pull = true
        elseif curr_arg == "--scan" then
            opts.scan = true
        elseif curr_arg:find("--get", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            opts.get = str.split(curr_arg:sub(equal_pos), ',')
        elseif curr_arg:find("--count", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            opts.count = str.split(curr_arg:sub(equal_pos), ',')
        elseif curr_arg == "--print-inputs" then
            opts.print_inputs = true
        end
    end
    return opts
end

return options
