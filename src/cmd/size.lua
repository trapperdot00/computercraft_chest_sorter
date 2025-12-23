local size = {}

function size.size(self)
    self:load(true)
    local in_slots  = 0
    local out_slots = 0
    for chest_id, contents in pairs(self.contents) do
        local slots = contents.size
        if self:is_input_chest(chest_id) then
            in_slots = in_slots + slots
        else
            out_slots = out_slots + slots
        end
    end
    return in_slots, out_slots
end

return size
