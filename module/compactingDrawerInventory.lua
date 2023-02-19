-- Variables --
local item = require("util.item")

--- Inventory class
--- @class CompactingDrawerInventory : Inventory
--- @field inventory
--- @field filter Filter
--- @field cache Item[]
local CompactingDrawerInventory = {}

local validInventoryTypes = {
    ["storagedrawers:fractional_drawers_3"] = true
}
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

--- @param self CompactingDrawerInventory
local function readInventory(self)
    local list = self.inventory.list()
    self.cache = {}

    for k in pairs(list) do
        self.cache[k] = item.new(self.inventory.getItemDetail(k))
    end

    return self.cache
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

local function updateAllSlotCounts(self)
    local list = self.inventory.list()

    for k, v in pairs(list) do
        self.cache[k].count = v.count
    end
end

local function acceptsItem(self, item)
    if not self.filter then
        return true
    end

    return self.filter:matches(item)
end

function CompactingDrawerInventory:pushItem(targetName, targetSlot, filter, amount)
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

            updateAllSlotCounts(self)
        end
    end

    deleteEmptyStacks(self)

    return totalTransferred
end

function CompactingDrawerInventory:pullItem(sourceName, sourceSlot, item, amount)
    if not acceptsItem(self, item) then
        return 0
    end

    if not self.cache then readInventory(self) end

    local actualTransferred = self.inventory.pullItems(sourceName, sourceSlot, amount)
    updateAllSlotCounts(self)

    return actualTransferred
end

function CompactingDrawerInventory:getItems()
    if not self.cache then
        return readInventory(self)
    end

    return compileItemList(self.cache)
end

function CompactingDrawerInventory:setFilter(filter)
    self.filter = filter
end

function CompactingDrawerInventory:setLimitCheck()
end

--- @return CompactingDrawerInventory
local function newInventory(name)
    if not validInventoryTypes[peripheral.getType(name)] then
        error("U stoopid, no valid compating drawer!")
    end

    local inventory = {
        inventory = peripheral.wrap(name)
    }

    return setmetatable(inventory, {__index = CompactingDrawerInventory})
end
-- Functions --

return {
    new = newInventory
}