-- Variables --
--- @class CompoundInventory
--- @field inventoryList table<number, Inventory[]>
local CompoundInventory = {}
-- Variables --


-- Functions --
--- @param itemList Item[]
--- @param itemFilter Filter
local function countItems(itemList, itemFilter)
    local count = 0

    for _, item in pairs(itemList) do
        if itemFilter:matches(item) then
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
            local currCount = countItems(v:getItems(), item)

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
--- @param item Filter
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
            local currCount = countItems(v:getItems(), item)

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
--- @param inventoryMap table<number, Inventory[]>
--- @return Item[]
local function compileItemList(inventoryMap)
    local items = {}

    for _, inventoryList in pairs(inventoryMap) do
        for _, inventory in pairs(inventoryList) do
            local inventoryItems = inventory:getItems()

            for _, item in pairs(inventoryItems) do
                addItemToList(items, item)
            end
        end
    end

    return items
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

    for _, inventoryList in pairs(self.inventoryList) do
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

    for _, inventoryList in pairs(self.inventoryList) do
        for _, inventory in itemAmountDesc(inventoryList) do
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

--- @return CompiledInventory
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