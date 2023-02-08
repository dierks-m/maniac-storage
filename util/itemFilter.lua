-- Variables --
--- @class Filter
--- @field filters
local Filter = {}
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

--- @param item Item
function Filter:matches(item)
    for _, filter in pairs(self.filters) do
        if displayNameMatches(item, filter) and
                nameMatches(item, filter) and
                tagsMatch(item, filter) then
            return true
        end
    end

    return false
end

--- @return Filter
local function newFilter(...)
    local filter = {
        filters = {...}
    }

    return setmetatable(filter, {__index = Filter})
end
-- Functions --


-- Returning of API --
return {
    new = newFilter
}
-- Returning of API --