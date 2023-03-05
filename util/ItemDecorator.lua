--- @class ItemDecorator
--- @field tags table<string, table<string, boolean>> Mapping between tag and items that carry this tag
local ItemDecorator = {}

--- @class ItemDecoratorConfiguration
--- @field tags table<string, string[]>

--- @param self ItemDecorator
--- @param itemName string
--- @return table<string, boolean>
local function getTagsForName(self, itemName)
    local tags = {}

    for tag, items in pairs(self.tags) do
        if items[itemName] then
            tags[tag] = true
        end
    end

    return tags
end

--- @param item Item
--- @return Item
function ItemDecorator:decorate(item)
    item.tags = item.tags or getTagsForName(self, item.name)

    return item
end

--- @param configTags table<string, string[]>
--- @return table<string, table<string, boolean>>
local function parseTags(configTags)
    local tags = {}

    for tagName, items in pairs(configTags) do
        if not tags[tagName] then tags[tagName] = {} end

        for _, item in pairs(items) do
            tags[tagName][item] = true
        end
    end

    return tags
end

--- @param config ItemDecoratorConfiguration
--- @return ItemDecorator
function ItemDecorator.fromConfiguration(config)
    local itemLookup = {}

    itemLookup.tags = parseTags(config.tags or {})

    return setmetatable(itemLookup, {__index = ItemDecorator })
end


return ItemDecorator