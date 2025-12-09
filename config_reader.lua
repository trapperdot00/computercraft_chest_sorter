local config_reader = {}

-- Reads the next character from a file
-- skipping whitespace
--
-- e.g. file: "  apple  " returns 'a',
-- remaining contents of file: "pple  "
function config_reader.read_next_nonspace_char(file)
    local c
    while true do
        c = file:read(1)
        if c ~= "\n" and c ~= " " and c ~= "\t" then
            break
        end
    end
    return c
end

-- Consumes characters up to (including)
-- given character from a file
-- Returns bool, indicating whether it succeeded
--
-- e.g. file: "  apple  "
-- ch = 'l': returns true,
-- remaining contents: "e  "
function config_reader.try_discard_up_to_char(file, ch)
    while true do
        local c = file:read(1)
        if c == nil then break end
        if c == ch then
            return true
        end
    end
    return false
end

-- Reads characters from a file up to
-- (not including) a given character
-- Returns the accumulated string
--
-- e.g. file: "  apple  "
-- ch = 'l': returns "  app"
-- remaining contents: "le  "
function config_reader.read_until_char(file, ch)
    local str = ""
    while true do
        local c = file:read(1)
        if c == nil then break end
        if c ~= ch then
            str = str..c
        else
            file:seek("cur", -1)
            break
        end
    end
    return str
end

-- Reads the next quoted string from a file,
-- skipping any leading whitespace
--
-- e.g. file: '   "four" five'
-- returns: 'four'
-- remaining contents: ' five'
function config_reader.read_quoted(file)
	local starter = config_reader.read_next_nonspace_char(file)
	if starter ~= '"' then return nil end
    local s = config_reader.read_until_char(file, "\"")
    if file:read(1) ~= "\"" then
        error("expected closing quote")
    end
    return s
end

-- Reads a comma-separated list of quoted strings
-- from a file as a sequential table
-- Whitespace between items is ignored
--
-- e.g. file: ' "apple",   " banana ",   "corn" are great'
-- returns: {"apple", " banana ", "corn"}
-- remaining contents: " are great"
function config_reader.read_quoted_items(file)
    local items = {}
    while true do
        local item = config_reader.read_quoted(file)
        if item == nil then break end
        table.insert(items, item)
        if config_reader.read_next_nonspace_char(file) ~= "," then
            file:seek("cur", -1)
            break
        end
    end
    return items
end

-- Reads the next number from a file,
-- skipping any whitespace
--
-- e.g. file: "  123abc "
-- returns: 123
-- remaining contents: "abc "
function config_reader.read_number(file)
    local s = config_reader.read_next_nonspace_char(file)
    if not s:match("%d") then
        error("expected number (got '"..s.."')")
    end
    while true do
        c = file:read(1)
        if not c then break end
        if not c:match("%d") then
            file:seek("cur", -1)
            break
        end
        s = s..c
    end
    return tostring(s)
end

-- Reads an associative configuration file,
-- returns an associative table from its contents:
-- Essentially a dictionary mapping a number to a
-- list of quoted strings
--
-- Keys must be integers
--
-- - File structure grammar: -
-- File         ::= SectionList
-- SectionList  ::= Section | Section ',' SectionList
-- Section      ::= <number> '{' ItemList '}'
-- ItemList     ::= Item | Item ',' ItemList
-- Item         ::= '"' <string> '"' | ""
--
-- - example file: -
-- 1 {
--     "minecraft:chest_1",
--     "minecraft:chest_2"
-- },
-- 2 {
--     "minecraft:chest_3"
-- }
function config_reader.read_assoc(filename, key_prefix)
    local conf = {}
    local file = io.open(filename)
    while true do
        local num = config_reader.read_number(file)
        local starter = config_reader.read_next_nonspace_char(file)
        if starter ~= "{" then
            error("expected { to start section "..num.." "
                    .."in associative file \""..filename.."\" (got '"..starter.."')")
        end
        conf[num] = config_reader.read_quoted_items(file)
        local ender = config_reader.read_next_nonspace_char(file)
        if ender ~= "}" then
            error("expected } to close section "..num.." "
                    .."in associative file \""..filename.."\" (got '"..ender.."')")
        end
        local comma = config_reader.read_next_nonspace_char(file)
        if comma ~= "," then break end
    end
    return conf
end

-- Reads a sequential configuration file
-- returns a sequential table from its contents:
-- Essentially a list of the quoted strings
--
-- - File structure grammar: -
-- File     ::= Section
-- Section  ::= '{' ItemList '}'
-- ItemList ::= Item | Item ',' ItemList
-- Item     ::= '"' <string> '"' | ""
function config_reader.read_seque(filename, key_prefix)
    local conf = {}
    local file = io.open(filename)
    local starter = config_reader.read_next_nonspace_char(file)
    if starter ~= "{" then
        error("expected { to start sequential file \""..filename.."\" (got '"..starter.."')")
    end
    conf = config_reader.read_quoted_items(file)
    local ender = config_reader.read_next_nonspace_char(file)
    if ender ~= "}" then
        error("expected } to close sequential file \""..filename.."\" (got '"..ender.."')")
    end
    return conf
end

return config_reader
