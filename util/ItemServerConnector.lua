local UUID = require("util.UUID")
local Item = require("util.Item")
local ItemSet = require("util.ItemSet")

--- @class ItemServerConnector
--- @field localInventoryName string
local ItemServerConnector = {}

local READINESS_PROTOCOL = "PROTOCOL_ITEM_SERVER_READINESS"
local READINESS_RESPONSE = "PROTOCOL_ITEM_SERVER_READINESS_RESPONSE"
local PROTOCOL_ITEM_REQUEST = "PROTOCOL_ITEM_REQUEST"
local PROTOCOL_REQUEST_RESPONSE = "PROTOCOL_REQUEST_RESPONSE"


local function waitForResponse(requestId)
    while true do
        local _, response = rednet.receive(PROTOCOL_REQUEST_RESPONSE)

        if response.requestId == requestId then
            return response
        end
    end
end

--- @param targetSlot number
--- @param itemFilter ItemFilter
--- @param count number
function ItemServerConnector:extract(targetSlot, itemFilter, count)
    local requestId = UUID.generate()
    rednet.broadcast({
        command = "extract",
        args = table.pack(
                self.localInventoryName,
                targetSlot,
                itemFilter,
                count
        ),
        requestId = requestId
    }, PROTOCOL_ITEM_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        return 0
    end

    return response.result[1]
end

--- @param sourceSlot number
--- @param item Item
--- @param count number
function ItemServerConnector:insert(sourceSlot, item, count)
    local requestId = UUID.generate()
    rednet.broadcast({
        command = "insert",
        args = table.pack(
                self.localInventoryName,
                sourceSlot,
                item,
                count
        ),
        requestId = requestId
    }, PROTOCOL_ITEM_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        return 0
    end

    return response.result[1]
end

function ItemServerConnector:insertUnknown(sourceSlot, count)
    local requestId = UUID.generate()
    rednet.broadcast({
        command = "insertUnknown",
        args = table.pack(
                self.localInventoryName,
                sourceSlot,
                count
        ),
        requestId = requestId
    }, PROTOCOL_ITEM_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        return 0
    end

    return response.result[1]
end

--- @return ItemSet
function ItemServerConnector:getItems()
    local requestId = UUID.generate()
    rednet.broadcast({
        command = "getItems",
        requestId = requestId
    }, PROTOCOL_ITEM_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        return {}
    end

    local rawItems = response.result[1]
    local result = ItemSet.new()

    for _, item in pairs(rawItems.items) do
        result:add(Item.new(item))
    end

    return result
end

--- @param itemFilter ItemFilter
--- @param count number
--- @return number
function ItemServerConnector:craft(itemFilter, count)
    local requestId = UUID.generate()
    rednet.broadcast({
        command = "craft",
        args = {itemFilter, count},
        requestId = requestId
    }, PROTOCOL_ITEM_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        return 0
    end

    return response.result[1]
end

function ItemServerConnector:connect()
    rednet.broadcast(nil, READINESS_PROTOCOL)
    rednet.receive(READINESS_RESPONSE)
end

--- @param localInventoryName string
--- @return ItemServerConnector
function ItemServerConnector.new(localInventoryName)
    return setmetatable({ localInventoryName = localInventoryName }, { __index = ItemServerConnector })
end


return ItemServerConnector