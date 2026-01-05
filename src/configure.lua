local str = require("utils.string_utils")
local tbl = require("utils.table_utils")

local configure = {}

local function draw_menu(self)
    local title  = "Chest Setup"
    local old_bg = term.getBackgroundColor()
    term.setBackgroundColor(self.menucolor)
    print(str.pad(title, ' ', self.width))
    term.setBackgroundColor(old_bg)
end

local function redraw(self)
    local old_bg = term.getBackgroundColor()
    term.clear()
    draw_menu(self)
    term.setBackgroundColor(self.bgcolor)
    local i = self.start
    local n = self.finish
    local lines = {}
    for i = self.start, self.finish do
        local chest = self.chests[i]
        if tbl.contains(self.inputs, chest) then
            chest = "[IN]  " .. chest
        else
            chest = "[OUT] " .. chest
        end
        local text  = str.rpad(chest, ' ', self.width)
        local color = self.bgcolor

        if i == self.cursor then
            color = self.hlcolor
        end
        table.insert(lines, { text = text, color = color })
        i = i + 1
    end
    table.insert(lines, {
        text  = str.from_n_chars(self.width, '-'),
        color = colors.black
    })
    for i = 1, self.height + self.start - self.finish - 4 do
        table.insert(lines, '')
    end
    for _, line in ipairs(lines) do
        if line.color ~= nil then
            term.setBackgroundColor(line.color)
        end
        if line.text ~= nil then
            print(line.text)
        else
            print()
        end
    end
    term.setBackgroundColor(old_bg)
end

local function get_inventory_names(extras)
    local invs = { peripheral.find("inventory") }
    local inv_names = {}
    for i = 1, #invs do
        local inv_name = peripheral.getName(invs[i])
        table.insert(inv_names, inv_name)
    end
    for _, inv_name in ipairs(extras) do
        if not tbl.contains(inv_names, inv_name)
        then
            table.insert(inv_names, inv_name)
        end
    end
    return inv_names
end

function configure.run(filename)
    local inputs = {}
    if fs.exists(filename) then
        local f = io.open(filename)
        if not f then
            error(
                "cannot open file '" ..
                filename ..
                "' for reading", 0
            )
        end
        inputs = textutils.unserialize(
            f:read('a')
        )
    end
    local width, height = term.getSize()
    local self = {
        -- Screen dimensions
        width     = width,
        height    = height,
        -- Chest data
        chests    = get_inventory_names(inputs),
        inputs    = inputs,
        -- Visible elements
        start     = 1,
        finish    = 1,
        cursor    = 1,
        -- Colors
        menucolor = colors.brown,
        bgcolor   = colors.gray,
        hlcolor   = colors.red
    }
    self.finish = self.height - 3
    if self.finish > #self.chests then
        self.finish = #self.chests
    end
    while true do
        redraw(self)
        local _, key = os.pullEvent("key")
        if key == keys.up then
            if self.cursor > 1 then
                if self.start > 1 and self.start == self.cursor then
                    self.start = self.start - 1
                    self.finish = self.finish - 1
                end
                self.cursor = self.cursor - 1
            end
        elseif key == keys.down then
            if self.cursor < #self.chests then
                if self.finish == self.cursor then
                    self.start = self.start + 1
                    self.finish = self.finish + 1
                end
                self.cursor = self.cursor + 1
            end
        elseif key == keys.enter
            or key == keys.space then
            local chest = self.chests[self.cursor]
            if tbl.contains(self.inputs, chest) then
                local pos = tbl.find(self.inputs, chest)
                table.remove(self.inputs, pos)
            else
                table.insert(self.inputs, chest)
            end
        elseif keys.getName(key) == 'q' then
            os.pullEvent(char)
            break
        end
    end
    return self.inputs
end

return configure
