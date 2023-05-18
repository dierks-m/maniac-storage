--- Provides an iterator for reversing a table with gaps in reverse
--- @param tbl table
local function ipairsReverse(tbl)
    local keys, n = {}, 0

    for key in pairs(tbl) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(a, b) return a > b end)

    return function()
        n = n + 1
        return keys[n], tbl[keys[n]]
    end
end

return {
    ipairsReverse = ipairsReverse
}