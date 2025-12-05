local string_utils = {}

function string_utils.split(s, delim)
	local result	= {}
	local begin		= 1
	local delim_pos = 1
	while delim_pos do
		delim_pos = s:find(delim, begin, true)
		if delim_pos then
			table.insert(result, s:sub(begin, delim_pos - 1))
			begin = delim_pos + 1
		end
	end
	return result
end

return string_utils
