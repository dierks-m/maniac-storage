local item = require("util.item")

--- Inventory class
--- @class Inventory
--- @field inventory
--- @field cache Item[]
local Inventory = {}

--- Push an item that matches a filter to a given inventory and target slot
--- @param targetName string
--- @param targetSlot number
--- @param filter Filter
--- @param amount number
--- @return number
function Inventory:pushItem(targetName, targetSlot, filter, amount) end

--- @return Item[]
function Inventory:getItems() end