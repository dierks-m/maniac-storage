local Item = require("util.item")
local Set = require("util.Set")

--- @class ProcessingCrafter : Crafter
--- @field input string
--- @field output string
--- @field inputConnector ItemServerConnector
--- @field outputConnector ItemServerConnector
--- @field timeoutSeconds number
--- @field recipeStore ProcessingRecipeStore
local ProcessingCrafter = {}
local craftInternal


--- @param inventoryName string
--- @param connector ItemServerConnector
local function storeItems(inventoryName, connector)
    local items = peripheral.call(inventoryName, "list")

    for slot in pairs(items) do
        local item = Item.new(peripheral.call(inventoryName, "getItemDetail", slot))

        connector:insert(slot, item, item.count)
    end
end

--- @param self ProcessingCrafter
--- @param item Item
local function countItems(self, resultItem)
    local itemCount = 0
    local items = peripheral.call(self.output, "list")

    for _, item in pairs(items) do
        if resultItem == Item.new(item) then
            itemCount = itemCount + item.count
        end
    end

    return itemCount
end

--- @param self ProcessingCrafter
--- @param output Item
local function getResultCount(self, output, outputCount)
    local timeout = os.startTimer(self.timeoutSeconds)
    local checkTimer = os.startTimer(1)
    local previousCount = 0

    while true do
        local event = {os.pullEvent()}

        if event[1] == "timer" then
            if event[2] == timeout then
                break
            elseif event[2] == checkTimer then
                local currentCount = countItems(self, output)

                if currentCount ~= previousCount then
                    os.cancelTimer(timeout)
                    timeout = os.startTimer(self.timeoutSeconds)
                    previousCount = currentCount
                end

                if currentCount == outputCount then
                    break
                end

                checkTimer = os.startTimer(1)
            end
        end
    end

    return previousCount
end

--- @param self ProcessingCrafter
--- @param items Set<ProcessingRecipeInput>
--- @param count number
--- @param attemptedRecipes Set<ProcessingRecipe>
local function retrieveItems(self, items, count, attemptedRecipes)
    local allItemsInserted

    repeat
        allItemsInserted = true

        for _, item in pairs(items:toList()) do
            local extractedCount = self.inputConnector:extract(nil, item.filter, item.count * count)

            if extractedCount == 0 then
                storeItems(self.input, self.inputConnector) -- Cleanup before crafting dependency

                if craftInternal(self, item, count, attemptedRecipes:clone()) == 0 and self.inputConnector:craft(item.filter, item.count * count) == 0 then
                    return false
                end

                allItemsInserted = false
                break
            end
        end
    until allItemsInserted

    return true
end

--- @param self ProcessingCrafter
--- @param recipe ProcessingRecipe
--- @param amount number
--- @param attemptedRecipes Set<ProcessingRecipe>
--- @return number The number of items crafted
local function craftRecipe(self, recipe, amount, attemptedRecipes)
    local craftedAmount = 0

    while craftedAmount < amount do
        local craftAmount = math.ceil((amount - craftedAmount) / recipe.guaranteedOutput.count)

        if not retrieveItems(self, recipe.input, craftAmount, attemptedRecipes) then
            break
        end

        craftedAmount = craftedAmount + getResultCount(self, recipe.guaranteedOutput, (amount - craftedAmount))


        storeItems(self.output, self.outputConnector)
    end

    return craftedAmount
end

--- @param self ProcessingCrafter
--- @param itemFilter Filter
--- @param count number
--- @param attemptedRecipes Set<ProcessingRecipe>
craftInternal = function(self, itemFilter, count, attemptedRecipes)
    local matchingRecipes = self.recipeStore:getRecipes(itemFilter):difference(attemptedRecipes)
    local craftedAmount = 0
    local craftedThisRound

    for _, recipe in pairs(matchingRecipes:toList()) do
        attemptedRecipes:add(recipe)
        craftedThisRound = craftRecipe(self, recipe, count - craftedAmount, attemptedRecipes)
        craftedAmount = craftedAmount + craftedThisRound

        if craftedAmount >= count or craftedThisRound == 0 then
            break
        end
    end

    return craftedAmount
end

function ProcessingCrafter:craft(itemFilter, count)
    local craftedCount =  craftInternal(self, itemFilter, count, Set.new())
    return craftedCount
end

function ProcessingCrafter:getCraftableItems()
    local recipes = self.recipeStore:getRecipes(nil):toList()

    --- @type Set<Item>
    local craftableItems = Set.new()

    for _, recipe in pairs(recipes) do
        craftableItems:add(recipe.guaranteedOutput)
    end

    return craftableItems
end

--- @param input string
--- @param output string
--- @param recipeStore ProcessingRecipeStore
--- @param inputConnector ItemServerConnector
--- @param outputConnector ItemServerConnector
--- @return ProcessingCrafter
function ProcessingCrafter.new(input, output, recipeStore, inputConnector, outputConnector)
    local crafter = {
        recipeStore = recipeStore,
        input = input,
        output = output,
        inputConnector = inputConnector,
        outputConnector = outputConnector,
        timeoutSeconds = 30
    }

    return setmetatable(crafter, { __index = ProcessingCrafter })
end

return ProcessingCrafter