--- @class ChestSizeChecker : SizeChecker
--- @field cache ItemCache
--- @field slotCount number
local ChestSizeChecker = {}


function ChestSizeChecker:hasSpaceForItem(item)
    local cacheItems = self.cache:getCacheData()

    for slot = 1, self.slotCount do
        if not cacheItems[slot] or cacheItems[slot] == item and cacheItems[slot].count < cacheItems[slot].maxCount then
            return true
        end
    end

    return false
end


--- @param itemCache ItemCache
--- @param slotCount number
--- @return ChestSizeChecker
function ChestSizeChecker.new(itemCache, slotCount)
    return setmetatable({ cache = itemCache, slotCount = slotCount }, { __index = ChestSizeChecker })
end


return ChestSizeChecker