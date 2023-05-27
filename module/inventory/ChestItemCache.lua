local Item = require("util.item")

--- @class ChestItemCache : ItemCache
--- @field inventory
--- @field slotCount number
--- @field itemCache table<number, Item>
local ChestItemCache = {}


--- @param self ChestItemCacheNew
--- @param item Item
--- @param slot number
--- @param amount number
--- @return number The number of items inserted into that slot
local function addItemToSlot(self, item, slot, amount)
    if not self.itemCache[slot] then
        self.itemCache[slot] = item:clone()
        self.itemCache[slot].count = math.min(amount, item.maxCount)
        return self.itemCache[slot].count
    end

    if self.itemCache[slot] ~= item then
        return 0
    end

    local insertAmount = math.min(self.itemCache[slot].maxCount - self.itemCache[slot].count, amount)
    self.itemCache[slot].count = self.itemCache[slot].count + insertAmount
    return insertAmount
end

function ChestItemCache:initialize()
    self.itemCache = {}
    local items = self.inventory.list()

    for slot in pairs(items) do
        self.itemCache[slot] = Item.new(self.inventory.getItemDetail(slot))
    end
end

function ChestItemCache:add(item, amount)
    if not self.itemCache then
        self:initialize()
    end

    for slot = 1, self.slotCount do
        local insertAmount = addItemToSlot(self, item, slot, amount)
        amount = amount - insertAmount

        if amount <= 0 then
            break
        end
    end
end

function ChestItemCache:remove(slot, count)
    if not self.itemCache then
        self:initialize()
    end

    if not self.itemCache[slot] then
        return
    end

    if count >= self.itemCache[slot].count then
        self.itemCache[slot] = nil
        return
    end

    self.itemCache[slot].count = self.itemCache[slot].count - count
end

function ChestItemCache:getCacheData()
    if not self.itemCache then
        self:initialize()
    end

    return self.itemCache
end

--- @param inventoryName string
--- @return ChestItemCache
function ChestItemCache.new(inventoryName)
    local itemCache = {
        inventory = peripheral.wrap(inventoryName),
        slotCount = peripheral.call(inventoryName, "size")
    }

    return setmetatable(itemCache, {__index = ChestItemCache})
end


return ChestItemCache