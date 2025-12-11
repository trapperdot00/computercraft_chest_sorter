local file_utils = {}

function file_utils.exists(filename)
    local file = io.open(filename)
    return file
end

return file_utils
