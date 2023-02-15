-- Variables --
local item = require("util.item")

--- Inventory class
--- @class PhysicalInventory : Inventory
--- @field inventory
--- @field cache Item[]
local PhysicalInventory = {}
-- Variables --


-- Functions --
--- Deletes stacks with zero-count
--- @param self PhysicalInventory
local function deleteEmptyStacks(self)
    for slot, item in pairs(self.cache) do
        if item.count == 0 then
            self.cache[slot] = nil
        end
    end
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

--- @param self PhysicalInventory
local function readInventory(self)
    local list = self.inventory.list()
    self.cache = {}

    for k in pairs(list) do
        self.cache[k] = item.new(self.inventory.getItemDetail(k))
    end

    return self.cache
end

function PhysicalInventory:getItems()
    if not self.cache then
        return readInventory(self)
    end

    return compileItemList(self.cache)
end

function PhysicalInventory:pushItem(targetName, targetSlot, filter, amount)
    if not self.cache then readInventory(self) end

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

--- @return PhysicalInventory
local function newInventory(name)
    local inventory = {
        inventory = peripheral.wrap(name)
    }

    return setmetatable(inventory, {__index = PhysicalInventory })
end
-- Functions --

return {
    new = newInventory
}