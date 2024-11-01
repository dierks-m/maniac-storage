--- @class ClientConfiguration
--- @field theme string
--- @field serverId number
--- @field outputInventory string

--- @class ClientConfiguration : SanitizedConfiguration
local ClientConfiguration = {}

local function loadFile(configPath)
    local file = fs.open(configPath, 'r')

    if not file then
        error("Configuration file '" .. configPath .. "' not found.")
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

--- @param raw table
local function sanitizeConfiguration(raw)
    local result = {}  --- @type ClientConfiguration

    assertType(raw, "table", false, nil, "Configuration must have map form.")

    result.theme = assertType(raw.theme, "string", true, "light", "Theme must be string")
    result.serverId = assertType(raw.server_id, "number", false, nil, "Server ID must be provided")
    result.outputInventory = assertType(raw.output_inventory, "string", false, nil, "Output inventory must be provided")

    return result
end

--- @param path string
--- @return ClientConfiguration
function ClientConfiguration.load(path)
    return sanitizeConfiguration(loadFile(path))
end

return ClientConfiguration
