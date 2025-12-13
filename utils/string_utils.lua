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

return string_utils
