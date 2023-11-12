local uuidTemplate = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

local function substitute(character)
    local value = character == "x" and math.random(0, 15) or math.random(8, 12)

    return string.format("%x", value)
end

local function generateUUID()
    return uuidTemplate:gsub("[xy]", substitute)
end

return {
    generate = generateUUID
}