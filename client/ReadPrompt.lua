--- @class ReadPrompt
--- @field currentText string
--- @field cursorPosition number
--- @field horizontalScroll number
--- @field width number
--- @field biDirectionalScroll
--- @field window
local ReadPrompt = {}

local function setCursorPosition(self, position)
    local oldPosition = self.cursorPosition
    self.cursorPosition = math.max(1, math.min(position, #self.currentText + 1))

    if self.biDirectionalScroll then
        if self.cursorPosition <= self.horizontalScroll then
            self.horizontalScroll = self.cursorPosition - 1
        elseif self.cursorPosition > (self.horizontalScroll + self.width) then
            self.horizontalScroll = self.cursorPosition - self.width
        end
    else
        self.horizontalScroll = math.max(0, self.cursorPosition - self.width)
    end

    if position ~= oldPosition then
        self:draw()
        self:focus()
    end
end

local function moveCursor(self, amount)
    setCursorPosition(self, self.cursorPosition + amount)
end

local function getWordLengthForward(self)
    if self.cursorPosition > #self.currentText then
        return 0
    end

    local subString = self.currentText:sub(self.cursorPosition)

    return #(subString:match("^%s?%w+") or subString:match("^%" .. subString:sub(1, 1) .. "*"))
end

local function getWordLengthBackward(self)
    if self.cursorPosition == 1 then
        return 0
    end

    local subString = self.currentText:sub(1, self.cursorPosition - 1)

    return #(subString:match("%w+%s?$") or subString:match("%" .. subString:sub(#subString) .. "*$"))
end

local function deleteForwards(self, amount)
    self.currentText = self.currentText:sub(1, self.cursorPosition - 1)
            .. self.currentText:sub(self.cursorPosition + amount)
    self:draw()
    self:focus()
end

local function deleteBackwards(self, amount)
    self.currentText = self.currentText:sub(1, math.max(0, self.cursorPosition - amount - 1))
            .. self.currentText:sub(self.cursorPosition)
    moveCursor(self, -amount)
    self:draw()
    self:focus()
end

function ReadPrompt:draw()
    self.window.setCursorPos(1, 1)
    self.window.clearLine()
    self.window.setCursorPos(1, 1)
    self.window.write(self.currentText:sub(self.horizontalScroll + 1, self.horizontalScroll + self.width))
end

function ReadPrompt:focus()
    self.window.setCursorPos(self.cursorPosition - self.horizontalScroll, 1)
    self.window.setCursorBlink(true)
end

function ReadPrompt:clear()
    self.currentText = ""
    setCursorPosition(self, 1)
end

function ReadPrompt:processEvent(...)
    local event = {...}

    if event[1] == "char" then
        self.currentText = self.currentText:sub(1, self.cursorPosition - 1)
                .. event[2]
                .. self.currentText:sub(self.cursorPosition)
        moveCursor(self, 1)
    elseif event[1] == "key" then
        if event[2] == keys.left then
            moveCursor(self, -1)
        elseif event[2] == keys.right then
            moveCursor(self, 1)
        elseif event[2] == keys.backspace then
            deleteBackwards(self, 1)
        elseif event[2] == keys.delete then
            deleteForwards(self, 1)
        elseif event[2] == keys.home then
            setCursorPosition(self, 1)
        elseif event[2] == keys["end"] then
            setCursorPosition(self, #self.currentText + 1)
        end
    elseif event[1] == "key_combo" then
        if (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) and event[3] == keys.backspace then
            deleteBackwards(self, getWordLengthBackward(self))
        elseif (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) and event[3] == keys.delete then
            deleteForwards(self, getWordLengthForward(self))
        elseif (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) and event[3] == keys.right then
            moveCursor(self, getWordLengthForward(self))
        elseif (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) and event[3] == keys.left then
            moveCursor(self, -getWordLengthBackward(self))
        end
    end
end

--- @param text string
--- @param win
--- @param uniDirectionalScroll boolean
--- @return ReadPrompt
function ReadPrompt.new(text, win, uniDirectionalScroll)
    assert(text == nil or type(text) == "string", "Text specified must be given in string form")
    assert(win == nil or win and win.getPosition and win.getSize, "Window argument does not seem to match a window's function signature")
    assert(not uniDirectionalScroll or uniDirectionalScroll == true, "Uni-directional scroll must be a boolean value")

    if not win then
        local xPos, yPos = term.getCursorPos()
        local xSize = term.getSize()
        win = window.create(term.current(), xPos, yPos, xSize - xPos + 1, 1)
    end

    local width = win.getSize()

    text = text or ""

    local readPrompt = {
        currentText = text,
        cursorPosition = #text + 1,
        horizontalScroll = 0,
        width = width,
        window = win,
        biDirectionalScroll = not uniDirectionalScroll
    }

    return setmetatable(readPrompt, {__index = ReadPrompt})
end

return ReadPrompt