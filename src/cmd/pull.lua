local pull = {}

function pull.get_plans(self)
    self:load()
    local plans = {}
    local src_pred = function(curr)
        return curr.item ~= nil
    end
    local dst_pred = function(curr)
        return curr.item == nil
    end
    local src_it = self:get_output_iterator(
        src_pred
    )
    local dst_it = self:get_input_iterator(
        dst_pred
    )
    src_it:first()
    dst_it:first()
    while not src_it:is_done() and
          not dst_it:is_done() do
        local src_data = src_it:get()
        local dst_data = dst_it:get()
        local plan = {
            src      = src_data.id,
            dst      = dst_data.id,
            src_slot = src_data.slot,
            dst_slot = dst_data.slot,
            count    = src_data.item.count
        }
        table.insert(plans, plan)
        src_it:next()
        dst_it:next()
    end
    return plans
end

return pull
