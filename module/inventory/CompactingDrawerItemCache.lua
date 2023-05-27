local Item = require("util.item")

--- @class CompactingDrawerItemCache : ItemCache
--- @field inventory
--- @field itemCache table<number, Item>
local CompactingDrawerItemCache = {}


--- @param self CompactingDrawerItemCache
local function updateChangedSlots(self)
    local newItemList = self.inventory.list()

    for slot, itemStack in pairs(newItemList) do
        if not self.itemCache[slot] then
            self.itemCache[slot] = Item.new(self.inventory.getItemDetail(slot))
        else
            self.itemCache[slot].count = itemStack.count
        end
    end
end

function CompactingDrawerItemCache:initialize()
    self.itemCache = {}
    updateChangedSlots(self)
end

function CompactingDrawerItemCache:add()
    if not self.itemCache then
        self:initialize()
        return
    end

    updateChangedSlots(self)
end

function CompactingDrawerItemCache:remove()
    if not self.itemCache then
        self:initialize()
    end

    updateChangedSlots(self)
end

function CompactingDrawerItemCache:getCacheData()
    if not self.itemCache then
        self:initialize()
    end

    return self.itemCache
end

--- @param inventoryName string
--- @return DefaultItemCache
function CompactingDrawerItemCache.new(inventoryName)
    return setmetatable({ inventory = peripheral.wrap(inventoryName) }, { __index = CompactingDrawerItemCache })
end


return CompactingDrawerItemCache