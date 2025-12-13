local string_utils = {}

function string_utils.split(s, delim)
    local result    = {}
    local begin     = 1
    local delim_pos = 1
    while delim_pos do
        delim_pos = s:find(delim, begin, true)
        if delim_pos then
            local substring = s:sub(begin, delim_pos - 1)
            if #substring > 0 then
                table.insert(result, substring)
            end
            begin = delim_pos + 1
        end
    end
    local substring = s:sub(begin, #s)
    if #substring > 0 then
        table.insert(result, substring)
    end
    return result
end

function string_utils.rpad(s, ch, width)
    while s:len() < width do
        s = s .. ch
    end
    return s
end

function string_utils.lpad(s, ch, width)
    while s:len() < width do
        s = ch .. s
    end
    return s
end

function string_utils.pad(s, ch, width)
    while s:len() < width do
        if s:len() % 2 == 0 then
            s = ch .. s
        else
            s = s .. ch
        end
    end
    return s
end

function string_utils.from_n_chars(n, ch)
    local s = ch
    for i = 1, n - 1 do
        s = s .. ch
    end
    return s
end

return string_utils
