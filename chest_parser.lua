local chest_parser = {}

function chest_parser.get_chest_contents()
	local chests = { peripheral.find("minecraft:chest") }
	local contents = {}
	for _, chest in ipairs(chests) do
		local chest_name = peripheral.getName(chest)
		contents[chest_name] = chest.list()
	end
	return contents
end

function chest_parser.write_to_file(contents, filename)
    local file = io.open(filename, "w")
    local serialized = textutils.serialize(contents)
    file:write(serialized)
    file:close()
end

return chest_parser
