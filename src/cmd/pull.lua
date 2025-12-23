local pull = {}

function pull.get_viable_pull_chests(self)
    local input_names  = {}
    local input_slots  = {}
    local output_names = {}
    local output_slots = {}
    for chest_name, contents in pairs(self.contents) do
        if self:is_input_chest(chest_name) then
            if not self:is_full(chest_name) then
                local empty_slots = self:get_free_slots(chest_name)
                table.insert(input_names, chest_name)
                table.insert(input_slots, empty_slots)
            end
        else
            if not self:is_empty(chest_name) then
                table.insert(output_names, chest_name)
                local slots = {}
                for slot, item in pairs(contents.items) do
                    table.insert(slots, slot)
                end
                table.insert(output_slots, slots)
            end
        end
    end
    local input = {
        names = input_names,
        slots = input_slots
    }
    local output = {
        names = output_names,
        slots = output_slots
    }
    return { input, output }
end

function pull.get_pull_plans(self)
    self:load()
    local plans = {}

    local dsts, srcs = table.unpack(
        pull.get_viable_pull_chests(self)
    )

    local dst_i = 1
    local src_i = 1
    while dst_i <= #dsts.names and src_i <= #srcs.names do
        local src       = srcs.names[src_i]
        local src_slots = srcs.slots[src_i]
        for _, src_slot in ipairs(src_slots) do
            local dst = dsts.names[dst_i]
            local plan = {
                src      = src,
                dst      = dst,
                src_slot = src_slot
            }
            table.insert(plans, plan)
            dsts.slots[dst_i] = dsts.slots[dst_i] - 1
            if dsts.slots[dst_i] == 0 then
                dst_i = dst_i + 1
            end
            if dst_i > #dsts.names then break end
        end
        src_i = src_i + 1
    end

    return plans
end

return pull
