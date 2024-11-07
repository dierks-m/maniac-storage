package.path = package.path .. ";/?.lua"

local Thread = require("module.threading.Thread")
local ThreadPool = require("module.threading.ThreadPool")

local Item = require("util.Item")
local KeyComboHandler = require("client.KeyComboHandler")
local ReadPrompt = require("client.ReadPrompt")
local ItemServerConnector = require("util.ItemServerConnector")
local SmartItemFilter = require("client.SmartItemFilter")
local ClientConfiguration = require("client.ClientConfiguration")

-- Variables --
local config = ClientConfiguration.load("client_configuration.json")
local autoClearSearchInterval = 30

local mainWindow
local itemSelectionWindow
local searchBarWindow
local itemInfoWindow
local logWindow
local orderWindow
local orderPrompt
local rawNameWindow

local availableItems
local filteredItems
local selectedItem
local itemFilter = SmartItemFilter.new()
local searchDisabled = false
local itemServerConnector  --- @type ItemServerConnector

local blitColor = {
    background = "f",
    orderBackground = "6",
    itemCount = "1",
    stackSizeText = "2",
    selectedBackground = "3",
    durabilitySelected = "5",
    text = "4",
    windowBackground = "8",
    durability = "d",
    enchantmentText = "e",
    durabilityText = "c",

    gray = "7"
}

local themes = {
    light = {
        background = 0xfafafa,
        windowBackground = 0xe6e6e6,
        orderBackground = 0xc4c4c4,
        selectedBackground = 0xc1cede,
        text = 0x404040,
        durability = 0xbfbfbf,
        durabilitySelected = 0x93abc9,
        durabilityText = 0x046335,
        itemCount = 0x0e7d64,
        enchantmentText = 0xa80a94,
        stackSizeText = 0xc27b2b,
    },

    dark = {
        background = 0x4a4a4a,
        windowBackground = 0x2e2e2e,
        orderBackground = 0x808080,
        selectedBackground = 0x24405c,
        text = 0xe8e8e8,
        durability = 0x2a2638,
        durabilitySelected = 0x2f8a78,
        durabilityText = 0x046335,
        itemCount = 0x0e7d64,
        enchantmentText = 0x910980,
        stackSizeText = 0xc27b2b,
        gray = 0x9c9c9c,
    }
}

local threadPool = ThreadPool.new()
-- Variables --


-- Functions --
--- @return Item[]
local function getAvailableItems()
    local content = itemServerConnector:getItems()
    local result = {}

    for _, item in content:iterator() do
        table.insert(result, item)
    end

    table.sort(result, function(a, b) return a.displayName < b.displayName end)

    return result
end

local function orderItem(item, amount)
    os.queueEvent("item_order", amount)

    local result = itemServerConnector:extract(
            nil,
            item,
            amount
    )

    os.queueEvent("item_delivered", item, result)
end

--- @param amount number
--- @return string
local function formatAmount(amount)
    if amount < 1000 then
        return string.format("%4d", amount)
    elseif amount < 1000000 then
        return string.format("%3.2gk", amount / 1000)
    else
        return string.format("%3.2gM", amount / 1000000)
    end
end

--- @param itemList Item[]
--- @param selectedItem Item
--- @param win
local function drawItemSelectionWindow(itemList, selectedItem, win)
    win.clear()
    local sizeX, sizeY = win.getSize()

    for i, item in pairs(itemList) do
        win.setCursorPos(1, i)

        local bgColor = item == selectedItem and blitColor.durabilitySelected or blitColor.durability
        local bgColor2 = item == selectedItem and blitColor.selectedBackground or blitColor.windowBackground
        local textColor = item.enchantments and blitColor.enchantmentText or blitColor.text
        local durabilityWidth = math.floor((item.durability or 0) * sizeX)

        local amount = formatAmount(item.count)
        local truncatedName = item.displayName:sub(1, sizeX - #amount)

        win.blit(
                truncatedName .. (" "):rep(sizeX - #amount - #truncatedName) .. amount,
                textColor:rep(sizeX - #amount) .. blitColor.itemCount:rep(#amount),
                bgColor:rep(durabilityWidth) .. bgColor2:rep(sizeX - durabilityWidth)
        )

        if i == sizeY then
            break
        end
    end
end

local function drawItemInfoWindow()
    itemInfoWindow.clear()
    if rawNameWindow then
        rawNameWindow.clear()
    end

    if not selectedItem then
        return
    end

    local yPos = 1

    if selectedItem.durability then
        itemInfoWindow.setCursorPos(1, yPos)
        itemInfoWindow.setTextColor(colors.fromBlit(blitColor.durabilityText))
        itemInfoWindow.write("Durability ")
        itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
        itemInfoWindow.write((selectedItem.maxDamage - selectedItem.damage) .. "/" .. selectedItem.maxDamage)
        yPos = yPos + 2
    end

    if selectedItem.enchantments then
        itemInfoWindow.setCursorPos(1, yPos)
        itemInfoWindow.setTextColor(colors.fromBlit(blitColor.enchantmentText))
        itemInfoWindow.write("Enchantments")
        itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
        yPos = yPos + 1

        for i, enchantment in pairs(selectedItem.enchantments) do
            itemInfoWindow.setCursorPos(1, yPos)
            itemInfoWindow.write(" " .. enchantment.displayName)
            yPos = yPos + 1
        end

        yPos = yPos + 1
    end

    itemInfoWindow.setCursorPos(1, yPos)
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.stackSizeText))
    itemInfoWindow.write("Stack Size ")
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemInfoWindow.write(selectedItem.maxCount)
    yPos = yPos + 1
    itemInfoWindow.setCursorPos(1, yPos)
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.stackSizeText))
    itemInfoWindow.write("Available  ")
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemInfoWindow.write(selectedItem.count)

    if rawNameWindow then
        rawNameWindow.setCursorPos(1, 1)
        rawNameWindow.write(selectedItem.name)
    end
end

local function determineClickedItem(cursorX, cursorY)
    local offsetX, offsetY = itemSelectionWindow.getPosition()
    local sizeX, sizeY = itemSelectionWindow.getSize()

    if cursorX < offsetX or cursorX >= offsetX + sizeX
            or cursorY < offsetY or cursorY >= offsetY + sizeY then
        return nil
    end

    local clickedY = cursorY - offsetY + 1

    if not filteredItems[clickedY] then
        return nil
    end

    return Item.new(filteredItems[clickedY])
end

local function determineSelectedItem(previous)
    if not previous then
        return nil
    end

    for _, item in pairs(availableItems) do
        if previous == item then
            return Item.new(item)
        end
    end
end

local function containsItem(itemList, item)
    if not item then
        return false
    end

    for k, i in pairs(itemList) do
        if item == i then
            return k
        end
    end

    return false
end

local function filterAvailableItems(items, filter)
    local result = {}

    for _, v in pairs(items) do
        if filter:matches(v) then
            result[#result + 1] = v
        end
    end

    return result
end

local function inputEventHandler(currInput)
    itemFilter:setPattern(currInput)
    filteredItems = filterAvailableItems(availableItems, itemFilter)
    drawItemSelectionWindow(filteredItems, selectedItem, itemSelectionWindow)
end

local function inputLoop(win)
    local autoClearTimerId = os.startTimer(autoClearSearchInterval)
    local keyComboHandler = KeyComboHandler.new()
    local inputPrompt = ReadPrompt.new("", win, true)
    inputPrompt:focus()
    inputPrompt:draw()

    while true do
        local event = {keyComboHandler:pullEvent()}

        if not searchDisabled then
            inputPrompt:processEvent(table.unpack(event))
            inputEventHandler(inputPrompt.currentText)
            inputPrompt:focus()

            if event[1] == "key_combo" and (event[2] == keys.leftCtrl or event[2] == keys.rightCtrl) and event[3] == keys.c then
                inputPrompt:clear()
            end

            if event[1] == "char" then
                os.cancelTimer(autoClearTimerId)
                autoClearTimerId = os.startTimer(autoClearSearchInterval)
            end
        end

        if event[1] == "timer" and event[2] == autoClearTimerId then
            autoClearTimerId = os.startTimer(autoClearSearchInterval)

            if inputPrompt.currentText ~= "" then
                inputPrompt:clear()
                inputEventHandler(inputPrompt.currentText)
                inputPrompt:focus()
            end
        end
    end
end

local function mouseHandler()
    while true do
        local e = {os.pullEvent()}

        if not searchDisabled and (e[1] == "mouse_click" or e[1] == "mouse_drag") and e[2] == 1 then
            local previouslySelected = selectedItem
            selectedItem = determineClickedItem(e[3], e[4])

            if previouslySelected ~= selectedItem then
                local blink = term.getCursorBlink()
                term.setCursorBlink(false)
                local posX, posY = term.getCursorPos()

                drawItemSelectionWindow(filteredItems, selectedItem, itemSelectionWindow)
                drawItemInfoWindow()

                term.setCursorPos(posX, posY)
                term.setCursorBlink(blink)
            end
        end
    end
end

local function determineAmount()
    local inputPrompt = ReadPrompt.new("", orderPrompt, true)
    local keyComboHandler = KeyComboHandler.new()

    inputPrompt:draw()
    inputPrompt:focus()

    while true do
        local e = {keyComboHandler:pullEvent()}

        inputPrompt:processEvent(table.unpack(e))

        if e[1] == "key" and e[2] == keys.enter then
            return inputPrompt.currentText
        elseif e[1] == "key_combo" and (e[2] == keys.leftCtrl or e[2] == keys.rightCtrl) and e[3] == keys.c then
            return nil
        end
    end
end

local function mtHandler()
    while true do
        os.pullEvent("mt_event")
        rednet.broadcast({
            command = "empty",
            args = table.pack(
                    config.outputInventory
            )
        }, "PROTOCOL_ITEM_REQUEST")
    end
end

local function keyPressHandler()
    local _, selectionWindowYSize = itemSelectionWindow.getSize()

    while true do
        local e = {os.pullEvent()}

        if e[1] == "key" and e[2] == keys.enter and selectedItem then
            searchDisabled = true

            orderWindow.setVisible(true)
            local amount = tonumber(determineAmount())

            if amount and amount > 0 then
                threadPool:add(Thread.new(function()
                    orderItem(selectedItem, amount)
                    availableItems = getAvailableItems()

                    selectedItem = determineSelectedItem(selectedItem)

                    drawItemSelectionWindow(availableItems, selectedItem, itemSelectionWindow)
                    drawItemInfoWindow()
                    os.queueEvent("search_enabled")
                end):start())
            end

            orderWindow.setVisible(false)
            mainWindow.redraw()
            searchDisabled = false
            os.queueEvent("search_enabled")
        elseif e[1] == "key" and e[2] == keys.leftAlt then
            availableItems = getAvailableItems()
            filteredItems = filterAvailableItems(availableItems, itemFilter)

            selectedItem = determineSelectedItem(selectedItem)

            drawItemSelectionWindow(filteredItems, selectedItem, itemSelectionWindow)
            drawItemInfoWindow()

            os.queueEvent("reload_event")
        elseif e[1] == "key" and e[2] == keys.pause then
            os.queueEvent("mt_event")
        elseif e[1] == "key" and e[2] == keys.up then
            local selectedIndex = containsItem(filteredItems, selectedItem)
            selectedIndex = selectedIndex and math.max(1, selectedIndex - 1) or #filteredItems
            selectedIndex = math.min(selectionWindowYSize, selectedIndex)

            selectedItem = filteredItems[selectedIndex] and Item.new(filteredItems[selectedIndex])
            drawItemSelectionWindow(filteredItems, selectedItem, itemSelectionWindow)
            drawItemInfoWindow()
        elseif e[1] == "key" and e[2] == keys.down then
            local selectedIndex = containsItem(filteredItems, selectedItem)
            selectedIndex = (not selectedIndex or selectedIndex > selectionWindowYSize) and 0 or selectedIndex
            selectedIndex = math.min(selectedIndex + 1, #filteredItems, selectionWindowYSize)

            selectedItem = filteredItems[selectedIndex] and Item.new(filteredItems[selectedIndex])
            drawItemSelectionWindow(filteredItems, selectedItem, itemSelectionWindow)
            drawItemInfoWindow()
        end
    end
end

local function statusWindowHandler(statusWindow)
    local _, ySize = statusWindow.getSize()
    local yPos = 0

    local function addLine(text)
        if yPos == ySize then
            statusWindow.scroll(1)
        end

        yPos = math.min(yPos + 1, ySize)

        statusWindow.setCursorPos(1, yPos)
        statusWindow.write(text)
    end

    while true do
        local e = {os.pullEvent()}

        if e[1] == "item_delivered" then
            addLine(" " .. e[3] .. " " .. e[2].displayName)
        elseif e[1] == "reload_event" then
            addLine(" Reloaded")
        elseif e[1] == "mt_event" then
            addLine(" Emptying items")
        end
    end
end

local function setPaletteColors(windowObject)
    for name, color in pairs(themes[config.theme]) do
        windowObject.setPaletteColor(colors.fromBlit(blitColor[name]), color)
    end
end

local function initializeGUIComputer()
    local sizeX, sizeY = term.getSize()

    mainWindow = window.create(term.current(), 1, 1, sizeX, sizeY)
    setPaletteColors(mainWindow)
    mainWindow.setBackgroundColor(colors.fromBlit(blitColor.background))
    mainWindow.clear()

    itemSelectionWindow = window.create(mainWindow, 2, 2, 25, sizeY - 4)
    itemSelectionWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    itemSelectionWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemSelectionWindow.clear()

    searchBarWindow = window.create(mainWindow, 28, 2, sizeX - 28, 1)
    searchBarWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    searchBarWindow.setTextColor(colors.fromBlit(blitColor.text))
    searchBarWindow.clear()

    itemInfoWindow = window.create(mainWindow, 28, 4, sizeX - 28, 9)
    itemInfoWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemInfoWindow.clear()

    logWindow = window.create(mainWindow, 28, 14, sizeX - 28, sizeY - 16)
    logWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    logWindow.setTextColor(colors.fromBlit(blitColor.text))
    logWindow.clear()

    rawNameWindow = window.create(mainWindow, 2, sizeY - 1, sizeX - 10, 1)
    rawNameWindow.setBackgroundColor(colors.fromBlit(blitColor.background))
    rawNameWindow.setTextColor(colors.fromBlit(blitColor.text))
    rawNameWindow.clear()

    orderWindow = window.create(
            term.current(),
            math.floor((sizeX - 25) / 2),
            math.floor((sizeY - 5) / 2),
            25,
            5,
            false
    )
    orderWindow.setBackgroundColor(colors.fromBlit(blitColor.orderBackground))
    orderWindow.setTextColor(colors.fromBlit(blitColor.text))
    orderWindow.clear()
    orderWindow.setCursorPos(4, 3)
    orderWindow.write("Enter Amount: ")

    orderPrompt = window.create(
            orderWindow,
            18,
            3,
            6,
            1
    )
    orderPrompt.setBackgroundColor(colors.fromBlit(blitColor.orderBackground))
    orderPrompt.setTextColor(colors.fromBlit(blitColor.text))
end

local function initializeGUIPocket()
    local sizeX, sizeY = term.getSize()

    mainWindow = window.create(term.current(), 1, 1, sizeX, sizeY)
    setPaletteColors(mainWindow)
    mainWindow.setBackgroundColor(colors.fromBlit(blitColor.background))
    mainWindow.clear()

    itemSelectionWindow = window.create(mainWindow, 1, 3, sizeX, 8)
    itemSelectionWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    itemSelectionWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemSelectionWindow.clear()

    searchBarWindow = window.create(mainWindow, 1, 1, sizeX, 1)
    searchBarWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    searchBarWindow.setTextColor(colors.fromBlit(blitColor.text))
    searchBarWindow.clear()

    itemInfoWindow = window.create(mainWindow, 1, 12, sizeX, sizeY - 11)
    itemInfoWindow.setBackgroundColor(colors.fromBlit(blitColor.windowBackground))
    itemInfoWindow.setTextColor(colors.fromBlit(blitColor.text))
    itemInfoWindow.clear()

    orderWindow = window.create(
            term.current(),
            1,
            math.floor((sizeY - 5) / 2),
            sizeX,
            5,
            false
    )
    orderWindow.setBackgroundColor(colors.fromBlit(blitColor.orderBackground))
    orderWindow.setTextColor(colors.fromBlit(blitColor.text))
    orderWindow.clear()
    orderWindow.setCursorPos(4, 3)
    orderWindow.write("Enter Amount: ")

    orderPrompt = window.create(
            orderWindow,
            18,
            3,
            6,
            1
    )
    orderPrompt.setBackgroundColor(colors.fromBlit(blitColor.orderBackground))
    orderPrompt.setTextColor(colors.white)
end

local function initialize()
    if not themes[config.theme] then
        error("Desired theme '" .. config.theme .. "' not available.")
    end

    for _, side in pairs(rs.getSides()) do
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
        end
    end

    itemServerConnector = ItemServerConnector.new(config.serverId, config.outputInventory)

    print("Waiting for server.")
    itemServerConnector:connect()

    if not pocket then
        initializeGUIComputer()
    else
        initializeGUIPocket()
    end

    availableItems = getAvailableItems()
    filteredItems = availableItems
    drawItemSelectionWindow(availableItems, nil, itemSelectionWindow)

    multishell.setTitle(multishell.getCurrent(), "Item UI")
end
-- Functions --

initialize()

threadPool:join(Thread.new(function() inputLoop(searchBarWindow) end):start())
threadPool:join(Thread.new(keyPressHandler):start())
threadPool:join(Thread.new(mouseHandler):start())
threadPool:join(Thread.new(mtHandler):start())

if not pocket then
    -- Pocket computers have no status window
    threadPool:join(Thread.new(function() statusWindowHandler(logWindow) end):start())
end

local ok, err = pcall(function() threadPool:run() end)
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)

if not ok then
    error(err, 0)
end
