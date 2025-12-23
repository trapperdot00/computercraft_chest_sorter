local str     = require("utils.string_utils")
local options = {}
options.__index = options

function options.parse()
    local self = {
        -- Exclusive arguments:
        push            = false,
        pull            = false,
        conf            = false,
        size            = false,
        usage           = false,
        get             = {},
        count           = {},
        find            = {},
        -- Non-exclusive:
        scan            = false
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
        if curr_arg == "--configure" then
            self.conf = true
        end
        if curr_arg == "--size" then
            self.size = true
        end
        if curr_arg == "--usage" then
            self.usage = true
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
        if curr_arg:find("--find", 1, true) then
            local equal_pos = curr_arg:find('=', 1, true) + 1
            self.find = str.split(curr_arg:sub(equal_pos), ',')
        end
    end
    return self
end

function options:count_exclusives()
    local count = 0
    if self.push  then count = count + 1 end
    if self.pull  then count = count + 1 end
    if self.conf  then count = count + 1 end
    if self.size  then count = count + 1 end
    if self.usage then count = count + 1 end
    if #self.get   > 0 then count = count + 1 end
    if #self.count > 0 then count = count + 1 end
    if #self.find > 0 then count = count + 1 end
    return count
end

function options:count_nonexclusives()
    local count = 0
    if self.scan == true then
        count = count + 1
    end
    return count
end

function options:valid()
    local excl   = self:count_exclusives()
    local noexcl = self:count_nonexclusives()
    return excl == 1 or noexcl > 0
end

return options
