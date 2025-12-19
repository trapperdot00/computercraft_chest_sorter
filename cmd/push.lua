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
-- (as in item's count is less than its stack size)
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

local function print_input_item_slots(input_item_slots)
    for item, chests in pairs(input_item_slots) do
        print(item)
        for chest_id, slots in pairs(chests) do
            print("  in: "..chest_id, table.unpack(slots))
        end
    end
end

local function print_item_dsts(item_dsts)
    for item_name, dsts in pairs(item_dsts) do
        print(item_name)
        for dst_id, dst_slots in pairs(dsts) do
            print("  "..dst_id, table.unpack(dst_slots))
        end
    end
end

local function print_dsts_dst_frees(dsts, dst_frees)
    for i = 1, #dsts do
        print(dsts[i], dst_frees[i])
    end
end

local function print_plan(plan)
    print(plan.src, '[', plan.src_slot, "] ->", plan.dst, "[", plan.dst_slot, "] {", plan.count, "}")
end

local function print_plans(plans)
    for _, plan in ipairs(plans) do
        print_plan(plan)
    end
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function push.get_existing_slot_filling_plans(self, contents)
    local plans = {}
    local input_item_slots = push.get_input_item_slots(self)
    local item_dsts        = push.get_nonfull_viable_output_slots(self)
    for item_name, inputs in pairs(input_item_slots) do
        local stack_size = self.stacks[item_name]
        for input_id, input_slots in pairs(inputs) do
            local input_contents = contents[input_id]
            for _, input_slot in ipairs(input_slots) do
                print(input_slot, item_name)
                local item      = input_contents.items[input_slot]
                local src_count = item.count
                local dsts     = item_dsts[item_name]
                for dst_id, dst_slots in pairs(dsts) do
                    for _, dst_slot in ipairs(dst_slots) do
                        local dst_contents = contents[dst_id]
                        local dst_item     = dst_contents.items[dst_slot]
                        local dst_count    = dst_item.count
                        print(dst_id, dst_slot, dst_count)
                        local available    = stack_size - dst_count
                        local pushable     = math.min(src_count, available)
                        print(available, pushable)
                        if pushable == 0 then goto next_output_slot end
                        src_count = src_count - pushable
                        local plan = {
                            src      = input_id,
                            dst      = dst_id,
                            src_slot = input_slot,
                            dst_slot = dst_slot,
                            count    = pushable
                        }
                        table.insert(plans, plan)
                        dst_item.count = dst_item.count + pushable
                        if src_count == 0 then
                            goto next_input_slot
                        end
                        ::next_output_slot::
                    end
                    ::next_output::
                end
                ::next_input_slot::
            end
            ::next_input::
        end
        ::next_item::
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
    local contents = deepcopy(self.contents)
    local plans     = push.get_existing_slot_filling_plans(self, contents)
    local tmp_plans = push.get_empty_slot_filling_plans(self, contents)
    table.move(tmp_plans, 1, #tmp_plans, #plans + 1, plans)
    print_plans(plans)
    return plans
end

return push
