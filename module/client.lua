-- Variables --
--- @class Client
--- @field inventory Inventory
local Client = {}
-- Variables --


-- Functions --
function Client:run()

end

--- @param inventory Inventory
--- @return Client
local function newClient(inventory)
    local client = {
        inventory = inventory
    }

    return setmetatable(client, {__index = Client})
end
-- Functions --

return {
    new = newClient
}