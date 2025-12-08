local chest_parser = {}

function chest_parser.load_chest_contents()
	local chests = { peripheral.find("minecraft:chest") }
	local contents = {}
	for _, chest in ipairs(chests) do
		local chest_name = peripheral.getName(chest)
		contents[chest_name] = chest.list()
	end
	return contents
end

function chest_parser.save_chest_contents_to_file(contents, filename)
	local serialized = textutils.serialize(contents)
	print(serialized)
end

return chest_parser
