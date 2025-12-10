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

function Inventory:load()
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
        self:scan_inputs()
    else
        self:scan()
    end
end

function Inventory:get_nonfull_chests()
    local dests   = {}
    local empties = {}
    for output_id, contents in pairs(self.contents) do
        if not self:is_input_chest(output_id) then
            local occupied = tbl.size(contents.items)
            local empty    = contents.size - occupied
            if empty > 0 then
                table.insert(dests, output_id)
                table.insert(empties, empty)
            end
        end
    end
    return { dests, empties }
end

function Inventory:do_push(dests, empties)
    local pushed = 0
    local dest_i = 1
    for _, input_id in ipairs(self.inputs) do
        local input = peripheral.wrap(input_id)
        local input_data = self.contents[input_id]
        for slot, item in pairs(input_data.items) do
            if input.pushItems(dests[dest_i], slot) > 0 then
                pushed = pushed + 1
                empties[dest_i] = empties[dest_i] - 1
                if empties[dest_i] == 0 then
                    dest_i = dest_i + 1
                end
                if dest_i > #dests then
                    print("No space for remaining items!")
                    break
                end
                output = peripheral.wrap(dests[dest_i])
            end
        end
    end
	return { pushed, dest_i }
end

function Inventory:push()
    self:load()

    -- Pre-calculate viable output chests
    local dests, empties = table.unpack(self:get_nonfull_chests())
    if #dests == 0 then
        print("0 empty slots in output chests!")
        return
    end
    print(#dests .. " viable output chests.")

    -- Push items to output chests
    print("Starting push.")
	local pushed, dest_i = table.unpack(self:do_push(dests, empties))
    print("Pushed " .. pushed .. " slots.")

    if pushed == 0 then return end
    if dest_i > #dests then
        dest_i = #dests
    end

    print("Updating chest database in memory.")
    for i=1, dest_i do
        local chest_name = dests[i]
        self:update_contents(chest_name)
    end
    
    print("Commiting changes to file.")
    self:save_contents()
end

function Inventory:scan()
    self.contents = chest_parser.read_from_chests()
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
