local cliargs   = require("src.options")
local work      = require("src.work_delegator")

local function create_directory(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    elseif not fs.isDir(dir) then
        return false
    end
    return true
end

local function main()
    -- Get current working directory
    -- based on the command's directory specification
    local pwd  = fs.getDir(shell.resolve(arg[0]))

    -- Create data directory
    local data_dir = fs.combine(pwd, "data")
    if not create_directory(data_dir) then
        printError("Cannot create '"..data_dir.."' directory.")
        print("Try deleting the file that shares the same path.")
        return
    end

    -- Data file paths
    local contents_path = fs.combine(data_dir, "contents.data")
    local inputs_path   = fs.combine(data_dir, "inputs.data")
    local stacks_path   = fs.combine(data_dir, "stacks.data")

    local options = cliargs.parse()
    
    -- Select appropriate work for command-line arguments
    work.delegate(
        options, contents_path, inputs_path, stacks_path
    )
end

main()
