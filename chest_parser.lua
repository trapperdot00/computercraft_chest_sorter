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

return chest_parser
