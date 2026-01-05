-- Class data members
local con = require("src.contents")
local inp = require("src.inputs")
local sta = require("src.stacks")

-- Utilities
local inv_db  = require("src.inv_db")
local plan    = require("src.plan")
local tbl     = require("utils.table_utils")
local tskp    = require("utils.task_pool")
local planner = require("src.move_planner")

local inventory = {}
inventory.__index = inventory

local function get_connected_inv_ids()
    local inv_ids = {}
    local invs = { peripheral.find("inventory") }
    for _, inv in ipairs(invs) do
        table.insert(
            inv_ids, peripheral.getName(inv)
        )
    end
    return inv_ids
end

-- Constructs and returns a new instance
-- of inventory
-- Fields:
--   `task_pool`  : An instance of task_pool,
--                  manages the parallelized
--                  execution of tasks.
--   `connected`  : Array of currently visible,
--                  connected inventory
--                  peripherals on the network.
--   `contents`   : An instance of contents
--                  that keeps track of the
--                  inventory contents.
--   `inputs`     : An instance of inputs
--                  that keeps track of the IDs
--                  of input peripherals.
--   `stacks`     : An instance of stacks
--                  that keeps track of each
--                  item's maximum stack size.
function inventory.new
(contents_path, inputs_path, stacks_path)
    -- WARNING: The task buffer can cause
    -- hangs if it is too high!
    local task_buffer = 250
    local task_pool = tskp.new(task_buffer)
    local self = setmetatable({
        task_pool = task_pool,
        connected = get_connected_inv_ids(),
        contents  = con.new(
                        contents_path, task_pool
                    ),
        inputs    = inp.new(inputs_path),
        stacks    = sta.new(
                        stacks_path, task_pool
                    )
    }, inventory)
    if #self.connected == 0 then
        error("No chests found on the network!", 0)
    end
    self.inputs:load()
    return self
end

function inventory:load(noscan)
    for _, input in ipairs(self.inputs.data) do
        if not tbl.contains(
            self.connected, input
        ) then
            error(
                "Input '" .. input ..
                "' not connected!",
                0
            )
        end
    end
    self.stacks:load()
    self.contents:load() 
    if not noscan then
        self:scan_inputs()
    end
end

-- Executes a given list of item-moving plans
-- and updates the affected
-- inventories' databases.
function inventory:carry_out(plans)
    -- Move the specified items
    plan.execute_plans(plans, self.task_pool)
    
    -- Update affected chests in memory
    local affected = plan.affected_chests(plans)
    for _, id in ipairs(affected) do
        local task = function()
            print("updating", id)
            self.contents:update(id)
        end
        self.task_pool:add(task)
    end
    self.task_pool:run()

    -- Update chest database file
    if #affected > 0 then
        print(
            "saving to file", 
            self.contents.filename
        )
        self.contents:save_to_file()
    end
end

local function get_db(db, inputs, is_input)
    local in_db = inv_db.new()
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        if is_input == inputs:is_input_chest(inv_id)
        then
            local inv_size = db:get_size(inv_id)
            local items = db:get_items(inv_id)
            in_db:add_inv(inv_id, inv_size)
            for slot, item in pairs(items) do
                in_db:add_item(
                    inv_id, slot, item
                )
            end
        end
    end
    return in_db
end

function inventory:get_input_db()
    return get_db(
        self.contents.db, self.inputs, true
    )
end

function inventory:get_output_db()
    return get_db(
        self.contents.db, self.inputs, false
    )
end

-- Updates stack size database
-- with the items inside
-- the input inventory peripherals.
-- Parameters:
--     `incl_outputs`: Boolean flag, if provided
--                     and true, will scan output
--                     slots as well as input
--                     slots for stack sizes.
function inventory:update_stacksize(incl_outputs)
    self:load()
    local in_db = self:get_input_db()
    local in_ids = in_db:get_inv_ids()
    for _, inv_id in ipairs(in_ids) do
        local items = in_db:get_items(inv_id)
        local inv = peripheral.wrap(inv_id)
        for slot, _ in pairs(items) do
            local s = slot
            local i = inv
            self.task_pool:add(
                function()
                    local item = i.getItemDetail(s)
                    self.stacks:add(
                        item.name, item.maxCount
                    )
                end
            )
        end
    end
    if incl_outputs == true then
        local out_db = self:get_output_db()
        local out_ids = out_db:get_inv_ids()
        for _, inv_id in ipairs(out_ids) do
            local items = out_db:get_items(inv_id)
            local inv = peripheral.wrap(inv_id)
            for slot, _ in pairs(items) do
                local s = slot
                local i = inv
                self.task_pool:add(
                    function()
                        local item = i.getItemDetail(s)
                        self.stacks:add(
                            item.name, item.maxCount
                        )
                    end
                )
            end
        end
    end
    self.task_pool:run()
end

local function get_dst_names(self)
    local out_db = self:get_output_db()
    return out_db:get_inv_ids()
end

local function print_plans(plans)
    for _, plan in ipairs(plans) do
        print(
            plan.src .. "[" ..
            tostring(plan.src_slot) .. "]->" ..
            plan.dst .. "[" ..
            tostring(plan.dst_slot) .. "]{" ..
            tostring(plan.count) .. "}"
        )
    end
end

-- Push items from the input peripherals
-- into the output peripherals.
function inventory:push()
    self:update_stacksize()
    self.stacks:save_to_file()
    local plans = planner.move(
        tbl.deepcopy(self.contents.db),
        self.stacks,
        self.inputs.data,
        get_dst_names(self)
    )
    self:carry_out(plans)
end

-- Push items from the output peripherals
-- into the input peripherals.
function inventory:pull()
    self:load()
    local plans = planner.move(
        tbl.deepcopy(self.contents.db),
        self.stacks,
        get_dst_names(self),
        self.inputs.data
    )
    self:carry_out(plans)
end

function inventory:get(sought_items)
    self:load()
    local db_cpy = tbl.deepcopy(self.contents.db)
    local plans = {}
    for _, item_name in ipairs(sought_items) do
        local item_plans = planner.move(
            db_cpy,
            self.stacks,
            get_dst_names(self),
            self.inputs.data,
            item_name
        )
        table.move(
            item_plans, 1, #item_plans,
            #plans + 1, plans
        )
    end
    self:carry_out(plans)
end

function inventory:count(sought_items)
    self:load(true)
    local out_db = self:get_output_db()
    local inv_ids = out_db:get_inv_ids()
    -- { ITEM_NAME = COUNT }
    local item_cnt = {}
    for _, sought_item in ipairs(sought_items) do
        for _, inv_id in ipairs(inv_ids) do
            local inv_items = out_db:get_items(
                inv_id
            )
            for slot, item in pairs(inv_items) do
                if item.name == sought_item then
                    if item_cnt[item.name] == nil
                    then
                        item_cnt[item.name] = 0
                    end
                    item_cnt[item.name] =
                        item_cnt[item.name] +
                        item.count
                end
            end
        end
    end
    for item, count in pairs(item_cnt) do
        print(item, count)
    end
end

function inventory:find(sought_items)
    self:load(true)
    local out_db = self:get_output_db()
    local inv_ids = out_db:get_inv_ids()
    -- { ITEM_NAME = { INV_ID } }
    local item_pos = {}
    for _, sought_item in ipairs(sought_items) do
        for _, inv_id in pairs(inv_ids) do
            local inv_items = out_db:get_items(
                inv_id
            )
            for slot, item in pairs(inv_items) do
                if item.name == sought_item then
                    if item_pos[item.name] == nil
                    then
                        item_pos[item.name] = {}
                    end
                    table.insert(
                        item_pos[item.name],
                        inv_id
                    )
                    break
                end
            end
        end
    end
    for item_name, inv_ids in pairs(item_pos) do
        for _, inv_id in ipairs(inv_ids) do
            print(item_name, "->", inv_id)
        end
    end
end

function inventory:size()
    self:load(true)
    local db = self.contents.db
    local inputs = self.inputs
    local src_slots = 0
    local dst_slots = 0
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        local inv_size = db:get_size(inv_id)
        if inputs:is_input_chest(inv_id) then
            src_slots = src_slots + inv_size
        else
            dst_slots = dst_slots + inv_size
        end
    end
    local all_slots = src_slots + dst_slots
    print("[IN] :", src_slots)
    print("[OUT]:", dst_slots)
    print("[ALL]:", all_slots)
end

function inventory:usage()
    self:load(true)
    local db = self.contents.db
    local inputs = self.inputs
    local all = 0
    local occupied = 0
    local inv_ids = db:get_inv_ids()
    for _, inv_id in ipairs(inv_ids) do
        if not inputs:is_input_chest(inv_id) then
            local inv_size = db:get_size(inv_id)
            local full = db:occupied_slots(inv_id)
            all = all + inv_size
            occupied = occupied + full
        end
    end
    local percent = (occupied / all) * 100
    print("[USED]:", occupied)
    print("[ALL] :", all)
    print("["..tostring(percent).."%]")
end

function inventory:scan()
    print("starting scan")
    self.contents:scan()
    print("saving inventory to file")
    self.contents:save_to_file()
    print("updating stack sizes")
    self:update_stacksize(true)
    print("saving stacks to file")
    self.stacks:save_to_file()
end

function inventory:scan_inputs()
    for _, inv_id in ipairs(self.inputs.data) do
        self.contents:update(inv_id)
    end
end

function inventory:configure()
    self.inputs:configure()
end

return inventory
