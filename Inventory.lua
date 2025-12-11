local tbl          = require("table_utils")
local chest_parser = require("chest_parser")

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(inputs, filename)
    local self = setmetatable({}, Inventory)
    self.inputs   = inputs
    self.filename = filename
    self.contents = nil
    return self
end

function Inventory:load(noscan)
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
        if not noscan then
            self:scan_inputs()
        end
    else
        self:scan()
    end
end

-- Viable outputs: output chests with at least one free slot
function Inventory:get_viable_push_chests()
    local output_names    = {}
    local free_slots_list = {}
    for output_name, contents in pairs(self.contents) do
        if not self:is_input_chest(output_name) then
            local nonfree_slots = tbl.size(contents.items)
            local free_slots    = contents.size - nonfree_slots
            if free_slots > 0 then
                table.insert(output_names, output_name)
                table.insert(free_slots_list, free_slots)
            end
        end
    end
    return { output_names, free_slots_list }
end

-- Viable inputs:  input chests with at least 1 free slot
-- Viable outputs: output chests with at least 1 non-free slot
function Inventory:get_viable_pull_chests()
    local input_names  = {}
    local input_slots  = {} -- Empty slot counts
    local output_names = {}
    local output_slots = {} -- Lists of full slots
    for chest_name, contents in pairs(self.contents) do
        local full_slots = tbl.size(contents.items)
        if self:is_input_chest(chest_name) then
            if contents.size > full_slots then
                local empty_slots = contents.size - full_slots
                table.insert(input_names, chest_name)
                table.insert(input_slots, empty_slots)
            end
        else
            if full_slots > 0 then
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

function Inventory:get_output_chests_containing(sought_items)
    local output_names = {} -- List of output chests
    local output_slots = {} -- List of slots with sought item
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

function Inventory:get_nonfull_input_chests()
    local input_names = {} -- List of viable input chests to pull into
    local input_slots = {} -- Free-slot counts
    for _, input_name in ipairs(self.inputs) do
        local contents      = self.contents[input_name]
        local nonfree_slots = tbl.size(contents.items)
        local free_slots    = contents.size - nonfree_slots
        if free_slots > 0 then
            table.insert(input_names, input_name)
            table.insert(input_slots, free_slots)
        end
    end
    return { names = input_names, slots = input_slots }
end

function Inventory:do_push(output_names, free_slots_list)
    local pushed   = 0
    local input_i  = 1
    local output_i = 1
    while input_i  <= #self.inputs
    and   output_i <= #output_names do
        local input_id   = self.inputs[input_i]
        local input      = peripheral.wrap(input_id)
        local input_data = self.contents[input_id]
        for slot, item in pairs(input_data.items) do
            if input.pushItems(output_names[output_i], slot) > 0 then
                pushed = pushed + 1
                free_slots_list[output_i] = free_slots_list[output_i] - 1
                if free_slots_list[output_i] == 0 then
                    output_i = output_i + 1
                end
                if output_i > #output_names then break end
            end
        end
        input_i = input_i + 1
    end
    return { pushed, output_i }
end

function Inventory:do_pull(input, output)
    local pulled   = 0
    local input_i  = 1
    local output_i = 1
    while output_i <= #output.names
    and   input_i  <= #input.names do
        local output_name = output.names[output_i]
        local slots       = output.slots[output_i]
        for _, slot in ipairs(slots) do
            local input_chest = peripheral.wrap(input.names[input_i])
            if input_chest.pullItems(output_name, slot) > 0 then
                pulled = pulled + 1
            end
            input.slots[input_i] = input.slots[input_i] - 1
            if input.slots[input_i] == 0 then
                input_i = input_i + 1
            end
        end
        output_i = output_i + 1
    end
    return { pulled, output_i }
end

function Inventory:do_get(input, output, sought_items)
    local got      = 0
    local output_i = 1
    local input_i  = 1
    while output_i <= #output.names
    and   input_i  <= #input.names do
        local output_name = output.names[output_i]
        local output_chest = peripheral.wrap(output_name)
        local output_slot_i = 1
        while output_slot_i <= #output.slots[output_i] do
            local output_slot = output.slots[output_i][output_slot_i]
            local input_name = input.names[input_i]
            if output_chest.pushItems(input_name, output_slot) > 0 then
                got = got + 1
            end
            input.slots[input_i] = input.slots[input_i] - 1
            if input.slots[input_i] <= 0 then
                input_i = input_i + 1
            end
            output_slot_i = output_slot_i + 1
        end
        output_i = output_i + 1
    end
    return { got, output_i }
end

function Inventory:push()
    self:load()

    print("Calculating viable chests.")
    local output_names, free_slots_list = table.unpack(
        self:get_viable_push_chests()
    )
    print(#output_names .. " viable output chests.")
    if #output_names == 0 then return end

    print("Starting push.")
    local pushed, output_i = table.unpack(
        self:do_push(output_names, free_slots_list)
    )
    print("Pushed " .. pushed .. " slots.")

    if pushed == 0 then return end
    if output_i > #output_names then
        output_i = #output_names
    end

    print("Updating chest database in memory.")
    self:update_chests(output_names, 1, output_i)
    
    print("Commiting changes to file '" .. self.filename .. "'.")
    self:save_contents()
end

function Inventory:pull()
    self:load()

    print("Calculating viable chests.")
    local input, output = table.unpack(
        self:get_viable_pull_chests()
    )
    print(#input.names  .. " viable input chests.")
    print(#output.names .. " viable output chests.")
    if #input.names == 0 or #output.names == 0 then return end

    print("Starting pull.")
    local pulled, output_i = table.unpack(
        self:do_pull(input, output)
    )
    print("Pulled " .. pulled .. " slots.")

    if pulled == 0 then return end
    if output_i > #output.names then
        output_i = #output.names
    end

    print("Updating chest database in memory.")
    self:update_chests(output.names, 1, output_i)

    print("Commiting changes to file '" .. self.filename .. "'.")
    self:save_contents()
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
    self:save_contents()
end

function Inventory:get(sought_items)
    self:load(true)

    print("Calculating viable chests.")
    local output = self:get_output_chests_containing(sought_items)

    self:scan_inputs()
    local input = self:get_nonfull_input_chests()
    print(#output.names .. " viable output chests.")
    print(#input.names  .. " viable input chests.")
    if #output.names == 0 or #input.names == 0 then return end
    
    print("Starting get.")
    local got, output_i = table.unpack(
        self:do_get(input, output, sought_items)
    )
    print("Got " .. got .. " slots.")

    if got == 0 then return end
    if output_i > #output.names then
        output_i = #output.names
    end

    print("Updating chest database in memory.")
    self:update_chests(output.names, 1, output_i)

    print("Commiting changes to file '" .. self.filename .. "'.")
    self:save_contents()
end

function Inventory:scan_inputs()
    for _, chest_name in ipairs(self.inputs) do
        self:update_contents(chest_name)
    end
    self:save_contents()
end

function Inventory:update_contents(chest_id)
    local chest = peripheral.wrap(chest_id)
    local chest_data = { size = chest.size(), items = chest.list() }
    self.contents[chest_id] = chest_data
end

function Inventory:update_chests(chest_list, start_, end_)
    for i = start_, end_ do
        local chest_name = chest_list[i]
        print("Updating " .. chest_name)
        self:update_contents(chest_name)
    end
end

function Inventory:save_contents()
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:is_input_chest(chest_id)
    for _, input_name in ipairs(self.inputs) do
        if chest_id == input_name then
            return true
        end
    end
    return false
end

function Inventory:has_empty_slot(chest_id)
    local size  = self.contents[chest_id].size
    local count = 0
    for slot, item in pairs(self.contents[chest_id].items) do
        count = count + 1
    end
    return count ~= size
end

function Inventory:count(sought_item)
    self:load()
    local count = 0
    for chest_name, content in pairs(self.contents) do
        for slot, item in pairs(content) do
            if item.name == sought_item then
                count = count + item.count
            end
        end
    end
    return count
end

return Inventory
