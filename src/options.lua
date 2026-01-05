local str     = require("utils.string_utils")
local options = {}
options.__index = options

function options.new()
    return setmetatable({
        excl = {
            flags = {
                help      = false,
                push      = false,
                pull      = false,
                configure = false,
                size      = false,
                usage     = false
            },
            varopts = {
                get   = {},
                count = {},
                find  = {}
            }
        },
        noexcl = {
            flags = {
                scan  = false
            }
        },
        valid = false
    }, options)
end

local function parse_flag(_arg, flags)
    for flag, _ in pairs(flags)
    do
        if _arg == "--"..flag then
            if flags[flag] ~= true then
                flags[flag] = true
                return true
            end
        end
    end
    return false
end

local function parse_varopts(_arg, varopts)
    for varopt, _ in pairs(varopts)
    do
        local vals, cnt = _arg:gsub(
            "--"..varopt..'=', ""
        )
        if cnt > 0 then
            if #varopts[varopt] == 0 then
                varopts[varopt] = str.split(
                    vals, ','
                )
                return true
            end
        end
    end
    return false
end

function options:parse()
    local parsed = 0
    for i = 1, #arg do
        if parse_flag(arg[i], self.excl.flags)
        or parse_flag(arg[i], self.noexcl.flags)
        or parse_varopts(arg[i], self.excl.varopts)
        then
            parsed = parsed + 1
        end
    end
    local excl_cnt = self:count_exclusives()
    local noexcl_cnt = self:count_nonexclusives()
    self.valid = parsed == #arg and
        (excl_cnt < 2 and
        (excl_cnt > 0 or noexcl_cnt > 0))
end

function options:count_exclusives()
    local count = 0
    for _, val in pairs(self.excl.flags) do
        if val == true then
            count = count + 1
        end
    end
    for _, val in pairs(self.excl.varopts) do
        if #val > 0 then
            count = count + 1
        end
    end
    return count
end

function options:count_nonexclusives()
    local count = 0
    for _, val in pairs(self.noexcl.flags) do
        if val == true then
            count = count + 1
        end
    end
    return count
end

return options
