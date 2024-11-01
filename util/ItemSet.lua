--- @class ItemSet
--- @field items Item[]
local ItemSet = {}


--- Adds a copy of the given item or, if it is already contained, increases its count by `item.count`
--- @param item Item
function ItemSet:add(item)
    for _, v in pairs(self.items) do
        if v == item then
            v.count = v.count + item.count
            return
        end
    end

    self.items[#self.items + 1] = item:clone()
end

--- @param item Item
--- @return Item
function ItemSet:remove(item)
    for k, v in pairs(self.items) do
        if v == item then
            if v.count <= item.count then
                self.items[k] = nil
                return v
            end

            v.count = v.count - item.count
            return item:clone()
        end
    end

    return item:clone():withCount(0)
end

--- @param item Item
--- @return boolean
function ItemSet:contains(item)
    for _, v in pairs(self.items) do
        if v == item then
            return true
        end
    end

    return false
end

--- @param filter Filter
--- @return ItemSet
function ItemSet:getMatchingItems(filter)
    local result = ItemSet.new()

    for _, item in pairs(self.items) do
        if filter:matches(item) then
            result:add(item)
        end
    end

    return result
end

--- @param other ItemSet
--- @return ItemSet
function ItemSet:unite(other)
    for _, item in pairs(other.items) do
        self:add(item)
    end

    return self
end

--- @return number The amount of item stacks contained in this `ItemSet`
function ItemSet:size()
    local count = 0

    for _ in pairs(self.items) do
        count = count + 1
    end

    return count
end

function ItemSet:iterator()
    return pairs(self.items)
end

function ItemSet:clone()
    local clone = ItemSet.new()

    for _, item in pairs(self.items) do
        clone:add(item)
    end
end

--- @param items Item[]
function ItemSet.new(items)
    assert(items == nil or type(items) == "table", "Items must be given in table form")

    local itemCopies = {}

    if items then
        for _, item in pairs(items) do
            itemCopies[#itemCopies + 1] = item:clone()
        end
    end

    return setmetatable({items = itemCopies}, {__index = ItemSet})
end

return ItemSet