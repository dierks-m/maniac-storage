-- Variables --
local item = require("util.item")

--- Inventory class
--- @class Inventory
--- @field inventory
--- @field cache Item[]
local Inventory = {}
-- Variables --


-- Functions --
--- Deletes stacks with zero-count
--- @param self Inventory
local function deleteEmptyStacks(self)
    for slot, item in pairs(self.cache) do
        if item.count == 0 then
            self.cache[slot] = nil
        end
    end
end

function Inventory:read()
    local list = self.inventory.list()
    self.cache = {}

    for k in ipairs(list) do
        self.cache[k] = item.new(self.inventory.getItemDetail(k))
    end

    return self.cache
end

--- Push an item that matches a filter to a given inventory and target slot
--- @param targetName string
--- @param targetSlot number
--- @param filter Filter
--- @param amount number
function Inventory:pushItem(targetName, targetSlot, filter, amount)
    if not self.cache then self:read() end

    local totalTransferred = 0

    for slot, item in pairs(self.cache) do
        if amount == 0 then
            break
        end

        if filter:matches(item) then
            local transferredAmount = self.inventory.pushItems(
                    targetName,
                    slot,
                    amount,
                    targetSlot
            )

            totalTransferred = totalTransferred + transferredAmount
            amount = amount - transferredAmount

            item.count = item.count - transferredAmount
        end
    end

    deleteEmptyStacks(self)

    return totalTransferred
end

--- Adds an item to a list of items, increasing the count if the item
--- already exists in that list
--- @param list Item[]
--- @param item Item
local function addItemToList(list, item)
    for _, listItem in pairs(list) do
        if listItem:matches(item) then
            listItem.count = listItem.count + item.count
            return
        end
    end

    table.insert(list, item:clone())
    list[#list].maxCount = nil
end

--- Compiles a list of items from a list of stacks
--- @param inventory Item[]
--- @return Item[]
local function compileItemList(inventory)
    local items = {}

    for _, slot in pairs(inventory) do
        addItemToList(items, slot)
    end

    return items
end

--- @return Inventory
local function newInventory(name)
    local inventory = {
        inventory = peripheral.wrap(name)
    }

    return setmetatable(inventory, {__index = Inventory})
end
-- Functions --

return {
    new = newInventory,
    compileItemList = compileItemList
}