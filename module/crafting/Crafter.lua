-- This is just the interface definition for a crafter

--- @class Crafter
local Crafter = {}

--- @param itemFilter Filter
--- @param count number
--- @return number The amount of items crafted
function Crafter:craft(itemFilter, count) end

--- Get a list of all craftable items
--- @return Set<Item>
function Crafter:getCraftableItems() end