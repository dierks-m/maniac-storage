local ItemFilter = require("util.itemFilter")
local FilterList = require("util.filterList")

--- @class DynamicWhiteList : Filter
--- @field filterList FilterList
--- @field inventory Inventory
local DynamicWhiteList = {}

--- @param self DynamicWhiteList
local function assertInitialization(self)
    if not self.filterList then
        local containedItems = self.inventory:getItems()
        local filters = {}

        for _, item in containedItems:iterator() do
            filters[#filters + 1] = ItemFilter.new(item)
        end

        self.filterList = FilterList.new(table.unpack(filters))
    end
end

function DynamicWhiteList:matches(item)
    assertInitialization(self)
    return self.filterList:matches(item)
end

--- @param inventory Inventory
--- @return DynamicWhiteList
DynamicWhiteList.new = function(inventory)
    return setmetatable({inventory=inventory}, {__index = DynamicWhiteList})
end

return DynamicWhiteList