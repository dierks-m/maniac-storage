package.path = package.path .. ";/?.lua"

local PhysicalInventory = require("module.inventory.PhysicalInventory")
local ChestSizeChecker = require("module.inventory.ChestSizeChecker")
local DrawerSizeChecker = require("module.inventory.DrawerSizeChecker")
local NoLimitSizeChecker = require("module.inventory.NoLimitSizeChecker")
local ChestItemCache = require("module.inventory.ChestItemCache")
local DefaultItemCache = require("module.inventory.DefaultItemCache")
local CompactingDrawerItemCache = require("module.inventory.CompactingDrawerItemCache")
local IdentifierInventory = require("module.inventory.IdentifierInventory")
local ItemFilter = require("util.itemFilter")
local FilterList = require("util.filterList")
local DynamicWhitelist = require("util.dynamicWhitelist")
local CompoundInventory = require("module.compoundInventory")
local CrafterResourceHandler = require("CrafterResourceHandler")
local CrafterConnector = require("util.CrafterConnector")

-- Variables --
--- @class InventoryEntry
--- @field name string
--- @field priority number
--- @field whitelist table
--- @field type string

--- @class TextConfiguration
--- @field inventories InventoryEntry[]
--- @field identifier string

--- @class Configuration
--- @field inventory CompoundInventory
--- @field identifier IdentifierInventory
--- @field crafterResourceHandler CrafterResourceHandler
-- Variables --

-- Functions --
local function loadFile(configPath)
    local file = fs.open(configPath, 'r')

    if not file then
        return {}
    end

    local content = textutils.unserializeJSON(file.readAll())
    file.close()

    return content or {}
end

local function assertType(value, allowedType, nilAllowed, defaultValue, message)
    if value == nil then
        if nilAllowed then
            return defaultValue
        else
            error(message)
        end
    end

    if type(value) ~= allowedType then
        error(message)
    end

    return value
end

--- @param configTable table
--- @return TextConfiguration
local function sanitizeConfiguration(configTable)
    --- @type TextConfiguration
    local config = {
        inventories = {},
        crafters = {}
    }

    if type(configTable.inventories) == "table" then
        for name, inv in pairs(configTable.inventories) do
            assertType(name, "string", false, nil, "Inventory name must be present")
            if type(inv) == "table" then
                local inventory = {
                    priority = assertType(inv.priority, "number", true, 0, "Priority must be number value"),
                    whitelist = assertType(inv.whitelist, "table", true, nil, "Whitelist must be table of items"),
                    blacklist = assertType(inv.blacklist, "table", true, nil, "Whitelist must be table of items"),
                    disableLimitCheck = assertType(inv.disableLimitCheck, "boolean", true, false, "Limit check must be boolean"),
                    dynamicWhitelist = assertType(inv.dynamicWhitelist, "boolean", true, false, "Dynamic whitelist must be boolean")
                }

                config.inventories[name] = inventory

                if (inventory.whitelist or inventory.blacklist) and inventory.dynamicWhitelist then
                    print("Dynamic whitelist enabled, but whitelist or blacklist specified. Only explicit list will be used.")
                end

                if inventory.whitelist and inventory.blacklist then
                    print("Both whitelist and blacklist enabled. Whitelist will take precedence.")
                end
            end
        end
    end

    if assertType(configTable.crafters, "table", true, nil, "Crafters must be list of computer IDs.") then
        for _, id in pairs(configTable.crafters) do
            if type(id) == "number" then
                config.crafters[#config.crafters + 1] = id
            else
                print("Malformed crafter ID '" .. tostring(id) .. "'. Only numbers are allowed.")
            end
        end
    end


    if assertType(configTable.identifier, "string", true, nil, "Identifier inventory must be string.") then
        config.identifier = configTable.identifier
    end

    return config
end

--- @param name string
--- @return Inventory
local function createInventory(name, inventory)
    --- @type SizeChecker
    local sizeChecker
    --- @type ItemCache
    local itemCache

    if name:match("^storagedrawers") then
        if name:match("fractional_drawers") then
            itemCache = CompactingDrawerItemCache.new(name)
        else
            itemCache = DefaultItemCache.new(name)
        end
        sizeChecker = DrawerSizeChecker.new(itemCache, name)
    else
        itemCache = ChestItemCache.new(name)
        sizeChecker = ChestSizeChecker.new(itemCache, peripheral.call(name, "size"))
    end

    if inventory.disableLimitCheck then
        sizeChecker = NoLimitSizeChecker.new()
    end

    local newInventory = PhysicalInventory.new(name, itemCache, sizeChecker)

    local filterList = inventory.whitelist or inventory.blacklist

    if filterList then
        local filters = {}

        for _, rawFilter in pairs(filterList) do
            filters[#filters + 1] = ItemFilter.new(rawFilter)
        end

        local itemFilterList = FilterList.new(table.unpack(filters))
        itemFilterList:setWhiteList(inventory.whitelist and true or false)
        newInventory:setFilter(itemFilterList)
    elseif inventory.dynamicWhitelist then
        newInventory:setFilter(DynamicWhitelist.new(newInventory))
    end

    return newInventory
end

--- @param configPath string
--- @return Configuration
local function loadConfiguration(configPath)
    --- @type Configuration
    local configuration = {
        inventory = CompoundInventory.new(),
        crafterResourceHandler = CrafterResourceHandler.new({})
    }

    local textConfiguration = sanitizeConfiguration(loadFile(configPath))

    for name, inventory in pairs(textConfiguration.inventories) do
        while not peripheral.getType(name) do
            print("Peripheral " .. name .. " not available. Waiting 5s.")
            sleep(5)
        end

        configuration.inventory:addInventory(
                createInventory(name, inventory),
                inventory.priority
        )
    end

    for _, crafterId in pairs(textConfiguration.crafters) do
        configuration.crafterResourceHandler:addCrafter(CrafterConnector.new(crafterId))
    end

    if textConfiguration.identifier then
        configuration.identifier = IdentifierInventory.new(textConfiguration.identifier)
    end

    return configuration
end
-- Functions --

return {
    loadConfiguration = loadConfiguration
}