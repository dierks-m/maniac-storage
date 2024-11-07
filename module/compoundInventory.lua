-- Variables --
local util = require("util.util")
local ItemSet = require("util.ItemSet")

--- @class CompoundInventory
--- @field inventoryList table<number, Inventory[]>
local CompoundInventory = {}
-- Variables --


-- Functions --
--- @param itemList Item[]
--- @param itemFilter Filter
local function countByFilter(itemList, itemFilter)
    local count = 0

    for _, item in pairs(itemList) do
        if itemFilter:matches(item) then
            count = count + item.count
        end
    end

    return count
end

--- @param itemList Item[]
--- @param itemFilter Item
local function countByItem(itemList, itemFilter)
    local count = 0

    for _, item in pairs(itemList) do
        if itemFilter == item then
            count = count + item.count
        end
    end

    return count
end

--- @param inventoryList Inventory[]
--- @param item Filter
local function itemAmountAsc(inventoryList, item)
    local iteratedKeys = {}

    --- @param tbl Inventory[]
    --- @param key number
    return function(tbl, key)
        if key then
            iteratedKeys[key] = true
        end

        local minKey, minValue, minCount
        for k, v in pairs(tbl) do
            local currCount = countByFilter(v:getItems(), item)

            if (not (minKey or minValue) or currCount < minCount) and not iteratedKeys[k] then
                minKey, minValue, minCount = k, v, currCount
            end
        end

        if minKey then
            return minKey, minValue
        end

        return nil
    end, inventoryList, nil
end

--- @param inventoryList Inventory[]
--- @param item Item
local function itemAmountDesc(inventoryList, item)
    local iteratedKeys = {}

    --- @param tbl Inventory[]
    --- @param key number
    return function(tbl, key)
        if key then
            iteratedKeys[key] = true
        end

        local maxKey, maxValue, maxCount
        for k, v in pairs(tbl) do
            local currCount = countByItem(v:getItems(), item)

            if (not (maxKey or maxValue) or currCount > maxCount) and not iteratedKeys[k] then
                maxKey, maxValue, maxCount = k, v, currCount
            end
        end

        if maxKey then
            return maxKey, maxValue
        end

        return nil
    end, inventoryList, nil
end

--- Compiles a list of items from a list of stacks
--- @param inventoryMap table<number, Inventory[]>
--- @return Item[]
local function compileItemList(inventoryMap)
    local result = ItemSet.new()
    local getItemFunctions = {}

    for _, inventoryList in pairs(inventoryMap) do
        for _, inventory in pairs(inventoryList) do
            table.insert(
                    getItemFunctions,
                    function()
                        result:unite(inventory:getItems())
                    end
            )
        end
    end

    parallel.waitForAll(table.unpack(getItemFunctions))

    return result
end

function CompoundInventory:getItems()
    return compileItemList(self.inventoryList)
end

--- Push an item that matches a filter to a given inventory and target slot
--- @param targetName string
--- @param targetSlot number
--- @param filter Filter
--- @param amount number
function CompoundInventory:extract(targetName, targetSlot, filter, amount)
    local totalTransferred = 0

    for _, inventoryList in util.ipairsGapped(self.inventoryList) do
        for _, inventory in itemAmountAsc(inventoryList, filter) do
            if amount - totalTransferred <= 0 then
                return totalTransferred
            end

            local transferredItems = inventory:pushItem(targetName, targetSlot, filter, math.min(amount, amount-totalTransferred))
            totalTransferred = totalTransferred + transferredItems
        end
    end

    return totalTransferred
end

--- Pulls an item if any of the inventories accepts that item and returns the amount actually pulled.
--- @param sourceName string
--- @param sourceSlot number
--- @param item Item
--- @param amount number
--- @return number
function CompoundInventory:insert(sourceName, sourceSlot, item, amount)
    local totalTransferred = 0

    for _, inventoryList in util.ipairsReverse(self.inventoryList) do
        for _, inventory in itemAmountDesc(inventoryList, item) do
            if amount - totalTransferred <= 0 then
                return totalTransferred
            end

            local transferredItems = inventory:pullItem(sourceName, sourceSlot, item, math.min(amount, amount-totalTransferred))
            totalTransferred = totalTransferred + transferredItems
        end
    end

    return totalTransferred
end

--- @param inventory Inventory
--- @param priority number
function CompoundInventory:addInventory(inventory, priority)
    if not self.inventoryList[priority] then
        self.inventoryList[priority] = {}
    end

    table.insert(self.inventoryList[priority], inventory)
end

--- @return CompoundInventory
local function newCompiledInventory()
    local compiledInventory = {
        inventoryList = {}
    }

    return setmetatable(compiledInventory, {__index = CompoundInventory })
end
-- Functions --

return {
    new = newCompiledInventory
}