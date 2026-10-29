local Journal = {}

function Journal:isOpen()
    return isOpen
end

-- Data structure: { [day] = {"Sunfish", "Bass", ...} }
local entriesByDay = {}
local isOpen = false
local currentDay = 1
local scrollOffset = 0

function Journal:init()
    entriesByDay = {}
    currentDay = 1
end

function Journal:hasEntry(species)
    local speciesList = entriesByDay[currentDay] or {}
    for _, entry in ipairs(speciesList) do
        local fishName = type(entry) == "table" and entry.name or entry
        if fishName == species then return true end
    end
    return false
end

function Journal:addCatch(day, fishName, fishData)
    if not entriesByDay[day] then entriesByDay[day] = {} end
    
    -- Store more detailed fish information
    local catchEntry = {
        name = fishName,
        time = os.date("%H:%M"),
        data = fishData or {}
    }
    
    table.insert(entriesByDay[day], catchEntry)
    print("📖 Added " .. fishName .. " to journal for day " .. day)
end

function Journal:toggle()
    isOpen = not isOpen
end

function Journal:drawUI()
    if not isOpen then return end
    local width, height = love.graphics.getWidth() * 0.6, love.graphics.getHeight() * 0.7
    -- Center the journal properly
    local x, y = love.graphics.getWidth() * 0.2, love.graphics.getHeight() * 0.15
    
    -- Sync with game's current day
    local DayNightCycle = require("world.daynightcycle")
    currentDay = DayNightCycle:getCurrentDay()

    -- Background
    love.graphics.setColor(0.97, 0.95, 0.92, 0.98)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.2, 0.1, 0.05, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, width, height)

    -- Title
    local titleFont = love.graphics.newFont(28)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.2, 0.1, 0.05, 1)
    love.graphics.print("JOURNAL", x + 20, y + 20)

    -- Day label
    local dayLabel = "Day " .. tostring(currentDay)
    local labelFont = love.graphics.newFont(20)
    love.graphics.setFont(labelFont)
    love.graphics.print(dayLabel, x + 20, y + 60)

    -- Species list
    local speciesList = entriesByDay[currentDay] or {}
    local listFont = love.graphics.newFont(16)
    love.graphics.setFont(listFont)
    local listY = y + 100
    local lineHeight = 28
    local maxVisible = math.floor((height - 160) / lineHeight)
    if #speciesList == 0 then
        love.graphics.setColor(0.5, 0.2, 0.2, 1)
        love.graphics.print("No fish caught today.", x + 40, listY)
    else
        love.graphics.setColor(0.2, 0.1, 0.05, 1)
        for i = scrollOffset + 1, math.min(#speciesList, scrollOffset + maxVisible) do
            local entry = speciesList[i]
            local fishName = type(entry) == "table" and entry.name or entry
            local timeStr = type(entry) == "table" and entry.time and (" @ " .. entry.time) or ""
            love.graphics.print("• " .. fishName .. timeStr, x + 40, listY)
            listY = listY + lineHeight
        end
        -- Draw scrollbar if needed
        if #speciesList > maxVisible then
            local barHeight = math.max(30, (height - 160) * (maxVisible / #speciesList))
            local barY = y + 100 + ((height - 160 - barHeight) * (scrollOffset / (#speciesList - maxVisible)))
            love.graphics.setColor(0.5, 0.4, 0.3, 0.7)
            love.graphics.rectangle("fill", x + width - 15, barY, 8, barHeight)
            love.graphics.setColor(0.3, 0.2, 0.1, 1)
            love.graphics.rectangle("line", x + width - 15, barY, 8, barHeight)
        end
    end

    -- Controls
    love.graphics.setColor(0.3, 0.2, 0.1, 0.9)
    love.graphics.print("TAB: Close | ←→: Change Day", x + 20, y + height - 30)
end

function Journal:keypressed(key)
    if key == "tab" then
        Journal:toggle()
        return
    end
    if not isOpen then return end
    local speciesList = entriesByDay[currentDay] or {}
    local height = love.graphics.getHeight() * 0.7
    local lineHeight = 28
    local maxVisible = math.floor((height - 160) / lineHeight)
    if key == "right" then
        currentDay = currentDay + 1
        if not entriesByDay[currentDay] then entriesByDay[currentDay] = {} end
        scrollOffset = 0
    elseif key == "left" then
        currentDay = math.max(1, currentDay - 1)
        scrollOffset = 0
    elseif key == "down" and #speciesList > maxVisible and scrollOffset < #speciesList - maxVisible then
        scrollOffset = scrollOffset + 1
    elseif key == "up" and scrollOffset > 0 then
        scrollOffset = scrollOffset - 1
    end
end

return Journal
