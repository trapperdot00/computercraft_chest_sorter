local size = {}

function size.size(self)
    self:load(true)
    local db = self.contents.db
    local src_slots  = 0
    local dst_slots = 0
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        local inv_size = db:get_size(inv_id)
        if self.inputs:is_input_chest(inv_id) then
            src_slots = src_slots + inv_size
        else
            dst_slots = dst_slots + inv_size
        end
    end
    return src_slots, dst_slots
end

return size
