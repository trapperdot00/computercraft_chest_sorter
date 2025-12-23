local find = {}

function find.find(self, sought_item)
    self:load(true)
    local chests = {}
    for chest_id, contents in pairs(self.contents) do
        if self:is_input_chest(chest_id) then goto next_chest end
        for _, item in pairs(contents.items) do
            if item.name ~= sought_item then goto next_item end
            table.insert(chests, chest_id)
            goto next_chest
            ::next_item::
        end
        ::next_chest::
    end
    return chests
end

return find
