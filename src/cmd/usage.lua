local usage = {}

function usage.usage(self)
    self:load(true)
    local total = 0
    local used  = 0
    for id, _ in pairs(self.contents.data) do
        if not self.inputs:is_input_chest(id) then
            local size = self.contents:get_slot_size(id)
            local full = self.contents:get_full_slots(id)
            total = total + size
            used  = used  + full
        end
    end
    return total, used
end

return usage
