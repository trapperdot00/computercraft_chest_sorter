local find = {}

function find.find(self, sought_item)
    self:load(true)
    local ids = {}
    for id, data in pairs(self.contents.data) do
        if not self.inputs:is_input_chest(id) then
            for _, item in pairs(data.items) do
                if item.name == sought_item then
                    table.insert(ids, id)
                    break
                end
            end
        end
    end
    return ids
end

return find
