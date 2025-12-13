local push = {}

function push.get_viable_push_chests(self)
    local output_names    = {}
    local free_slots_list = {}
    for output_name, contents in pairs(self.contents) do
        if not self:is_input_chest(output_name) then
            local free_slots = self:get_free_slots(output_name)
            if free_slots > 0 then
                table.insert(output_names, output_name)
                table.insert(free_slots_list, free_slots)
            end
        end
    end
    return { output_names, free_slots_list }
end

function push.get_push_plans(self)
    self:load()
    local plans = {}

    local dst_ids, dst_slots = table.unpack(
        push.get_viable_push_chests(self)
    )

    local src_i = 1
    local dst_i = 1
    while src_i <= #self.inputs and dst_i <= #dst_ids do
        local src = self.inputs[src_i]
        local src_data = self.contents[src]
        for src_slot, item in pairs(src_data.items) do
            local dst = dst_ids[dst_i]
            local plan = {
                src      = src,
                dst      = dst,
                src_slot = src_slot
            }
            table.insert(plans, plan)
            dst_slots[dst_i] = dst_slots[dst_i] - 1
            if dst_slots[dst_i] == 0 then
                dst_i = dst_i + 1
            end
            if dst_i > #dst_ids then break end
        end
        src_i = src_i + 1
    end
    
    return plans
end

return push
