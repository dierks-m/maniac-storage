-- Variables --
--- @class Enchantment
--- @field displayName string
--- @field level number
--- @field name string

--- @class ItemGroup
--- @field displayName string
--- @field name string

--- @class Item
--- @field count number
--- @field maxCount number
--- @field displayName string
--- @field name string
--- @field nbt string
--- @field enchantments Enchantment[]
--- @field tags table<string, boolean>
--- @field itemGroups ItemGroup[]
local Item = {}
-- Variables --


-- Functions --
--- @param self Item
--- @param other Item
local function nameMatches(self, other)
    return other.name == self.name
end

--- @param self Item
--- @param other Item
local function nbtMatches(self, other)
    return self.nbt == other.nbt
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

--- @param self Item
--- @param other Item
local function enchantmentsMatch(self, other)
    if not self.enchantments then
        return not other.enchantments
    end

    if not other.enchantments then
        return false
    end

    for _, enchantment in pairs(self.enchantments) do
        if not hasEnchantment(other, enchantment) then
            return false
        end
    end

    return true
end

local function matches(self, other)
    -- No need to check display name, tags and item groups, as
    -- the same id (name) will already uniquely identify the item type

    return nameMatches(self, other)
            and nbtMatches(self, other)
            and enchantmentsMatch(self, other)
end

--- @generic T
--- @param input T
--- @return T
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
Item.new = function(itemStack)
    return setmetatable(itemStack, {__index = Item, __eq = matches})
end
-- Functions --


-- Returning of API --
return Item
-- Returning of API --