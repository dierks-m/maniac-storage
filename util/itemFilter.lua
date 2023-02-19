local enchantmentFilter = require("util.enchantmentFilter")

-- Variables --
--- @class ItemFilter : Filter
--- @field displayName string
--- @field displayNamePattern string
--- @field name string
--- @field tags string[]
--- @field enchantments EnchantmentFilter[]
local ItemFilter = {}
-- Variables --


-- Functions --
local function displayNameMatches(stack, filter)
    if not filter.displayName then
        return true
    end

    return filter.displayName == stack.displayName
end

local function displayNamePatternMatches(stack, filter)
    if not filter.displayNamePattern then
        return true
    end

    return stack.displayName:match(filter.displayNamePattern)
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

--- @param stack Item
--- @param filter ItemFilter
local function enchantmentsMatch(stack, filter)
    if not filter.enchantments then
        return true
    end

    for _, enchantment in pairs(filter.enchantments) do
        if not enchantmentFilter.matches(stack, enchantment) then
            return false
        end
    end

    return true
end

function ItemFilter:matches(item)
    return displayNameMatches(item, self)
            and displayNamePatternMatches(item, self)
            and nameMatches(item, self)
            and tagsMatch(item, self)
            and enchantmentsMatch(item, self)
end

--- @return ItemFilter
local function newFilter(filter)
    return setmetatable(filter, {__index = ItemFilter })
end
-- Functions --


-- Returning of API --
return {
    new = newFilter
}
-- Returning of API --