local cliargs   = require("options")
local work      = require("work_delegator")

local function main()
    -- Get current working directory
    -- based on the command's directory specification
    local pwd = fs.getDir(shell.resolve(arg[0]))

    -- Files
    local contents_path = fs.combine(pwd, "contents.data")
    local inputs_path   = fs.combine(pwd, "inputs.data")
    local stacks_path   = fs.combine(pwd, "stacks.data")

    local options = cliargs.parse()
    
    -- Select appropriate work for command-line arguments
    work.delegate(
        options, contents_path, inputs_path, stacks_path
    )
end

main()
