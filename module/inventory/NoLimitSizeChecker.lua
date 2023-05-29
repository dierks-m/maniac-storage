--- @class NoLimitSizeChecker : SizeChecker
local NoLimitSizeChecker = {}


function NoLimitSizeChecker:hasSpaceForItem()
    return true
end

--- @return NoLimitSizeChecker
function NoLimitSizeChecker.new()
    return setmetatable({}, {__index = NoLimitSizeChecker})
end


return NoLimitSizeChecker