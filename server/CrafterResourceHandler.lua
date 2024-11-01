--- @class ReservableCrafter : Crafter
--- @field crafter Crafter
--- @field busy boolean
local ReservableCrafter = {}

function ReservableCrafter:craft(itemFilter, count)
    self.busy = true
    local _, result = pcall(self.crafter.craft, self.crafter, itemFilter, count)
    self.busy = false

    return result
end

function ReservableCrafter:getCraftableItems()
    return self.crafter:getCraftableItems()
end

function ReservableCrafter:isBusy()
    return self.busy
end

--- @param crafter Crafter
--- @return ReservableCrafter
function ReservableCrafter.new(crafter)
    return setmetatable({crafter = crafter, busy = false}, {__index = ReservableCrafter})
end

--- @class CrafterResourceHandler
--- Manages all available crafters and their busyness status.
--- If a craft is initiated for a crafter, this crafter is busy for the duration of the craft
--- and cannot be used until it is done crafting.
--- This way, a crafter also cannot call itself to craft a dependent recipe.
--- @field crafters ReservableCrafter[]
local CrafterResourceHandler = {}


--- @param crafter Crafter
--- @param itemFilter Filter
--- @return boolean
local function hasRecipeFor(crafter, itemFilter)
    local items = crafter:getCraftableItems():toList()

    for _, item in pairs(items) do
        if itemFilter:matches(item) then
            return true
        end
    end

    return false
end

--- @param itemFilter Filter
--- @return Crafter|nil
function CrafterResourceHandler:getCrafter(itemFilter)
    for _, crafter in pairs(self.crafters) do
        if not crafter:isBusy() and hasRecipeFor(crafter, itemFilter) then
            return crafter
        end
    end

    return nil
end

function CrafterResourceHandler:getCrafters()
    return self.crafters
end

--- @param crafter Crafter
function CrafterResourceHandler:addCrafter(crafter)
    self.crafters[#self.crafters + 1] = ReservableCrafter.new(crafter)
end

--- @param crafters Crafter[]
function CrafterResourceHandler.new(crafters)
    --- @type CrafterResourceHandler
    local crafterResourceHandler = setmetatable({ crafters = {}}, { __index = CrafterResourceHandler})

    for _, crafter in pairs(crafters) do
        crafterResourceHandler:addCrafter(crafter)
    end

    return crafterResourceHandler
end


return CrafterResourceHandler