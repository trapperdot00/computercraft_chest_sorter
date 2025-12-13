local str     = require("utils.string_utils")
local options = {}
options.__index = options

function options.parse()
    local self = {
        -- Exclusive arguments:
        push            = false,
        pull            = false,
        conf            = false,
        get             = {},
        count           = {},
        -- Non-exclusive:
        scan            = false,
        print_inputs    = false
    }
    setmetatable(self, options)
    for i = 1, #arg do
        local curr_arg = arg[i]
        if curr_arg == "--push" then
            self.push = true
        end
        if curr_arg == "--pull" then
            self.pull = true
        end
        if curr_arg == "--scan" then
            self.scan = true
        end
        if curr_arg:find("--get", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            self.get = str.split(curr_arg:sub(equal_pos), ',')
        end
        if curr_arg:find("--count", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            self.count = str.split(curr_arg:sub(equal_pos), ',')
        end
        if curr_arg == "--print-inputs" then
            self.print_inputs = true
        end
    end
    return self
end

function options:valid()
    local excl_cnt = 0
    if self.push then excl_cnt = excl_cnt + 1 end
    if self.pull then excl_cnt = excl_cnt + 1 end
    if self.conf then excl_cnt = excl_cnt + 1 end
    if #self.get   > 0 then excl_cnt = excl_cnt + 1 end
    if #self.count > 0 then excl_cnt = excl_cnt + 1 end
    return excl_cnt <= 1
end

return options
