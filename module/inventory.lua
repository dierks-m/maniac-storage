-- Variables --
local item = require("util.item")
local inventoryMT = {}
-- Variables --


-- Functions --
local function deleteEmptyStacks(self)
    for slot, item in pairs(self.cache) do
        if item.count == 0 then
            self.cache[slot] = nil
        end
    end
end

function inventoryMT:read()
    local list = self.inventory.list()
    self.cache = {}

    for k in pairs(list) do
        self.cache[k] = item.new(self.inventory.getItemDetail(k))
    end

    return self.cache
end

function inventoryMT:pushItem(targetName, targetSlot, filter, amount)
    if not self.cache then self:read() end

    local totalTransferred = 0

    for slot, item in pairs(self.cache) do
        if amount == 0 then
            break
        end

        if item:matches(filter) then
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

local function newInventory(name)
    local inventory = {
        inventory = peripheral.wrap(name)
    }

    return setmetatable(inventory, {__index = inventoryMT})
end
-- Functions --

return {
    new = newInventory
}