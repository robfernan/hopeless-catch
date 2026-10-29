local Journal = {}

function Journal:isOpen()
    return isOpen
end

-- Data structure: { [day] = {"Sunfish", "Bass", ...} }
local entriesByDay = {}
local isOpen = false
local currentDay = 1
local scrollOffset = 0

-- Secret / horror journal entries (unlocked by events, not catches)
local secretEntries = {}   -- { [day] = {"It saw you too.", ...} }
local secretsUnlocked = {} -- track which secrets have been revealed

-- Cached fonts (created once, not every frame)
local titleFont = nil
local labelFont = nil
local listFont = nil

function Journal:init()
    entriesByDay = {}
    secretEntries = {}
    secretsUnlocked = {}
    currentDay = 1
    isOpen = false
    scrollOffset = 0
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

--- Unlock a secret journal entry (called by horror event system or fish catches).
-- These are narrative fragments that appear alongside normal catches.
-- Dedup is guaranteed: the same day+text pair can only be unlocked once.
-- @param day number - which day the entry belongs to
-- @param text string - the secret line, e.g. "It saw you too."
function Journal:unlockSecretEntry(day, text)
    local key = day .. ":" .. text
    if secretsUnlocked[key] then return end  -- already unlocked (no duplicates)

    if not secretEntries[day] then secretEntries[day] = {} end
    table.insert(secretEntries[day], {
        name = text,
        time = "???",
        data = {secret = true, source = "horror_event"}
    })
    secretsUnlocked[key] = true
    print("📖 Secret journal entry unlocked (Day " .. day .. "): \"" .. text .. "\"")
end

--- Unlock a narrative snippet triggered by catching a specific fish at night.
-- Functionally identical to unlockSecretEntry but tagged with the source fish
-- so the journal can render it with a slightly different visual cue if desired.
-- @param day number - which day the entry belongs to
-- @param text string - the creepy narrative line
-- @param sourceFish string (optional) - name of the fish that triggered it
function Journal:unlockNarrativeSnippet(day, text, sourceFish)
    local key = day .. ":" .. text
    if secretsUnlocked[key] then return end  -- no duplicates for same day+text

    if not secretEntries[day] then secretEntries[day] = {} end
    table.insert(secretEntries[day], {
        name = text,
        time = "???",
        data = {secret = true, source = "fish_catch", fish = sourceFish or "?"}
    })
    secretsUnlocked[key] = true
    print("📖 Narrative unlocked (Day " .. day .. ", from " .. (sourceFish or "?") .. "): \"" .. text .. "\"")
end

--- Check if a specific secret entry has been unlocked.
function Journal:hasSecretEntry(day, text)
    return secretsUnlocked[day .. ":" .. text] == true
end

--- Get all secret entries (for save/load).
-- Returns the raw { [day] = {entryTable, ...} } structure.
function Journal:getSecretEntries()
    return secretEntries
end

--- Get all entries (catches + secrets) for a given day, merged in order.
-- Secrets appear after normal catches with a distinct visual marker.
local function getAllEntriesForDay(day)
    local result = {}
    -- Normal catches first
    local catches = entriesByDay[day] or {}
    for _, e in ipairs(catches) do table.insert(result, e) end
    -- Secret entries appended after
    local secrets = secretEntries[day] or {}
    for _, s in ipairs(secrets) do table.insert(result, s) end
    return result
end

function Journal:drawUI()
    if not isOpen then return end
    
    -- Cache fonts (create once)
    if not titleFont then titleFont = love.graphics.newFont(28) end
    if not labelFont then labelFont = love.graphics.newFont(20) end
    if not listFont then listFont = love.graphics.newFont(16) end
    
    local width, height = love.graphics.getWidth() * 0.6, love.graphics.getHeight() * 0.7
    -- Center the journal properly
    local x, y = love.graphics.getWidth() * 0.2, love.graphics.getHeight() * 0.15

    -- Background
    love.graphics.setColor(0.97, 0.95, 0.92, 0.98)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.2, 0.1, 0.05, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, width, height)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.2, 0.1, 0.05, 1)
    love.graphics.print("JOURNAL", x + 20, y + 20)

    -- Day label
    local dayLabel = "Day " .. tostring(currentDay)
    love.graphics.setFont(labelFont)
    love.graphics.print(dayLabel, x + 20, y + 60)

    -- Species list (catches + secret entries)
    local speciesList = getAllEntriesForDay(currentDay)
    love.graphics.setFont(listFont)
    local listY = y + 100
    local lineHeight = 28
    local maxVisible = math.floor((height - 160) / lineHeight)
    if #speciesList == 0 then
        love.graphics.setColor(0.5, 0.2, 0.2, 1)
        love.graphics.print("No fish caught today.", x + 40, listY)
    else
        love.graphics.setColor(0.2, 0.1, 0.05, 1)
        -- Clamp scroll offset in case the list shrank since it was set
        if scrollOffset > #speciesList - maxVisible then scrollOffset = math.max(0, #speciesList - maxVisible) end
        for i = scrollOffset + 1, math.min(#speciesList, scrollOffset + maxVisible) do
            local entry = speciesList[i]
            local fishName = (type(entry) == "table" and entry.name) or entry
            local timeStr = type(entry) == "table" and entry.time and (" @ " .. entry.time) or ""
            local isSecret = type(entry) == "table" and entry.data and entry.data.secret == true
            if isSecret then
                -- Secret entries render in a darker, unsettling style with ✦ bullet
                love.graphics.setColor(0.4, 0.1, 0.3, 1)
                local line = "✦ " .. fishName
                -- Fish-catch narratives get a subtle source attribution
                if entry.data.source == "fish_catch" and entry.data.fish then
                    love.graphics.print(line, x + 40, listY)
                    -- Source tag in smaller, dimmer text on the right
                    local srcTag = "(" .. entry.data.fish .. ")"
                    local tagW = listFont:getWidth(srcTag)
                    love.graphics.setColor(0.35, 0.15, 0.25, 0.7)
                    love.graphics.print(srcTag, x + width - 40 - tagW, listY)
                else
                    love.graphics.print(line, x + 40, listY)
                end
            else
                love.graphics.setColor(0.2, 0.1, 0.05, 1)
                love.graphics.print("• " .. fishName .. timeStr, x + 40, listY)
            end
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
