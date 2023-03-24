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
function Set:unite(other)
    for _, value in pairs(other:toList()) do
        self:add(value)
    end
end

--- @return Set<T>
function Set.new()
    return setmetatable({ values = {} }, { __index = Set })
end

return Set