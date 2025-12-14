local debugger          = require("utils.debugger")
local configure         = require("configure")
local cfg               = require("utils.config_reader")
local Inventory         = require("Inventory")
local work_delegator    = {}

local function print_inputs(inventory)
    debugger.print_seque(inventory.inputs)
end

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --configure")
    print("         --push --pull --scan")
    print("         --get=<item1>[,<itemN>]...")
    print("         --count=<item1>[,<itemN>]...")
    print("         --find=<item1>[,<itemN>]...")
end

local function load_inputs(inputs_file)
    if not fs.exists(inputs_file) or
    not cfg.is_valid_seque_file(inputs_file) then
        configure.run(inputs_file)
    end
    return cfg.read_seque(inputs_file, "")
end

function work_delegator.delegate(options, inputs_file, inventory_file)
    if not options:valid() then
        print_help()
        return
    end

    if options.conf then
        configure.run(inputs_file)
        return
    end

    local inputs    = load_inputs(inputs_file)
    local inventory = Inventory.new(inputs, inventory_file)

    -- Non-exclusive flags
    if options.scan then
        inventory:scan()
    end

    -- Exclusive flags
    if options.push then
        inventory:push()
    elseif options.pull then
        inventory:pull()
    elseif #options.get > 0 then
        inventory:get(options.get)
    elseif #options.count > 0 then
        inventory:count(options.count)
    elseif #options.find > 0 then
        inventory:find(options.find)
    end
end

return work_delegator
