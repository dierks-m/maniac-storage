local Item = require("util.item")

--- @class ItemServerConnector
--- @field localInventoryName string
local ItemServerConnector = {}

local READINESS_PROTOCOL = "PROTOCOL_ITEM_SERVER_READINESS"
local READINESS_RESPONSE = "PROTOCOL_ITEM_SERVER_READINESS_RESPONSE"
local PROTOCOL_ITEM_REQUEST = "PROTOCOL_ITEM_REQUEST"
local PROTOCOL_REQUEST_RESPONSE = "PROTOCOL_REQUEST_RESPONSE"

--- @param targetSlot number
--- @param itemFilter ItemFilter
--- @param count number
function ItemServerConnector:extract(targetSlot, itemFilter, count)
    rednet.broadcast({
        command = "extract",
        args = table.pack(
                self.localInventoryName,
                targetSlot,
                itemFilter,
                count
        )
    }, PROTOCOL_ITEM_REQUEST)

    local _, response = rednet.receive(PROTOCOL_REQUEST_RESPONSE)

    if not response.success then
        return 0
    end

    return response.result[1]
end

--- @param sourceSlot number
--- @param item Item
--- @param count number
function ItemServerConnector:insert(sourceSlot, item, count)
    rednet.broadcast({
        command = "insert",
        args = table.pack(
                self.localInventoryName,
                sourceSlot,
                item,
                count
        )
    }, PROTOCOL_ITEM_REQUEST)

    local _, response = rednet.receive(PROTOCOL_REQUEST_RESPONSE)

    if not response.success then
        return 0
    end

    return response.result[1]
end

--- @return Item[]
function ItemServerConnector:getItems()
    rednet.broadcast({
        command = "getItems"
    }, PROTOCOL_ITEM_REQUEST)

    local _, response = rednet.receive(PROTOCOL_REQUEST_RESPONSE)

    if not response.success then
        return {}
    end

    local rawItems = response.result[1]
    local wrappedItems = {}

    for _, item in pairs(rawItems) do
        wrappedItems[#wrappedItems + 1] = Item.new(item)
    end

    return wrappedItems
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