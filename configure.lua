local str       = require("utils.string_utils")
local tbl       = require("utils.table_utils")
local cfg       = require("utils.config_reader")
local configure = {}

local function draw_menu(self)
    local old_bg = term.getBackgroundColor()
    local bg     = colors.cyan
    term.setBackgroundColor(bg)
    print(str.pad("Chest Setup (DOESN'T WORK YET)", ' ', self.width))
    term.setBackgroundColor(old_bg)
end

local function redraw(self)
    local old_bg = term.getBackgroundColor()
    local bg     = colors.blue
    local sbg    = colors.yellow
    term.clear()
    draw_menu(self)
    term.setBackgroundColor(bg)
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
        local color = bg

        if i == self.cursor then
            color = sbg
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

function configure.run()
    local pwd = shell.resolve(".")
    --local inputs = cfg.read_seque(fs.combine(pwd, "inputs.txt"))
    local inputs = {}
    local width, height = term.getSize()
    local self = {
        width = width,
        height = height,
        chests = peripheral.getNames(),
        inputs = inputs,
        start  = 1,
        finish = 1,
        cursor = 1
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
                self.cursor = self.cursor - 1
                if self.start > 1 and self.start == self.cursor then
                    self.start = self.start - 1
                    self.finish = self.finish - 1
                end
            end
        elseif key == keys.down then
            if self.cursor < #self.chests then
                if self.finish == self.cursor then
                    self.start = self.start + 1
                    self.finish = self.finish + 1
                end
                self.cursor = self.cursor + 1
            end
        elseif key == keys.enter then
            print(self.cursor, self.chests[self.cursor])
            local chest = self.chests[self.cursor]
            if tbl.contains(self.inputs, chest) then
                local pos = tbl.find(self.inputs, chest)
                table.remove(self.inputs, pos)
            else
                table.insert(self.inputs, chest)
            end
        elseif key == 'q' then
            break
        end
    end
end

return configure
