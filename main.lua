local cfg       = require("config_reader")
local options   = require("options")
local wd        = require("work_delegator")

local args = { ... }

local function main()
    -- Have to update this to the current working directory
    local pwd = "/programs/chest/0006/"

    -- Configuration files
    local row_chests_file = pwd .. "row_chests.txt"
    local row_items_file  = pwd .. "row_items.txt"
    local inputs_file     = pwd .. "inputs.txt"

    -- Configuration tables
    local rows      = cfg.read_config_file_assoc(row_chests_file)
    local items     = cfg.read_config_file_assoc(row_items_file)
    local inputs    = cfg.read_config_file_seque(inputs_file)

    -- Command-line arguments
    local opts      = options.parse(args)
    
    -- Select appropriate work for command-line arguments
    wd.delegate(opts, rows, items, inputs)
end

main()
