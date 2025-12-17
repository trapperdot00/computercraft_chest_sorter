local chest_parser = {}

function chest_parser.read_from_chests()
    local chests = { peripheral.find("inventory") }
    local contents = {}
    for _, chest in ipairs(chests) do
        local chest_name = peripheral.getName(chest)
        local chest_data = { size = chest.size(), items = chest.list() }
        contents[chest_name] = chest_data
    end
    return contents
end

function chest_parser.read_from_file(file)
    local contents = file:read("a")
    return textutils.unserialize(contents)
end

function chest_parser.write_to_file(contents, filename)
    local file = io.open(filename, "w")
    local serialized = textutils.serialize(contents)
    file:write(serialized)
end

return chest_parser
