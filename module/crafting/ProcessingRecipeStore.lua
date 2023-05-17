local Set = require("util.Set")

--- @class ProcessingRecipeInput
--- @field filter ItemFilter
--- @field count number

--- @class ProcessingRecipe
--- @field input Set<ProcessingRecipeInput>
--- @field guaranteedOutput Item

--- @class ProcessingRecipeStore
--- @field recipes Set<ProcessingRecipe>
local ProcessingRecipeStore = {}


--- @param itemFilter Filter
--- @return Set<ProcessingRecipe>
function ProcessingRecipeStore:getRecipes(itemFilter)
    if not itemFilter then
        return self.recipes
    end

    --- @type Set<Item>
    local matchingRecipes = Set.new()

    for _, recipe in pairs(self.recipes:toList()) do
        if itemFilter:matches(recipe.guaranteedOutput) then
            matchingRecipes:add(recipe)
        end
    end

    return matchingRecipes
end

--- @param itemDecorator ItemDecorator
--- @vararg ProcessingRecipe
--- @return ProcessingRecipeStore
function ProcessingRecipeStore.new(itemDecorator, ...)
    local store = {recipes = Set.new(...)}

    for _, recipe in pairs(store.recipes:toList()) do
        recipe.guaranteedOutput = itemDecorator:decorate(recipe.guaranteedOutput)
    end

    return setmetatable(store, {__index = ProcessingRecipeStore})
end

return ProcessingRecipeStore