--- @class DrawerSizeChecker : SizeChecker
--- @field slotSizes table<number, number>
--- @field cache ItemCache
local DrawerSizeChecker = {}


function DrawerSizeChecker:hasSpaceForItem(item)
    local cacheItems = self.cache:getCacheData()

    -- First slot always seems to be some sort of dummy input slot with size INT_MAX
    for slot = 2, #self.slotSizes do
        if not cacheItems[slot] or cacheItems[slot] == item and cacheItems[slot].count < self.slotSizes[slot] then
            return true
        end
    end

    return false
end

--- @param cache ItemCache
--- @param inventoryName string
--- @return DrawerSizeChecker
function DrawerSizeChecker.new(cache, inventoryName)
    local slotCount = peripheral.call(inventoryName, "size")
    local slotSizes = {}

    for i = 1, slotCount do
        slotSizes[i] = peripheral.call(inventoryName, "getItemLimit", i)
    end

    return setmetatable({slotSizes = slotSizes, cache = cache}, {__index = DrawerSizeChecker})
end


return DrawerSizeChecker