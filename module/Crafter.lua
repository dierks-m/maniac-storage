local Item = require("util.item")

--- @class Crafter
--- @field recipeStore CraftingRecipeStore
--- @field itemSystem ItemServerConnector
local Crafter = {}
local craftInternal

--- @param self Crafter
local function storeItems(self)
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            local itemDetail = turtle.getItemDetail(i)
            self.itemSystem:insert(i, Item.new(itemDetail), turtle.getItemCount(i))
        end
    end
end

--- @param item Item
local function getResultCount(item)
    local itemCount = 0

    for i = 1, 16 do
        local slot = turtle.getItemDetail(i)

        if slot and item:matches(slot) then
            itemCount = itemCount + turtle.getItemCount(i)
        end
    end

    return itemCount
end

--- @param self Crafter
--- @param items table<number, ItemFilter>
--- @param count number
--- @param attemptedRecipes CraftingRecipe[]
local function retrieveItems(self, items, count, attemptedRecipes)
    local allItemsInserted

    repeat
        allItemsInserted = true

        for slot, item in pairs(items) do
            local mappedSlot = slot + math.floor((slot - 1) / 3) -- Map 3x3 to 4x4 grid
            local extractedCount = self.itemSystem:extract(mappedSlot, item, count)

            if extractedCount == 0 then
                storeItems(self) -- Cleanup before crafting dependency

                if craftInternal(self, item, count, {table.unpack(attemptedRecipes)}) == 0 then
                    return false
                end

                allItemsInserted = false
                break
            end
        end
    until allItemsInserted

    return true
end

--- @param self Crafter
--- @param recipe CraftingRecipe
--- @param amount number
--- @param attemptedRecipes CraftingRecipe[]
--- @return number The number of items crafted
local function craftRecipe(self, recipe, amount, attemptedRecipes)
    local craftedAmount = 0

    while craftedAmount < amount do
        local craftAmount = math.ceil((amount - craftedAmount) / recipe.guaranteedOutput.count)

        if not retrieveItems(self, recipe.input, craftAmount, attemptedRecipes) then
            break
        end

        turtle.craft()
        craftedAmount = craftedAmount + getResultCount(recipe.guaranteedOutput)
        storeItems(self)
    end

    return craftedAmount
end

--- Internal function that keeps track of attempted recipes
--- to prevent infinite recursion.
--- E.g. a piston could be made the vanilla way or by making a sticky piston non-sticky.
--- However, the sticky piston would be made by a piston and a slime ball - recursively calling the
--- piston recipe.
--- @param self Crafter
--- @param itemFilter Filter
--- @param amount number
--- @param attemptedRecipes CraftingRecipe[]
--- @return number
craftInternal = function(self, itemFilter, amount, attemptedRecipes)
    local recipes = self.recipeStore:getRecipes(itemFilter)

    -- Remove those recipes that were already attempted to craft
    for _, attemptedRecipe in pairs(attemptedRecipes) do
        for key, recipe in pairs(recipes) do
            if recipe == attemptedRecipe then
                recipes[key] = nil
                break
            end
        end
    end

    local craftedAmount = 0

    for _, recipe in ipairs(recipes) do
        attemptedRecipes[#attemptedRecipes + 1] = recipe
        craftedAmount = craftedAmount + craftRecipe(self, recipe, amount - craftedAmount, attemptedRecipes)

        if craftedAmount >= amount then
            break
        end
    end

    return craftedAmount
end

--- @param itemFilter Filter
--- @param amount number
--- @return number The number of actually crafted items
function Crafter:craft(itemFilter, amount)
    return craftInternal(self, itemFilter, amount, {})
end

--- @return Crafter
function Crafter.new(recipeStore, itemSystem)
    local crafter = {
        recipeStore=recipeStore,
        itemSystem=itemSystem
    }

    return setmetatable(crafter, {__index = Crafter})
end


return Crafter