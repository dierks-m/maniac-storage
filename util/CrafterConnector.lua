local UUID = require("util.UUID")
local Set = require("util.Set")
local Item = require("util.Item")

--- @class CrafterConnector : Crafter
--- @field remoteId number The computer's ID
local CrafterConnector = {}

local PROTOCOL_CRAFT_REQUEST = "PROTOCOL_ITEM_REQUEST"
local PROTOCOL_CRAFT_RESPONSE = "PROTOCOL_REQUEST_RESPONSE"
local PROTOCOL_CRAFT_READINESS = "PROTOCOL_CRAFT_READINESS"

local function waitForResponse(requestId)
    while true do
        local _, response = rednet.receive(PROTOCOL_CRAFT_RESPONSE)

        if response.requestId == requestId then
            return response
        end
    end
end

function CrafterConnector:craft(itemFilter, count)
    local requestId = UUID.generate()
    rednet.send(self.remoteId, {
        command = "craft",
        args = { itemFilter, count },
        requestId = requestId
    }, PROTOCOL_CRAFT_REQUEST)

    local response = waitForResponse(requestId)

    if not response.success then
        print("Error: " .. response.result[1])
        return 0
    end

    return response.result[1]
end

function CrafterConnector:getCraftableItems()
    local requestId = UUID.generate()
    rednet.send(self.remoteId, {
        command = "getCraftableItems",
        requestId = requestId
    }, PROTOCOL_CRAFT_REQUEST)

    local response = waitForResponse(requestId)

    if not response or not response.success then
        --- @type Set<Item>
        return Set.new()
    end

    --- @type Set<Item>
    local items = Set.new()

    for _, item in pairs(response.result[1]) do
        items:add(Item.new(item))
    end

    return items
end

function CrafterConnector:connect()
    while true do
        rednet.send(self.remoteId, nil, PROTOCOL_CRAFT_READINESS)

        if rednet.receive(PROTOCOL_CRAFT_READINESS, 10) then
            return true
        end
    end
end

--- @param remoteId number
--- @return CrafterConnector
function CrafterConnector.new(remoteId)
    return setmetatable({ remoteId = remoteId }, { __index = CrafterConnector })
end

return CrafterConnector