local count = {}

function count.count(self, sought_item)
    self:load(true)
    local cnt = 0
    for id, data in pairs(self.contents.data) do
        if not self.inputs:is_input_chest(id) then
            for _, item in pairs(data.items) do
                if item.name == sought_item then
                    cnt = cnt + item.count
                end
            end
        end
    end
    return cnt
end

return count
