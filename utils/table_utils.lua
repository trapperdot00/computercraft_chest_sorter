local table_utils = {}

-- Calculate the size of an array-like table,
-- that has nonconsecutive indices.
-- 
-- `#tbl` would return 2 for a table like this:
-- local tbl = {
--     [1] = "a",
--     [2] = "b",
--     [10] = "c",
--     [11] = "d"
-- }
-- , whereas this function would return 4 correctly
function table_utils.size(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Finds a given element inside an array-like table
--
-- found:     Returns a valid index to the found element
--            (in the range [1; #tbl])
-- not found: Returns the table's size
--
--     tbl   : table to search
--     value : value to search for
--     eq    : comparator function that is called
--             with each element inside the table
--             and with value, defaults to ==
function table_utils.find(tbl, value, eq)
    eq = eq or function(a, b) return a == b end
    local i = 1
    while i <= #tbl do
        if eq(tbl[i], value) then break end
        i = i + 1
    end
    return i
end

-- Checks whether an array-like table
-- contains an element with a given value
function table_utils.contains(tbl, value, eq)
    local i = table_utils.find(tbl, value, eq)
    return i <= #tbl
end

-- Returns the keys of an associative table
-- as an array
function table_utils.get_keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

-- { 1 2 2 3 6 8 }
-- { 2 4 6 6 7 8 }
function table_utils.get_common_values(t1, t2)
    local res = {}
    for i = 1, #t1 do
        for j = 1, #t2 do
            if t1[i] == t2[j] and
            not table_utils.contains(res, t1[i])
            then
                table.insert(res, t1[i])
            end
        end
    end
    return res
end

function table_utils.deepcopy(orig, copies)
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
    else
        copy = orig
    end
    return copy
end


return table_utils
