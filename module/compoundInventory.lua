-- Variables --
--- @class PrioritizedInventory
--- @field inventory Inventory
--- @field priority number
local PrioritizedInventory

--- @class CompoundInventory
--- @field inventoryList PrioritizedInventory[]
local CompoundInventory = {}
-- Variables --


-- Functions --
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
--- @param inventories PrioritizedInventory[]
--- @return Item[]
local function compileItemList(inventories)
    local items = {}

    for _, inventory in pairs(inventories) do
        local inventoryItems = inventory.inventory:getItems()

        for _, item in pairs(inventoryItems) do
            addItemToList(items, item)
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

    for _, inventory in pairs(self.inventoryList) do
        if amount - totalTransferred <= 0 then
            return totalTransferred
        end

        local transferredItems = inventory.inventory:pushItem(targetName, targetSlot, filter, math.min(amount, amount-totalTransferred))
        totalTransferred = totalTransferred + transferredItems
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

    for _, inventory in pairs(self.inventoryList) do
        if amount - totalTransferred <= 0 then
            return totalTransferred
        end

        local transferredItems = inventory.inventory:pullItem(sourceName, sourceSlot, item, math.min(amount, amount-totalTransferred))
        totalTransferred = totalTransferred + transferredItems
    end

    return totalTransferred
end

--- @param inventory Inventory
--- @param priority number
function CompoundInventory:addInventory(inventory, priority)
    local position = 1

    for k, invMap in ipairs(self.inventoryList) do
        if invMap.priority > priority then
            position = k + 1
        else
            break
        end
    end

    table.insert(self.inventoryList, position, {inventory=inventory, priority=priority})
end

--- @param inventories Inventory[]
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