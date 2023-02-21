local function getLargestIndex(tbl)
    local currIndex, lastIndex

    repeat
        if type(currIndex) == "number" then
            if lastIndex and lastIndex < currIndex then
                lastIndex = currIndex
            elseif not lastIndex then
                lastIndex = currIndex
            end
        end

        currIndex = next(tbl, currIndex)
    until not currIndex

    return lastIndex
end

--- Provides an iterator for reversing a table with gaps in reverse
--- @param tbl table
local function ipairsReverse(tbl)
    local lastIndex = getLargestIndex(tbl) or 0

    return function(t, key)
        if not key then
            key = lastIndex
        else
            key = key - 1
        end

        for i = key, 1, -1 do
            if t[i] then
                return i, t[i]
            end
        end

        return nil
    end, tbl, nil
end

return {
    ipairsReverse = ipairsReverse
}