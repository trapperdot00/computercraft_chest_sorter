domain = "https://raw.githubusercontent.com"
user   = "trapperdot00"
repo   = "cc-tweaked_inventory_manager"
ref    = "refs/heads/master"

site = domain..'/'..fs.combine(user, repo, ref)

-- Directory names as keys, filenames as values
data = {
    ["."] = {
        "main.lua"
    },
    ["src"] = {
        "configure.lua",
        "contents.lua",
        "inputs.lua",
        "inv_db.lua",
        "inventory.lua",
        "move_planner.lua",
        "options.lua",
        "plan.lua",
        "stack_db.lua",
        "stacks.lua",
        "work_delegator.lua"
    },
    ["utils"] = {
        "string_utils.lua",
        "table_utils.lua",
        "task_pool.lua"
    }
}

local function install()
    local pwd = shell.dir()
    for dir, files in pairs(data) do
        local abs_dir = fs.combine(pwd, dir)
        if not fs.exists(abs_dir) then
            fs.makeDir(abs_dir)
        elseif not fs.isDir(abs_dir) then
            error(
                "cannot create directory '"..
                abs_dir.."'", 0
            )
        end
        shell.setDir(abs_dir)
        for _, file in ipairs(files) do
            local path = fs.combine(dir, file)
            local webpath = site..'/'..path
            shell.execute("wget", webpath)
        end
    end
    shell.setDir(pwd)
end

install()
