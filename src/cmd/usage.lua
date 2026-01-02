local usage = {}

function usage.usage(self)
    self:load(true)
    local db     = self.contents.db
    local inputs = self.inputs
    local total = 0
    local used  = 0
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        if not inputs:is_input_chest(inv_id) then
            local inv_size = db:get_size(inv_id)
            local full = db:occupied_slots(inv_id)
            total = total + inv_size
            used  = used + full
        end
    end
    return total, used
end

return usage
