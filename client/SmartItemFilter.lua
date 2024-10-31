--- @class SmartItemFilter : Filter
--- @field searchPattern string
local SmartItemFilter = {}

--- @param item Item
--- @param filterPattern string
--- @return boolean
local function anyEnchantmentMatches(item, filterPattern)
    if not item.enchantments then
        return false
    end

    for _, enchantment in pairs(item.enchantments) do
        if enchantment.displayName:lower():match(filterPattern) then
            return true
        end
    end

    return false
end

--- Searches display name, internal name and enchantments with the given search pattern.
--- All sub-filters, separated by spaces, must match. The order of sub-filters is not relevant.
--- However, sub-filters themselves are order-sensitive.
--- Sub-filters may contain uppercase letters to signal the initials of multiple words.
--- Example: `BaPot` will match "Baked Potato", as will `BP`.
--- `Pot Baked` will also match, whereas `PotBak` will not, as a sub-filter must match with the given order.
--- The same mechanic applies to enchantments.
--- However, a single matching enchantment will suffice for the filter to match.
--- @param item Item
--- @return boolean
function SmartItemFilter:matches(item)
    for subFilter in self.searchPattern:gmatch("%S+") do
        local pattern = subFilter:gsub("%U*%u%U*", " %1")
                                 :gsub("^%s+", ""):lower()
                                 :gsub("%s+", "%%S* ")

        if not (item.displayName:lower():match(pattern)
                or item.name:lower():match(pattern)
                or anyEnchantmentMatches(item, pattern)) then
            return false
        end
    end

    return true
end

--- @param pattern string
function SmartItemFilter:setPattern(pattern)
    self.searchPattern = pattern
end

--- @param pattern string
--- @return SmartItemFilter
function SmartItemFilter.new(pattern)
    pattern = pattern or ""
    return setmetatable({pattern = pattern}, {__index = SmartItemFilter})
end

return SmartItemFilter
