--- @class SizeChecker
local SizeChecker = {}

--- Checks whether or not an item may fit in this inventory.
--- This is only an initial check to circumvent trying to push an item, which requires one tick of time.
--- This function may return false positives (i.e. return true even if the item does not actually fit)
--- @param item Item
--- @return boolean
function SizeChecker:hasSpaceForItem(item) end