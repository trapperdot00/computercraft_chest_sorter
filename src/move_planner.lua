local tbl   = require("utils.table_utils")
local fiter = require("src.filter_iterator")
local move_planner = {}

-- Create plans for topping up slots
-- where there are items whose counts
-- are less than their stack sizes.
function move_planner.top_up
(db, stacks, src_ids, dst_ids)
    local plans = {}
    local src_pred = function(curr)
        local item = curr.item
        return item ~= nil 
            and tbl.contains(src_ids, curr.id)
    end
    local src_it = fiter:new(db, src_pred)
    src_it:first()
    while not src_it:is_done() do
        local src_val  = src_it:get()
        local src_item = src_val.item
        local stack    = stacks:get(src_item.name)
        local dst_pred = function(curr)
            local item = curr.item
            return item ~= nil
                and item.name == src_item.name
                and item.count < stack
                and tbl.contains(dst_ids, curr.id)
        end
        local dst_it = fiter:new(db, dst_pred)
        dst_it:first()
        while not dst_it:is_done() and
            src_item.count > 0 do
            local dst_val  = dst_it:get()
            local dst_item = dst_val.item
            local cap = stack - dst_item.count
            local cnt = math.min(
                cap, src_item.count
            )
            local src_cnt = src_item.count - cnt
            local dst_cnt = dst_item.count + cnt
            local plan = {
                src      = src_val.id,
                src_slot = src_val.slot,
                dst      = dst_val.id,
                dst_slot = dst_val.slot,
                count    = cnt
            }
            table.insert(plans, plan)
            if src_cnt == 0 then
                db:del_item(
                    src_val.id, src_val.slot
                )
                src_item.count = 0
            else
                db:add_item(
                    src_val.id, src_val.slot,
                    {
                        name  = src_item.name,
                        count = src_cnt
                    }
                )
                src_item.count = src_cnt
            end
            db:add_item(dst_val.id, dst_val.slot,
                {
                    name  = dst_item.name,
                    count = dst_cnt
                }
            )
            if dst_cnt == stack then
                dst_it:next()
            end
        end
        src_it:next()
    end
    return plans
end

-- Create plans for moving items from
-- the input into the output inventories.
function move_planner.move
(db, stacks, src_ids, dst_ids)
    local plans = move_planner.top_up(
        db, stacks, src_ids, dst_ids
    )
    local src_pred = function(curr)
        return curr.item ~= nil
            and tbl.contains(src_ids, curr.id)
    end
    local dst_pred = function(curr)
        return curr.item == nil
            and tbl.contains(dst_ids, curr.id)
    end
    local src_it = fiter:new(db, src_pred)
    local dst_it = fiter:new(db, dst_pred)
    src_it:first()
    dst_it:first()
    while not src_it:is_done() and
          not dst_it:is_done() do
        local src_val = src_it:get()
        local dst_val = dst_it:get()
        local plan = {
            src      = src_val.id,
            src_slot = src_val.slot,
            dst      = dst_val.id,
            dst_slot = dst_val.slot,
            count    = src_val.item.count
        }
        table.insert(plans, plan)
        db:add_item(dst_val.id, dst_val.slot,
            {
                name  = src_val.item.name,
                count = src_val.item.count
            }
        )
        db:del_item(src_val.id, src_val.slot)
        local topper = move_planner.top_up(
            db, stacks, src_ids, dst_ids
        )
        table.move(
            topper, 1, #topper, #plans + 1, plans
        )
        src_it:next()
        dst_it:next()
    end
    return plans
end

return move_planner
