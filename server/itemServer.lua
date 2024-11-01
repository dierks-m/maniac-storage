local Configuration = require("Configuration")
local ItemFilter = require("util.itemFilter")
local Set = require("util.Set")
local Item = require("util.Item")
local ThreadPool = require("module.threading.ThreadPool")
local Thread = require("module.threading.Thread")

-- Variables --
local config --- @type Configuration

local requestQueue = {}
local requests = {}
local threadPool = ThreadPool.new()

local READINESS_PROTOCOL = "PROTOCOL_ITEM_SERVER_READINESS"
local READINESS_RESPONSE = "PROTOCOL_ITEM_SERVER_READINESS_RESPONSE"
local READINESS_MESSAGE = "ITEM_SERVER_READY"
local REQUEST_PROTOCOL = "PROTOCOL_ITEM_REQUEST"
local RESPONSE_PROTOCOL = "PROTOCOL_REQUEST_RESPONSE"
local PROTOCOL_CRAFT_READINESS = "PROTOCOL_CRAFT_READINESS"
-- Variables --


-- Functions --
requests.extract = function(targetName, targetSlot, itemFilter, count)
    return config.inventory:extract(
            targetName,
            targetSlot,
            ItemFilter.new(itemFilter),
            count
    )
end

requests.insert = function(sourceName, sourceSlot, item, count)
    return config.inventory:insert(
            sourceName,
            sourceSlot,
            Item.new(item),
            count
    )
end

requests.insertUnknown = function(sourceName, sourceSlot, count)
    local item, slot = config.identifier:identifyItem(sourceName, sourceSlot, count)

    return config.inventory:insert(config.identifier.inventoryName, slot, item, count)
end

requests.empty = function(sourceName)
    local containedStacks = peripheral.call(sourceName, "list")
    local totalInserted = 0

    for slot, stack in pairs(containedStacks) do
        totalInserted = totalInserted + requests.insert(
                sourceName,
                slot,
                Item.new(peripheral.call(sourceName, "getItemDetail", slot)),
                stack.count
        )
    end

    return totalInserted
end

requests.craft = function(itemFilter, count)
    local itemFilter = ItemFilter.new(itemFilter)
    local availableCrafter = config.crafterResourceHandler:getCrafter(itemFilter)

    if availableCrafter then
        return availableCrafter:craft(itemFilter, count)
    end

    return 0
end

requests.getCraftableItems = function()
    --- @type Set<Item>
    local craftableItems = Set.new()

    for _, crafter in pairs(config.crafterResourceHandler:getCrafters()) do
        craftableItems = craftableItems:unite(crafter:getCraftableItems())
    end

    return craftableItems:toList()
end

requests.getItems = function()
    return config.inventory:getItems()
end

local function isValidRequest(request)
    if type(request.command) ~= "string" then
        return false
    end

    if request.args ~= nil and type(request.args) ~= "table" then
        return false
    end

    return true
end

local function sendResponse(id, success, requestId, ...)
    rednet.send(id, {success=success, result={...}, requestId = requestId}, RESPONSE_PROTOCOL)
end

local function handleRequest(id, request)
    local ok, err = pcall(function()
        sendResponse(id, true, request.requestId, requests[request.command](table.unpack(request.args, 1, request.args.n))) end
    )

    if not ok then
        sendResponse(id, false, request.requestId, err)
    end
end

local function requestLoop()
    while true do
        while #requestQueue > 0 do
            local requestPair = table.remove(requestQueue, 1)
            local id, request = requestPair.id, requestPair.request

            if not request.args then request.args = {} end

            threadPool:add(Thread.new(function() handleRequest(id, request) end):start())
        end

        os.pullEvent("new_request")
    end
end

local function eventHandler()
    while true do
        local e = {os.pullEvent()}

        if e[1] == "rednet_message" and e[4] == REQUEST_PROTOCOL then
            local request = e[3]

            if isValidRequest(request) and requests[request.command] then
                requestQueue[#requestQueue + 1] = {id=e[2], request=request}
                os.queueEvent("new_request")
            end
        elseif e[1] == "rednet_message" and e[4] == READINESS_PROTOCOL then
            rednet.send(e[2], READINESS_MESSAGE, READINESS_RESPONSE)
        elseif e[1] == "rednet_message" and e[4] == PROTOCOL_CRAFT_READINESS then
            rednet.send(e[2], READINESS_MESSAGE, PROTOCOL_CRAFT_READINESS)
        end
    end
end

local function initialize()
    for _, name in pairs(redstone.getSides()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
            break
        end
    end

    for _, name in pairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" and peripheral.call(name, "isWireless") then
            rednet.open(name)
            break
        end
    end

    local timeBefore = os.clock()

    print("Loading configuration.")
    config = Configuration.loadConfiguration("/server/config.json")

    print("Indexing inventories.")
    config.inventory:getItems() -- Force cache initialization
    print("Startup completed after " .. math.floor((os.clock() - timeBefore) * 10) / 10 .. "s.")
end

local function inputLoop()
    while true do
        local event = {os.pullEvent("char")}

        if event[2]:lower() == "q" then
            break
        end
    end
end
-- Functions --

initialize()
rednet.broadcast(READINESS_MESSAGE, READINESS_RESPONSE)

threadPool:join(Thread.new(eventHandler):start())
threadPool:join(Thread.new(requestLoop):start())
threadPool:join(Thread.new(inputLoop):start())

threadPool:run()