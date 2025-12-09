local chest_parser = require("chest_parser")

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(filename)
    local self = setmetatable({}, Inventory)
    self.filename = filename
    return self
end

function Inventory:load()
    if self.contents then return end
    local file = io.open(self.filename)
    if file then
        self.contents = chest_parser.read_from_file(file)
    else
        self:update()
    end
end

function Inventory:update()
    self.contents = chest_parser.read_from_chests()
    chest_parser.write_to_file(self.contents, self.filename)
end

function Inventory:item_count(sought_item)
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

function Inventory:

return Inventory
