local get = {}

function get.get_output_chests_containing(self, sought_items)
    local output_names = {}
    local output_slots = {}
    for chest_name, contents in pairs(self.contents) do
        if not self:is_input_chest(chest_name) then
            local slots = {}
            for slot, item in pairs(contents.items) do
                for _, sought_item in ipairs(sought_items) do
                    if item.name == sought_item then
                        if output_names[#output_names] ~= chest_name then
                            table.insert(output_names, chest_name)
                        end
                        table.insert(slots, slot)
                    end
                end
            end
            if #slots > 0 then
                table.insert(output_slots, slots)
            end
        end
    end
    return { names = output_names, slots = output_slots }
end

function get.get_nonfull_input_chests(self)
    local input_names = {}
    local input_slots = {}
    for _, input_name in ipairs(self.inputs) do
        local free_slots = self:get_free_slots(input_name)
        if not self:is_full(input_name) then
            table.insert(input_names, input_name)
            table.insert(input_slots, free_slots)
        end
    end
    return { names = input_names, slots = input_slots }
end

function get.get_get_plans(self, sought_items)
    self:load()
    local plans = {}

    local srcs = get.get_output_chests_containing(self, sought_items)
    local dsts = get.get_nonfull_input_chests(self)

    local src_i = 1
    local dst_i = 1
    while src_i <= #srcs.names and dst_i <= #dsts.names do
        local src        = srcs.names[src_i]
        local src_slot_i = 1
        while src_slot_i <= #srcs.slots[src_i] do
            local src_slots   = srcs.slots[src_i]
            local src_slot    = src_slots[src_slot_i]
            local dst         = dsts.names[dst_i]
            local plan = {
                src      = src,
                dst      = dst,
                src_slot = src_slot
            }
            table.insert(plans, plan)
            dsts.slots[dst_i] = dsts.slots[dst_i] - 1
            if dsts.slots[dst_i] <= 0 then
                dst_i = dst_i + 1
            end
            if dst_i > #dsts.slots then break end
            src_slot_i = src_slot_i + 1
        end
        src_i = src_i + 1
    end

    return plans
end

return get
