--- @class FilterList : Filter
--- @field filters Filter[]
--- @field isWhitelist boolean
local FilterList = {}

function FilterList:matches(item)
    for _, filter in pairs(self.filters) do
        if filter:matches(item) then
            return self.isWhitelist
        end
    end

    return not self.isWhitelist
end

--- @param isWhitelist boolean
function FilterList:setWhiteList(isWhitelist)
    self.isWhitelist = isWhitelist
end

--- @vararg Filter
--- @return FilterList
local function newList(...)
    local list = {filters={...}, isWhitelist=true}

    return setmetatable(list, {__index = FilterList})
end

return {
    new = newList
}