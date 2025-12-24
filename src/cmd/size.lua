local size = {}

function size.size(self)
    self:load(true)
    local src_slots  = 0
    local dst_slots = 0
    for id, data in pairs(self.contents.data) do
        local slots = data.size
        if self.inputs:is_input_chest(id) then
            src_slots = src_slots + slots
        else
            dst_slots = dst_slots + slots
        end
    end
    return src_slots, dst_slots
end

return size
