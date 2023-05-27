local Set = require("util.Set")
local Item = require("util.Item")

--- @class TableCrafter : Crafter
--- @field recipeStore CraftingRecipeStore
--- @field itemSystem ItemServerConnector
local TableCrafter = {}
local craftInternal

--- @param self TableCrafter
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

        if slot and item == Item.new(slot) then
            itemCount = itemCount + turtle.getItemCount(i)
        end
    end

    return itemCount
end

--- @param self TableCrafter
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

                if craftInternal(self, item, count, {table.unpack(attemptedRecipes)}) == 0 and self.itemSystem:craft(item, count) == 0 then
                    return false
                end

                allItemsInserted = false
                break
            end
        end
    until allItemsInserted

    return true
end

--- @param self TableCrafter
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
--- @param self TableCrafter
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
    local craftedThisRound

    for _, recipe in ipairs(recipes) do
        attemptedRecipes[#attemptedRecipes + 1] = recipe
        craftedThisRound = craftRecipe(self, recipe, amount - craftedAmount, attemptedRecipes)
        craftedAmount = craftedAmount + craftedThisRound

        if craftedAmount >= amount or craftedThisRound == 0 then
            break
        end
    end

    return craftedAmount
end

--- @param itemFilter Filter
--- @param amount number
--- @return number The number of actually crafted items
function TableCrafter:craft(itemFilter, amount)
    return craftInternal(self, itemFilter, amount, {})
end

--- @return Set<Item>
function TableCrafter:getCraftableItems()
    local recipes = self.recipeStore:getRecipes(nil)
    --- @type Set<Item>
    local craftableItems = Set.new()

    for _, recipe in pairs(recipes) do
        craftableItems:add(recipe.guaranteedOutput)
    end

    return craftableItems
end

--- @param recipeStore CraftingRecipeStore
--- @param itemSystem ItemServerConnector
--- @return TableCrafter
function TableCrafter.new(recipeStore, itemSystem)
    local crafter = {
        recipeStore = recipeStore,
        itemSystem = itemSystem
    }

    return setmetatable(crafter, { __index = TableCrafter })
end


return TableCrafter