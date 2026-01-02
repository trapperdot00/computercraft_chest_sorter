local stack_db = {}
stack_db.__index = stack_db

--==== INTERFACE ====--
--
-- stack_db.new()
--
-- stack_db:add(item_name, stack_size)
-- stack_db:get(item_name)
--
--==== IMPLEMENTATION ====--

function stack_db.new()
    return setmetatable(
        {
            data = {}
        }, stack_db
    )
end

local function throw_if_item_doesnt_exist
(self, item_name)
    if self.data[item_name] == nil then
        error(
            "item '" .. item_name ..
            "' doesn't exist in the" ..
            " stack-size database", 0
        )
    end
end

function stack_db:add(item_name, stack_size)
    self.data[item_name] = stack_size
end

function stack_db:get(item_name)
    throw_if_item_doesnt_exist(self, item_name)
    return self.data[item_name]
end

return stack_db
