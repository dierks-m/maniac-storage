-- Variables --
local Item = require("util.item")
local util = require("util.util")

--- Inventory class
--- @class PhysicalInventory : Inventory
--- @field inventory
--- @field slotCount number
--- @field limitCheck boolean
--- @field filter Filter
--- @field cache Item[]
local PhysicalInventory = {}
-- Variables --


-- Functions --
--- @param self PhysicalInventory
--- @param item Item
local function acceptsItem(self, item)
    if not self.filter then
        return true
    end

    return self.filter:matches(item)
end

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
        self.cache[k] = Item.new(self.inventory.getItemDetail(k))
    end

    return self.cache
end

local function updateCache(self)
    local itemList = self.inventory.list()

    for slot, itemStack in pairs(itemList) do
        if not self.cache[slot] then
            self.cache[slot] = Item.new(self.inventory.getItemDetail(slot))
        else
            self.cache[slot].count = itemStack.count
        end
    end
end

--- @param self PhysicalInventory
--- @param item Item
local function itemFits(self, item)
    if not self.limitCheck or #self.cache < self.slotCount then
        return true
    end

    for _, slotContent in pairs(self.cache) do
        if slotContent:matches(item) and slotContent.count < slotContent.maxCount then
            return true
        end
    end

    return false
end

function PhysicalInventory:getItems()
    if not self.cache then
        return readInventory(self)
    end

    return compileItemList(self.cache)
end

function PhysicalInventory:pushItem(targetName, targetSlot, filter, amount)
    if not self.cache then
        readInventory(self)
    end

    local totalTransferred = 0

    -- Remove items in reverse to first get rid of non-full stacks
    for slot, item in util.ipairsReverse(self.cache) do
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

function PhysicalInventory:pullItem(sourceName, sourceSlot, item, amount)
    if not acceptsItem(self, item) then
        return 0
    end

    if not self.cache then readInventory(self) end

    if not itemFits(self, item) then
        return 0
    end

    local actualTransferred = self.inventory.pullItems(sourceName, sourceSlot, amount)
    updateCache(self)

    return actualTransferred
end

function PhysicalInventory:setFilter(filter)
    self.filter = filter
end

function PhysicalInventory:setLimitCheck(value)
    self.limitCheck = value
end

--- @return PhysicalInventory
local function newInventory(name)
    local inventory = {
        inventory = peripheral.wrap(name),
        limitCheck = true
    }

    inventory.slotCount = inventory.inventory.size()

    return setmetatable(inventory, {__index = PhysicalInventory })
end
-- Functions --

return {
    new = newInventory
}