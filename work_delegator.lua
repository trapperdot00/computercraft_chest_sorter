local debugger          = require("debugger")
local work_delegator    = {}

local function push(inventory)

end

local function pull(rows, items, inputs)

end

local function scan(contents)
    contents:update()
end

local function get(inputs, sought_items)

end

local function item_count(sought_items, contents)
    contents:load()
    for _, sought_item in pairs(sought_items) do
        local count = contents:item_count(sought_item)
        print(sought_item, count)
    end
end

local function print_inputs(inputs)
    debugger.print_seque(inputs)
end

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --push --pull --scan")
    print("         --get=<item1>[,<itemN>]...")
    print("         --count=<item1>[,<itemN>]...")
    print("         --print-inputs")
end

function work_delegator.delegate(options, inputs, inventory)
    if options.push then
        push(inputs, inventory)
    elseif options.pull then
        pull(inputs, inventory)
    elseif options.scan then
        scan(contents)
    elseif #options.get > 0 then
        get(inputs, inventory, options.get)
    elseif #options.count > 0 then
        count(options.count, contents)
    elseif options.print_inputs then
        print_inputs(inputs)
    else
        print_help()
    end
end

return work_delegator
