local debugger			= require("debugger")
local work_delegator	= {}

local function print_inputs(inventory)
	debugger.print_seque(inventory.inputs)
end

local function print_help()
	print("usage: " .. arg[0] .. " [options]")
	print("options: --push --pull --scan")
	print("			--get=<item1>[,<itemN>]...")
	print("			--count=<item1>[,<itemN>]...")
	print("			--print-inputs")
end

function work_delegator.delegate(options, inventory)
	if options.push then
		inventory:push()
	elseif options.pull then
		inventory:pull()
	elseif options.scan then
		inventory:scan()
	elseif #options.get > 0 then
		inventory:get(options.get)
	elseif #options.count > 0 then
		inventory:count(options.count)
	elseif options.print_inputs then
		print_inputs(inventory)
	else
		print_help()
	end
end

return work_delegator
