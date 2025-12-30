local tbl = require("utils.table_utils")
local get = {}

function get.get_plans(self, sought_items)
    self:load()
    local plans = {}
    local src_pred = function(it)
        local data = it:get()
        local item = data.item
        return item and tbl.contains(
            sought_items, data.item.name
        )
    end
    local dst_pred = function(it)
        return it:get().item == nil
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

return get
