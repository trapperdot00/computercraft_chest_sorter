local str     = require("string_utils")
local options = {}

function options.parse()
    local opts = {
        sort            = false,
        pull            = false,
        refresh         = false,
        get_items       = {},
        item_count      = {},
        print_rows      = false,
        print_items     = false,
        print_inputs    = false
    }
    for i = 1, #arg do
        local curr_arg = arg[i]
        if curr_arg == "--sort" then
            opts["sort"] = true
        elseif curr_arg == "--pull" then
            opts["pull"] = true
        elseif curr_arg == "--refresh" then
            opts["refresh"] = true
        elseif curr_arg:find("--get-items", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            opts["get_items"] = str.split(curr_arg:sub(equal_pos), ',')
        elseif curr_arg:find("--item-count", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            opts["item_count"] = str.split(curr_arg:sub(equal_pos), ',')
        elseif curr_arg == "--print-rows" then
            opts["print_rows"] = true
        elseif curr_arg == "--print-items" then
            opts["print_items"] = true
        elseif curr_arg == "--print-inputs" then
            opts["print_inputs"] = true
        end
    end
    return opts
end

return options
