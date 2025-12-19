local push = {}

--function push.get_viable_push_chests(self)
--    local output_names    = {}
--    local free_slots_list = {}
--    for output_name, contents in pairs(self.contents) do
--        if not self:is_input_chest(output_name) then
--            local free_slots = self:get_free_slots(output_name)
--            if free_slots > 0 then
--                table.insert(output_names, output_name)
--                table.insert(free_slots_list, free_slots)
--            end
--        end
--    end
--    return output_names, free_slots_list
--end
--

function push.get_nonfull_viable_output_slots(self)
    local item_dst = {}

    for chest_id, contents in pairs(self.contents) do
        if not self:is_input_chest(chest_id) then
            goto next_chest
        end
        for slot, item in pairs(contents.items) do
            local maxCount = self.stack[item.name]
            local dsts = {}
            for dst_id, dst_contents in pairs(self.contents) do
                if self:is_input_chest(dst_id) then
                    goto next_dst
                end
                for dst_slot, dst_item in pairs(dst_contents.items) do
                    if item.name == dst_item.name
                    and dst_item.count < maxCount then
                        local remaining = maxCount - dst_item.count
                        if not dsts[dst_id] then
                            dsts[dst_id] = {}
                        end
                        table.insert(dsts[dst_id], dst_slot)
                    end
                end
                ::next_dst::
            end
            if not item_dst[item.name] then
                item_dst[item.name] = dsts
            else
                table.move(dsts, 1, #dsts, #item_dst[item.name], item_dst[item.name])
            end
        end
        ::next_chest::
    end

    for item, dst in pairs(item_dst) do
        print(item)
        for dst_id, dst_slots in pairs(dst) do
            print(dst_id)
            for _, dst_slot in ipairs(dst_slots) do
                print(dst_slot)
            end
        end
    end
    return item_dst
end

function push.get_push_plans(self)
    self:load()
    local item_dst = push.get_nonfull_viable_output_slots(self)
--    local plans = {}
--
--    local dst_ids, dst_slots = push.get_viable_push_chests(self)
--
--    local src_i = 1
--    local dst_i = 1
--    while src_i <= #self.inputs and dst_i <= #dst_ids do
--        local src = self.inputs[src_i]
--        local src_data = self.contents[src]
--        for src_slot, item in pairs(src_data.items) do
--            local dst = dst_ids[dst_i]
--            local plan = {
--                src      = src,
--                dst      = dst,
--                src_slot = src_slot
--            }
--            table.insert(plans, plan)
--            dst_slots[dst_i] = dst_slots[dst_i] - 1
--            if dst_slots[dst_i] == 0 then
--                dst_i = dst_i + 1
--            end
--            if dst_i > #dst_ids then break end
--        end
--        src_i = src_i + 1
--    end
    
    return plans
end

return push
