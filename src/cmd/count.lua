local count = {}

function count.count(self, sought_item)
    self:load(true)
    local cnt = 0
    for chest_name, contents in pairs(self.contents) do
        if self:is_input_chest(chest_name) then goto continue1 end
        for _, item in pairs(contents.items) do
            if item.name ~= sought_item then goto continue2 end
            cnt = cnt + item.count
            ::continue2::
        end
        ::continue1::
    end
    return cnt
end

return count
