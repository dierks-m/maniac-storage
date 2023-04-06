-- TODO: How to document generics with a class?
--- @class Set<T>
--- @field values T[]
local Set = {}

local function contains(self, value)
    for _, v in pairs(self.values) do
        -- For tables, this requires the __eq metamethod
        if value == v then
            return true
        end
    end

    return false
end

--- @param value T
function Set:add(value)
    if not contains(self, value) then
        self.values[#self.values + 1] = value
    end
end

--- @return T[]
function Set:toList()
    return self.values
end

--- @param other Set<T>
--- @return Set<T>
function Set:unite(other)
    local newSet = Set.new()

    for _, value in pairs(other:toList()) do
        newSet:add(value)
    end

    for _, value in pairs(self:toList()) do
        newSet:add(value)
    end

    return newSet
end

--- @param other Set<T>
--- @return Set<T>
function Set:intersect(other)
    local newSet = Set.new()

    for _, value in pairs(other:toList()) do
        if contains(self, value) then
            newSet:add(value)
        end
    end

    return newSet
end

--- @generic T
--- @param other Set<T>
--- @return Set<T> All elements that are not contained in other
function Set:difference(other)
    local newSet = Set.new()

    for _,value in pairs(self:toList()) do
        if not contains(other, value) then
            newSet:add(value)
        end
    end

    return newSet
end

--- @generic T
--- @return Set<T>
function Set:clone()
    local newSet = Set.new()

    for _, value in pairs(self:toList()) do
        newSet:add(value)
    end

    return newSet
end

--- @generic T
--- @vararg T
--- @return Set<T>
function Set.new(...)
    return setmetatable({ values = {...} }, { __index = Set })
end

return Set