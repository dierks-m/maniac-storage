--- @class ItemStub
--- @field name string
--- @field count number
local ItemStub = {}


--- @param self ItemStub
--- @param other ItemStub
--- @return boolean
local function matches(self, other)
    return self.name == other.name
end


function ItemStub.new(itemStack)
    return setmetatable(itemStack, {__index = ItemStub, __eq = matches})
end


return ItemStub