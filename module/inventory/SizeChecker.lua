--- @class SizeChecker
local SizeChecker = {}

--- Checks whether or not an item may fit in this inventory.
--- This is only an initial check to circumvent trying to push an item, requiring one tick of time
--- and may return false positives.
--- @param item Item
--- @return boolean
function SizeChecker:hasSpaceForItem(item) end