--- @class CraftingRecipeStore
--- @field recipes CraftingRecipe[]
local CraftingRecipeStore = {}


--- @param itemFilter Filter
--- @return CraftingRecipe[]
function CraftingRecipeStore:getRecipes(itemFilter)
    local matchingRecipes = {}

    for _, recipe in pairs(self.recipes) do
        if itemFilter:matches(recipe.guaranteedOutput) then
            matchingRecipes[#matchingRecipes + 1] = recipe
        end
    end

    return matchingRecipes
end

--- @vararg CraftingRecipe
--- @return CraftingRecipeStore
function CraftingRecipeStore.new(...)
    local store = {recipes = {...}}

    return setmetatable(store, {__index = CraftingRecipeStore})
end


return CraftingRecipeStore