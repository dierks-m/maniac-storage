--- @class ItemCache
local ItemCache = {}

function ItemCache:initialize() end

--- @param item Item
--- @param amount number
function ItemCache:add(item, amount) end

--- @param slot number
--- @param count number
function ItemCache:remove(slot, count) end

--- @param slot number
--- @return number
function ItemCache:getItemCount(slot) end

--- @return table<number, Item>
function ItemCache:getCacheData() end