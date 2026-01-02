local tbl = require("utils.table_utils")

local push = {}

-- Get a list of output IDs and a list of free slots.
-- The two lists are connected through indices:
-- the output ID at index 10 has the free slot at index 10
-- number of free slots available.
-- The free slots are the slots that have no items in them
-- whatsoever.
function push.get_nonfull_output_chests(self, db)
    local output_names    = {}
    local free_slots_list = {}
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        if not self.inputs:is_input_chest(inv_id) then
            local free_slots = db:free_slots(inv_id)
            if free_slots > 0 then
                table.insert(output_names, inv_id)
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
function push.get_nonfull_viable_output_slots(self, db)
    local item_dst = {}
    local inv_ids = db:get_inv_ids()
    for _, src_id in ipairs(inv_ids) do
        if not self.inputs:is_input_chest(src_id) then
            goto next_chest
        end
        local src_items = db:get_items(src_id)
        for slot, item in pairs(src_items) do
            local maxCount =
                self.stacks:get(item.name)
            local dsts = {}
            for _, dst_id in ipairs(inv_ids) do
                if self.inputs:is_input_chest(dst_id) then
                    goto next_dst
                end
                local dst_items = db:get_items(dst_id)
                for dst_slot, dst_item in pairs(dst_items) do
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
    local work = function(inv_id, inv_size,
                          slot, item)
        if not input_item_slots[item.name] then
            input_item_slots[item.name] = {}
        end
        if not input_item_slots[item.name][inv_id] then
            input_item_slots[item.name][inv_id] = {}
        end
        local entry = input_item_slots[item.name][inv_id]
        table.insert(entry, slot)
    end
    self:for_each_input_slot(work)
    return input_item_slots
end

function push.get_existing_slot_filling_plans(self, db)
    local plans = {}

    -- Viable chest data
    -- { item = { ids = { slot1, ... slotN } } }
    local srcs = push.get_input_item_slots(self, db)
    local dsts = push.get_nonfull_viable_output_slots(self, db)

    -- All items in chests
    local srcs_items = tbl.get_keys(srcs)
    local dsts_items = tbl.get_keys(dsts)
    -- Common items in chests
    local items = tbl.get_common_values(
        srcs_items, dsts_items
    )
    local items_i = 1

    while items_i <= #srcs_items do
        -- Get info for current item
        local item_name  = srcs_items[items_i]
        local stack_size =
            self.stacks:get(item_name)
        -- Chests and slots that contain this item
        -- { ID = { slot1, slot2, ..., slotN } }
        local src_chests = srcs[item_name]
        local dst_chests = dsts[item_name]
        -- Chest IDs
        -- { ID1, ID2, ..., ID_N }
        local src_ids = tbl.get_keys(src_chests)
        local dst_ids = tbl.get_keys(dst_chests)
        -- Chest ID indices
        local src_id_i = 1
        local dst_id_i = 1
        -- Chest slot indices
        local src_slot_i = 1
        local dst_slot_i = 1

        while src_id_i <= #src_ids and
              dst_id_i <= #dst_ids do
            -- Current chest ID
            local src_id = src_ids[src_id_i]
            local dst_id = dst_ids[dst_id_i]
            -- Current chest contents
            local src_data = db:get_items(src_id)
            local dst_data = db:get_items(dst_id)
            -- Slots that contain the current item
            -- inside the current chest
            local src_slots = src_chests[src_id]
            local dst_slots = dst_chests[dst_id]
            -- Current slot
            local src_slot = src_slots[src_slot_i]
            local dst_slot = dst_slots[dst_slot_i]
            -- Current item table
            local src_item = db:get_item(src_id, src_slot)
            local dst_item = db:get_item(dst_id, dst_slot)

            -- Slot item capacity to full
            local dst_cap = stack_size - dst_item.count
            -- Pushable item count 
            -- from input slot to output slot
            local cnt = math.min(src_item.count, dst_cap)

            -- Can we push into this output slot?
            if 0 < cnt then
                -- Can push: we have a plan
                local plan = {
                    src      = src_id,
                    dst      = dst_id,
                    src_slot = src_slot,
                    dst_slot = dst_slot,
                    count    = cnt
                }
                table.insert(plans, plan)
                -- Update chest contents in memory
                -- as if the plan had been
                -- carried out
                src_item.count = src_item.count - cnt
                dst_item.count = dst_item.count + cnt
                if src_item.count == 0 then
                    -- Go to next input slot
                    db:del_item(src_id, src_slot)
                    src_slot_i = src_slot_i + 1
                    -- Go to next input chest
                    if src_slot_i > #src_slots then
                        src_id_i   = src_id_i + 1
                        src_slot_i = 1
                    end
                end
            else -- Can't push: output must be full
                -- Go to next output slot
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

function push.get_empty_slot_filling_plans(self, db)
    local plans = {}
    local dst_ids, dst_slots = push.get_nonfull_output_chests(self, db)
    local src_i = 1
    local dst_i = 1
    while src_i <= #self.inputs.data and dst_i <= #dst_ids do
        local src = self.inputs.data[src_i]
        local src_items = db:get_items(src)
        for src_slot, item in pairs(src_items) do
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

function push.get_plans(self)
    self:load()
    local db = tbl.deepcopy(self.contents.db)
    local plans = push.get_existing_slot_filling_plans(self, db)
    local tmp_plans = push.get_empty_slot_filling_plans(self, db)
    table.move(tmp_plans, 1, #tmp_plans, #plans + 1, plans)
    return plans
end

return push
