local Item = require("util.Item")

--- @class DefaultItemCache : ItemCache
--- @field inventory
--- @field itemCache table<number, Item>
local DefaultItemCache = {}


function DefaultItemCache:add()
    local newItemList = self.inventory.list()

    for slot, itemStack in pairs(newItemList) do
        if not self.itemCache[slot] then
            self.itemCache[slot] = Item.new(self.inventory.getItemDetail(slot))
        else
            self.itemCache[slot].count = itemStack.count
        end
    end
end

function DefaultItemCache:initialize()
    self.itemCache = {}
    DefaultItemCache.add(self)
end

function DefaultItemCache:remove(slot, count)
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

function DefaultItemCache:getCacheData()
    if not self.itemCache then
        self:initialize()
    end

    return self.itemCache
end

--- @param inventoryName string
--- @return DefaultItemCache
function DefaultItemCache.new(inventoryName)
    return setmetatable({ inventory = peripheral.wrap(inventoryName) }, { __index = DefaultItemCache })
end


return DefaultItemCache