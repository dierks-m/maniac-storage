-- Variables --
--- @class CompiledInventory
--- @field inventoryList Inventory[]
local CompiledInventory = {}
-- Variables --


-- Functions --
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
--- @param inventories Inventory[]
--- @return Item[]
local function compileItemList(inventories)
    local items = {}

    for _, inventory in pairs(inventories) do
        local inventoryItems = inventory:getItems()

        for _, item in pairs(inventoryItems) do
            addItemToList(items, item)
        end
    end

    return items
end

function CompiledInventory:getItems()
    return compileItemList(self.inventoryList)
end

--- Push an item that matches a filter to a given inventory and target slot
--- @param targetName string
--- @param targetSlot number
--- @param filter Filter
--- @param amount number
function CompiledInventory:pushItem(targetName, targetSlot, filter, amount)
    local totalTransferred = 0

    for _, inventory in pairs(self.inventoryList) do
        if amount - totalTransferred <= 0 then
            return totalTransferred
        end

        local transferredItems = inventory:pushItem(targetName, targetSlot, filter, math.min(amount, amount-totalTransferred))
        totalTransferred = totalTransferred + transferredItems
    end
end

--- @param inventories Inventory[]
--- @return CompiledInventory
local function newCompiledInventory(inventories)
    local compiledInventory = {
        inventoryList = inventories
    }

    return setmetatable(compiledInventory, {_index = CompiledInventory})
end
-- Functions --

return {
    new = newCompiledInventory
}