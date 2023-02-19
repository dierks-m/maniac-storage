--- @class EnchantmentFilter : Enchantment
--- @field displayName string
--- @field displayNamePattern string
--- @field level number
--- @field name string

--- @param filter EnchantmentFilter
--- @param enchantment Enchantment
local function displayNameMatches(filter, enchantment)
    if not filter.displayName then
        return true
    end

    return filter.displayName == enchantment.displayName
end

--- @param filter EnchantmentFilter
--- @param enchantment Enchantment
local function displayNamePatternMatches(filter, enchantment)
    if not filter.displayNamePattern then
        return true
    end

    return enchantment.displayName:match(filter.displayNamePattern)
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
local function matches(item, enchantmentFilter)
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

return {
    matches = matches
}