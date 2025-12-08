local chest_parser      = require("chest_parser")
local sorter            = require("sorter")
local debugger          = require("debugger")
local work_delegator    = {}

local function sort(rows, items, inputs)
    sorter.sort_input_chests(rows, items, inputs)
end

local function pull(rows, items, inputs)
    sorter.pull_into_input_chests(rows, items, inputs)
end

local function get_items(rows, items, inputs, sought_items)
    for _, item in ipairs(sought_items) do
        sorter.get_item(rows, items, inputs, item)
    end
end

local function refresh_database(pwd)
    local filename = pwd .. "items.data"
    local contents = chest_parser.get_chest_contents()
    chest_parser.write_to_file(contents, filename)
end

local function print_rows(rows)
    debugger.print_assoc(rows)
end

local function print_items(items)
    debugger.print_assoc(items)
end

local function print_inputs(inputs)
    debugger.print_seque(inputs)
end

local function print_help()
    print("usage: " .. arg[0] .. " [options]")
    print("options: --sort --pull --refresh")
    print("         --get-items=<item1>[,<itemN>]...")
    print("         --print-rows --print-items --print-inputs")
end

function work_delegator.delegate(pwd, options, rows, items, inputs)
    if options["sort"] then
        sort(rows, items, inputs)
    elseif options["pull"] then
        pull(rows, items, inputs)
    elseif options["refresh"] then
        refresh_database(pwd)
    elseif #options["get_items"] > 0 then
        get_items(rows, items, inputs, options["get_items"])
    elseif options["print_rows"] then
        print_rows(rows)
    elseif options["print_items"] then
        print_items(items)
    elseif options["print_inputs"] then
        print_inputs(inputs)
    else
        print_help()
    end
end

return work_delegator
