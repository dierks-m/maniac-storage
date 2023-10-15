--- @class KeyComboHandler
--- @field heldModifiers number[]
local KeyComboHandler = {}

local validModifiers = {
    [keys.leftShift] = true,
    [keys.leftCtrl] = true,
    [keys.leftAlt] = true,
    [keys.rightAlt] = true,
    [keys.rightCtrl] = true,
    [keys.rightAlt] = true,
}

function KeyComboHandler:pullEvent()
    local event = {os.pullEvent()}

    if event[1] == "key" then
        if validModifiers[event[2]] then
            table.insert(self.heldModifiers, event[2])
        elseif #self.heldModifiers > 0 then
            return "key_combo", table.unpack(self.heldModifiers), event[2]
        end
    elseif event[1] == "key_up" then
        for i = 1, #self.heldModifiers do
            if self.heldModifiers[i] == event[2] then
                table.remove(self.heldModifiers, i)
                break
            end
        end
    end

    return table.unpack(event)
end

--- @return KeyComboHandler
function KeyComboHandler.new()
    return setmetatable({heldModifiers={}}, {__index = KeyComboHandler})
end

return KeyComboHandler