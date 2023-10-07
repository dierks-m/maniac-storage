local util = require("util.util")


--- Inventory class
--- @class PhysicalInventory : Inventory
--- @field inventory
--- @field filter Filter
--- @field cache ItemCache
--- @field sizeChecker SizeChecker
local PhysicalInventory = {}


--- @param self PhysicalInventory
--- @param item Item
local function acceptsItem(self, item)
    if not self.filter then
        return true
    end

    return self.filter:matches(item)
end

--- Adds an item to a list of items, increasing the count if the item
--- already exists in that list
--- @param list Item[]
--- @param item Item
local function addItemToList(list, item)
    for _, listItem in pairs(list) do
        if listItem == item then
            listItem.count = listItem.count + item.count
            return
        end
    end

    table.insert(list, item:clone())
    list[#list].maxCount = nil
end

--- Compiles a list of items from a list of stacks
--- @param inventory table<number, Item>
--- @return Item[]
local function compileItemList(inventory)
    local items = {}

    for _, slot in pairs(inventory) do
        addItemToList(items, slot)
    end

    return items
end

function PhysicalInventory:getItems()
    return compileItemList(self.cache:getCacheData())
end

function PhysicalInventory:pushItem(targetName, targetSlot, filter, amount)
    local totalTransferred = 0

    -- Remove items in reverse to first get rid of non-full stacks
    for slot, item in util.ipairsReverse(self.cache:getCacheData()) do
        if amount <= 0 then
            break
        end

        if filter:matches(item) then
            local transferredAmount = self.inventory.pushItems(
                    targetName,
                    slot,
                    amount,
                    targetSlot
            )

            self.cache:remove(slot, transferredAmount)
            totalTransferred = totalTransferred + transferredAmount
            amount = amount - transferredAmount
        end
    end

    return totalTransferred
end

function PhysicalInventory:pullItem(sourceName, sourceSlot, item, amount)
    if not acceptsItem(self, item) then
        return 0
    end

    if not self.sizeChecker:hasSpaceForItem(item) then
        return 0
    end

    local actualTransferred = self.inventory.pullItems(sourceName, sourceSlot, amount)
    self.cache:add(item, actualTransferred)

    return actualTransferred
end

function PhysicalInventory:setFilter(filter)
    self.filter = filter
end

--- @param inventoryName string
--- @param itemCache ItemCache
--- @param sizeChecker SizeChecker
--- @return PhysicalInventory
function PhysicalInventory.new(inventoryName, itemCache, sizeChecker)
    local inventory = {
        inventory = peripheral.wrap(inventoryName),
        cache = itemCache,
        sizeChecker = sizeChecker
    }

    return setmetatable(inventory, {__index = PhysicalInventory})
end


return PhysicalInventory