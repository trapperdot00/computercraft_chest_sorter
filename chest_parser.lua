local chest_parser = {}

-- 
function chest_parser.read_from_chests()
	local chests = { peripheral.find("minecraft:chest") }
	local contents = {}
	for _, chest in ipairs(chests) do
		local chest_name = peripheral.getName(chest)
		contents[chest_name] = chest.list()
	end
	return contents
end

function chest_parser.read_from_file(filename)
	local file = io.open(filename)
	local contents = file:read("a")
	file:close()
	return textutils.unserialize(contents)
end

function chest_parser.write_to_file(contents, filename)
    local file = io.open(filename, "w")
    local serialized = textutils.serialize(contents)
    file:write(serialized)
    file:close()
end

function chest_parser.item_count(contents, sought_item)
	local count = 0
	for chest_name, content in pairs(contents) do
		for slot, item in pairs(content) do
			if item.name == sought_item then
				count = count + item.count
			end
		end
	end
	return count
end

return chest_parser
