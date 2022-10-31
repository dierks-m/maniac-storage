-- Variables --
--- @class Item
--- @field count number
--- @field maxCount number
--- @field displayName string
--- @field name string
local Item = {}
-- Variables --


-- Functions --
local function displayNameMatches(stack, filter)
    if not filter.displayName then
        return true
    end

    return filter.displayName == stack.displayName
end

local function nameMatches(stack, filter)
    if not filter.name then
        return true
    end

    return filter.name == stack.name
end

local function tagsMatch(stack, filter)
    if not filter.tags then
        return true
    end

    for tag in pairs(filter.tags) do
        if not stack.tags[tag] then
            return false
        end
    end

    return true
end

function Item:matches(...)
    local filters = {...}

    for _, filter in pairs(filters) do
        if displayNameMatches(self, filter) and
                nameMatches(self, filter) and
                tagsMatch(self, filter) then
            return true
        end
    end

    return false
end

local function tableDeepCopy(input)
    local output = {}

    for k, v in pairs(input) do
        output[k] = type(v) == "table" and tableDeepCopy(v) or v
    end

    return output
end

--- @return Item
function Item:clone()
    local clone = tableDeepCopy(self)
    setmetatable(clone, getmetatable(self))

    return clone
end

--- @type fun() : Item
local function new(itemStack)
    setmetatable(itemStack, {__index = Item })

    return itemStack
end
-- Functions --


-- Returning of API --
return {
    new = new
}
-- Returning of API --