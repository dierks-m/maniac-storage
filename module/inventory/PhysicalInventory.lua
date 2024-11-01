local util = require("util.util")
local ItemSet = require("util.ItemSet")

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


function PhysicalInventory:getItems()
    local result = ItemSet.new()

    for _, v in pairs(self.cache:getCacheData()) do
        result:add(v)
    end

    return result
end

function PhysicalInventory:pushItem(targetName, targetSlot, filter, amount)
    local totalTransferred = 0

    -- Remove items in reverse to first get rid of non-full stacks
    for slot, item in util.ipairsReverse(self.cache:getCacheData()) do
        if amount <= 0 then
            break
        end

        if filter:matches(item) then
            while amount > 0 and self.cache:getItemCount(slot) > 0 do
                local transferredAmount = self.inventory.pushItems(
                        targetName,
                        slot,
                        amount,
                        targetSlot
                )

                if transferredAmount <= 0 then
                    break
                end

                self.cache:remove(slot, transferredAmount)
                totalTransferred = totalTransferred + transferredAmount
                amount = amount - transferredAmount
            end
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