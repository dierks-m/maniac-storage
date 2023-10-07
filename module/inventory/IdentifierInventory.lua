local Item = require("util.Item")

--- @class IdentifierInventory
--- @field inventory
--- @field inventorySize number
--- @field inventoryName string
local IdentifierInventory = {}


--- @param sourceName string
--- @param sourceSlot number
--- @param amount number
--- @return Item, number Item and slot of identified item
function IdentifierInventory:identifyItem(sourceName, sourceSlot, amount)
    local occupiedSlots = self.inventory.list()
    local targetSlot

    for i = 1, self.inventorySize do
        if not occupiedSlots[i] then
            targetSlot = i
            break
        end
    end

    print("Target slot is " .. targetSlot)

    if not targetSlot then
        error("No available slot for item identification")
    end

    print("Trying to identify " .. sourceName .. "[" .. sourceSlot .. "] in slot " .. targetSlot)
    self.inventory.pullItems(sourceName, sourceSlot, amount, targetSlot)

    return Item.new(self.inventory.getItemDetail(targetSlot)), targetSlot
end


--- @param inventoryName string
--- @return IdentifierInventory
function IdentifierInventory.new(inventoryName)
    local inventory = {
        inventory = peripheral.wrap(inventoryName),
        inventorySize = peripheral.call(inventoryName, "size"),
        inventoryName = inventoryName
    }

    return setmetatable(inventory, {__index = IdentifierInventory})
end


return IdentifierInventory