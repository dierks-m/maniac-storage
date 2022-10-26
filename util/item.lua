-- Variables --
local itemTableMT = {}
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

function itemTableMT:matches(...)
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

local function new(itemStack)
    setmetatable(itemStack, {__index = itemTableMT})

    return itemStack
end
-- Functions --


-- Returning of API --
return {
    new = new
}
-- Returning of API --