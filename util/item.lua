local enchantmentFilter = require("util.enchantmentFilter")

-- Variables --
--- @class Enchantment
--- @field displayName string
--- @field level number
--- @field name string

--- @class Item
--- @field count number
--- @field maxCount number
--- @field displayName string
--- @field name string
--- @field enchantments Enchantment[]
local Item = {}
-- Variables --


-- Functions --
local function nameMatches(stack, filter)
    return filter.name == stack.name
end

local function nbtMatches(stack, filter)
    return stack.nbt == filter.nbt
end

--- @param stack Item
--- @param enchantment Enchantment
local function hasEnchantment(stack, enchantment)
    for _, e in pairs(stack.enchantments) do
        if e.name == enchantment.name and e.level == enchantment.level then
            return true
        end
    end

    return false
end

local function enchantmentsMatch(stack, filter)
    if not self.enchantments then
        return not filter.enchantments
    end

    if not filter.enchantments then
        return false
    end

    for enchantment in pairs(stack.enchantments) do
        if not hasEnchantment(filter, enchantment) then
            return false
        end
    end

    return true
end

--- @param filter Item
function Item:matches(filter)
    -- No need to check display name, tags and item groups, as
    -- the same id (name) will already uniquely identify the item type

    return nameMatches(self, filter)
            and nbtMatches(self, filter)
            and enchantmentsMatch(self, filter)
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

--- @return Item
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