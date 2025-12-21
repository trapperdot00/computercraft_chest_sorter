local tbl = require("utils.table_utils")

local push = {}

-- Get a list of output IDs and a list of free slots.
-- The two lists are connected through indices:
-- the output ID at index 10 has the free slot at index 10
-- number of free slots available.
-- The free slots are the slots that have no items in them
-- whatsoever.
function push.get_nonfull_output_chests(self)
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
    return output_names, free_slots_list
end

-- Get an associative table that maps item names
-- to an associative table that maps output chest IDs
-- to slot indices that denote slots in output chests
-- that are not empty, nor full.
-- (as in item's count not zero and is less than its stack size)
function push.get_nonfull_viable_output_slots(self)
    local item_dst = {}
    for chest_id, contents in pairs(self.contents) do
        if not self:is_input_chest(chest_id) then
            goto next_chest
        end
        for slot, item in pairs(contents.items) do
            local maxCount = self.stacks[item.name]
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
    return item_dst
end

-- Get an associative table that maps an item name
-- to an associative table that maps a chest ID
-- to a list of slots.
function push.get_input_item_slots(self)
    local input_item_slots = {}
    local work = function(chest_id, slot, item)
        if not input_item_slots[item.name] then
            input_item_slots[item.name] = {}
        end
        if not input_item_slots[item.name][chest_id] then
            input_item_slots[item.name][chest_id] = {}
        end
        local entry = input_item_slots[item.name][chest_id]
        table.insert(entry, slot)
    end
    self:for_each_input_slot(work)
    return input_item_slots
end

function push.get_existing_slot_filling_plans(self, contents)
    local plans = {}
    
    ------------- FORMERLY input_item_slots
    local srcs         = push.get_input_item_slots(self)            -- { item = { src_ids  = { slot1, ... slotN } } }

    ------------- FORMERLY item_dsts
    local dsts         = push.get_nonfull_viable_output_slots(self) -- { item = { dst_ids = { slot1, ... slotN } } }

    local srcs_items   = tbl.get_keys(srcs)
    local dsts_items   = tbl.get_keys(dsts)
    local items = tbl.get_common_values(srcs_items, dsts_items)
    local items_i = 1

    while items_i <= #srcs_items do
        local item_name = srcs_items[items_i]
        local stack_size = self.stacks[item_name]
        
        -- { ID = { slot1, slot2, ..., slotN } }
        local src_chests = srcs[item_name]
        local dst_chests = dsts[item_name]

        -- { ID1, ID2, ..., ID_N }
        local src_ids = tbl.get_keys(src_chests)
        local dst_ids = tbl.get_keys(dst_chests)

        local src_id_i = 1
        local dst_id_i = 1

        local src_slot_i = 1
        local dst_slot_i = 1

        while src_id_i <= #src_ids and
              dst_id_i <= #dst_ids do
            local src_id = src_ids[src_id_i]
            local dst_id = dst_ids[dst_id_i]

            local src_data = contents[src_id]
            local dst_data = contents[dst_id]

            local src_slots = src_chests[src_id]
            local dst_slots = dst_chests[dst_id]
            
            local src_slot = src_slots[src_slot_i]
            local dst_slot = dst_slots[dst_slot_i]

            local src_item = src_data.items[src_slot]
            local dst_item = dst_data.items[dst_slot]

            local dst_cap = stack_size - dst_item.count
            local cnt = math.min(src_item.count, dst_cap)

            if cnt ~= 0 then
                local plan = {
                    src      = src_id,
                    dst      = dst_id,
                    src_slot = src_slot,
                    dst_slot = dst_slot,
                    count    = cnt
                }
                table.insert(plans, plan)
                src_item.count = src_item.count - cnt
                dst_item.count = dst_item.count + cnt
                if src_item.count == 0 then
                    -- Go to next input slot
                    src_slot_i = src_slot_i + 1
                    -- Go to next input chest
                    if src_slot_i > #src_slots then
                        src_id_i   = src_id_i + 1
                        src_slot_i = 1
                    end
                end
            else
                dst_slot_i = dst_slot_i + 1
                if dst_slot_i > #dst_slots then
                    -- Go to next output chest
                    dst_id_i   = dst_id_i + 1
                    dst_slot_i = 1
                end
            end
        end
        items_i = items_i + 1
    end
    return plans
end

function push.get_empty_slot_filling_plans(self, contents)
    local plans = {}
    local dst_ids, dst_slots = push.get_nonfull_output_chests(self)
    local src_i = 1
    local dst_i = 1
    while src_i <= #self.inputs and dst_i <= #dst_ids do
        local src = self.inputs[src_i]
        local src_data = contents[src]
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

function push.get_push_plans(self)
    self:load()
    local contents = tbl.deepcopy(self.contents)
    local plans     = push.get_existing_slot_filling_plans(self, contents)
    --local tmp_plans = push.get_empty_slot_filling_plans(self, contents)
    --table.move(tmp_plans, 1, #tmp_plans, #plans + 1, plans)
    return plans
end

return push
