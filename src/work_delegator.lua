local debugger          = require("utils.debugger")
local configure         = require("src.configure")
local cfg               = require("utils.config_reader")
local Inventory         = require("src.Inventory")

local work_delegator    = {}

local function print_inputs(inventory)
    debugger.print_seque(inventory.inputs)
end

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --configure")
    print("         --push --pull --scan")
    print("         --size --usage")
    print("         --get=<item1>[,<itemN>]...")
    print("         --count=<item1>[,<itemN>]...")
    print("         --find=<item1>[,<itemN>]...")
end

function work_delegator.delegate
(options, contents_path, inputs_path, stacks_path)
    if not options:valid() then
        print_help()
        return
    end

    if options.conf then
        configure.run(inputs_path)
        return
    end

    local inventory = Inventory.new(
        contents_path, inputs_path, stacks_path
    )

    -- Handle non-exclusive flags
    if options.scan then
        inventory:scan()
    end

    -- Handle exclusive flags
    if options.push then
        inventory:push()
    elseif options.pull then
        inventory:pull()
    elseif options.size then
        inventory:size()
    elseif options.usage then
        inventory:usage()
    elseif #options.get > 0 then
        inventory:get(options.get)
    elseif #options.count > 0 then
        inventory:count(options.count)
    elseif #options.find > 0 then
        inventory:find(options.find)
    end
end

return work_delegator
