-- Variables --
--- @class ItemFilter : Filter
--- @field displayName string
--- @field displayNamePattern string
--- @field name string
--- @field nbt string
--- @field damage number
--- @field enchantments Enchantment[]
--- @field itemGroups ItemGroup[]
--- @field tags table<string, boolean>
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

local function damageMatches(filter, stack)
    return not filter.damage or filter.damage == stack.damage
end

--- @param filter ItemFilter
--- @param tags table<string, boolean>
local function tagsMatch(filter, tags)
    if not filter.tags then
        return true
    elseif type(tags) ~= "table" then
        return false
    end

    for tag in pairs(filter.tags) do
        if not tags[tag] then
            return false
        end
    end

    return true
end

--- @param filter Enchantment
--- @param enchantment Enchantment
local function levelMatches(filter, enchantment)
    return not filter.level or filter.level == enchantment.level
end

--- @param enchantments Enchantment[]
--- @param enchantmentFilter Enchantment
local function hasEnchantment(enchantments, enchantmentFilter)
    for _, enchantment in pairs(enchantments) do
        if displayNameMatches(enchantmentFilter, enchantment)
                and displayNamePatternMatches(enchantmentFilter, enchantment)
                and levelMatches(enchantmentFilter, enchantment) then
            return true
        end
    end

    return false
end

--- @param filter ItemFilter
--- @param enchantments Enchantment[]
local function enchantmentsMatch(filter, enchantments)
    if not filter.enchantments then
        return true
    elseif not enchantments then
        return false
    end

    for _, enchantment in pairs(filter.enchantments) do
        if not hasEnchantment(enchantments, enchantment) then
            return false
        end
    end

    return true
end

--- @param itemGroups ItemGroup[]
--- @param group ItemGroup
local function hasItemGroup(itemGroups, group)
    for _, g in pairs(itemGroups) do
        if g.id == group.id then
            return true
        end
    end

    return false
end

--- @param filter ItemFilter
--- @param itemGroups ItemGroup[]
local function itemGroupsMatch(filter, itemGroups)
    if not filter.itemGroups then
        return true
    elseif not itemGroups then
        return false
    end

    for _, group in pairs(filter.itemGroups) do
        if not hasItemGroup(itemGroups, group) then
            return false
        end
    end

    return true
end

--- @param self ItemFilter
--- @param other ItemFilter
local function equals(self, other)
    if self.displayName ~= other.displayName
            or self.displayNamePattern ~= other.displayNamePattern
            or self.name ~= other.name
            or self.nbt ~= other.nbt
            or self.damage ~= other.damage
            or self.enchantments and not other.enchantments
            or other.enchantments and not self.enchantments
            or self.itemGroups and not other.itemGroups
            or other.itemGroups and not self.itemGroups then
        return false
    end

    if not enchantmentsMatch(self, other.enchantments) then
        return false
    end

    if not itemGroupsMatch(self, other.itemGroups) then
        return false
    end

    if not tagsMatch(self, other.tags) then
        return false
    end

    return true
end

--- @param item Item
function ItemFilter:matches(item)
    return displayNameMatches(self, item)
            and displayNamePatternMatches(self, item)
            and nameMatches(self, item)
            and nbtMatches(self, item)
            and damageMatches(self, item)
            and tagsMatch(self, item.tags)
            and enchantmentsMatch(self, item.enchantments)
            and itemGroupsMatch(self, item.itemGroups)
end

--- @return ItemFilter
ItemFilter.new = function(filter)
    return setmetatable(filter, { __index = ItemFilter, __eq = equals })
end
-- Functions --


-- Returning of API --
return ItemFilter
-- Returning of API --