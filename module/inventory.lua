local item = require("util.item")

--- Inventory class
--- @class Inventory
local Inventory = {}

--- Push an item that matches a filter to a given inventory and target slot
--- @param targetName string
--- @param targetSlot number
--- @param filter Filter
--- @param amount number
--- @return number
function Inventory:pushItem(targetName, targetSlot, filter, amount) end

--- Pulls an item if this inventory accepts that item and returns the amount actually pulled.
--- @param sourceName string
--- @param sourceSlot number
--- @param item Item
--- @param amount number
--- @return number
function Inventory:pullItem(sourceName, sourceSlot, item, amount) end

--- @return Item[]
function Inventory:getItems() end

--- @param filter Filter
function Inventory:setFilter(filter) end