-- Variables --
--- @class ItemGroup
--- @field displayName string
--- @field name string

--- @class ItemFilter : Filter
--- @field displayName string
--- @field name string
--- @field nbt string
--- @field enchantments EnchantmentFilter[]
--- @field itemGroups ItemGroup[]
local ItemFilter = {}
-- Variables --


-- Functions --
local function displayNameMatches(filter, stack)
    return not filter.displayName or filter.displayName == stack.displayName
end

local function displayNamePatternMatches(filter, stack)
    return not filter.displayNamePattern or (stack.displayName and stack.displayName:lower():match(filter.displayNamePattern:lower()))
end

local function nameMatches(filter, stack)
    return not filter.name or filter.name == stack.name
end

local function nbtMatches(filter, stack)
    return not filter.nbt or filter.nbt == stack.nbt
end

local function tagsMatch(filter, stack)
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

--- @param filter EnchantmentFilter
--- @param enchantment Enchantment
local function levelMatches(filter, enchantment)
    if not filter.level then
        return true
    end

    return filter.level == enchantment.level
end

--- @param item Item
--- @param enchantmentFilter EnchantmentFilter
local function enchantmentMatches(item, enchantmentFilter)
    if not item.enchantments then
        return false
    end

    for _, enchantment in pairs(item.enchantments) do
        if displayNameMatches(enchantmentFilter, enchantment)
                and displayNamePatternMatches(enchantmentFilter, enchantment)
                and levelMatches(enchantmentFilter, enchantment) then
            return true
        end
    end

    return false
end

--- @param filter ItemFilter
--- @param stack Item
local function enchantmentsMatch(filter, stack)
    if not filter.enchantments then
        return true
    end

    for _, enchantment in pairs(filter.enchantments) do
        if not enchantmentMatches(stack, enchantment) then
            return false
        end
    end

    return true
end

local function hasItemGroup(stack, group)
    for _, g in pairs(stack.itemGroups) do
        if g.id == group.id then
            return true
        end
    end

    return false
end

local function itemGroupsMatch(filter, stack)
    if not filter.itemGroups then
        return true
    end

    for _, group in pairs(stack.itemGroups) do
        if not hasItemGroup(filter, group) then
            return false
        end
    end

    return true
end

--- @param item Item
function ItemFilter:matches(item)
    return displayNameMatches(self, item)
            and displayNamePatternMatches(self, item)
            and nameMatches(self, item)
            and nbtMatches(self, item)
            and tagsMatch(self, item)
            and enchantmentsMatch(self, item)
            and itemGroupsMatch(self, item)
end

--- @return ItemFilter
ItemFilter.new = function(filter)
    return setmetatable(filter, {__index = ItemFilter })
end
-- Functions --


-- Returning of API --
return ItemFilter
-- Returning of API --