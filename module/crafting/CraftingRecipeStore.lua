--- @class CraftingRecipeStore
--- @field recipes CraftingRecipe[]
local CraftingRecipeStore = {}


--- @param itemFilter Filter
--- @return CraftingRecipe[]
function CraftingRecipeStore:getRecipes(itemFilter)
    if not itemFilter then
        return self.recipes
    end

    local matchingRecipes = {}

    for _, recipe in pairs(self.recipes) do
        if itemFilter:matches(recipe.guaranteedOutput) then
            matchingRecipes[#matchingRecipes + 1] = recipe
        end
    end

    return matchingRecipes
end

--- @param itemDecorator ItemDecorator
--- @vararg CraftingRecipe
--- @return CraftingRecipeStore
function CraftingRecipeStore.new(itemDecorator, ...)
    local store = {recipes = {...}}

    for _, recipe in pairs(store.recipes) do
        recipe.guaranteedOutput = itemDecorator:decorate(recipe.guaranteedOutput)
    end

    return setmetatable(store, {__index = CraftingRecipeStore})
end


return CraftingRecipeStore