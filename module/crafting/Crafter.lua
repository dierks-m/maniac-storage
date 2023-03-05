-- This is just the interface definition for a crafter

--- @class Crafter
local Crafter = {}

--- @param itemFilter Filter
--- @param count number
--- @return number The amount of items crafted
function Crafter:craft(itemFilter, count) end

--- @return Item[]
function Crafter:getCraftableItems() end