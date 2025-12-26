-- Plan represents an item-moving strategy
-- between two inventory peripherals.
--
-- Fields:
--   `src`     : source chest's ID
--   `dst`     : destination chest's ID
--   `src_slot`: source slot index
--   `count`   : the count of items to move
--               (optional)
--   `dst_slot`: destination slot index
--               (optional)

local tbl  = require("utils.table_utils")
local plan = {}

function plan.execute_plan(p)
    local src      = p.src
    local dst      = p.dst
    local src_slot = p.src_slot
    local count    = p.count
    local dst_slot = p.dst_slot

    local src_chest = peripheral.wrap(src)
    if count == nil then
        src_chest.pushItems(dst, src_slot)
    elseif dst_slot == nil then
        src_chest.pushItems(dst, src_slot, count)
    else
        src_chest.pushItems(
            dst, src_slot, count, dst_slot
        )
    end
end

-- Execute a list of plans in parallel
function plan.execute_plans(plans, task_pool)
    for _, p in ipairs(plans) do
        local task = function()
            plan.execute_plan(p)
        end
        task_pool:add(task)
    end
    task_pool:run()
end

-- Returns an array containing
-- the peripheral IDs listed inside the
-- given plan-list.
-- The IDs are listed only once.
function plan.get_affected_chests(plans)
    local affected = {}
    for _, p in ipairs(plans) do
        if not tbl.contains(affected, p.src) then
            table.insert(affected, p.src)
        end
        if not tbl.contains(affected, p.dst) then
            table.insert(affected, p.dst)
        end
    end
    return affected
end

return plan
