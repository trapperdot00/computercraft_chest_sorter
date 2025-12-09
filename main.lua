local cfg       = require("config_reader")
local cliargs   = require("options")
local work      = require("work_delegator")
local Inventory = require("Inventory")

local function main()
    -- Update this to the current working directory:
    -- local pwd        = "./"
    local pwd        = "/chest/"

    -- Files
    local inventory_file = pwd .. "items.data"
    local inputs_file    = pwd .. "inputs.txt"

    local options   = cliargs.parse()
    local inputs    = cfg.read_seque(input_chests_file)
    local inventory = Inventory.new(chest_contents_file)
    
    -- Select appropriate work for command-line arguments
    work.delegate(options, inputs, inventory)
end

main()
