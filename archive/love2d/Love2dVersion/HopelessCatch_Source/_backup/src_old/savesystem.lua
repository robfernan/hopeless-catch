-- Save System
-- Simple save/load functionality for the fishing horror game

local SaveSystem = {}

local saveData = {
    totalCatches = 0,
    horrorLevel = 0,
    fishCaught = {},
    journalEntries = 0,
    discoveries = 0,
    playTime = 0,
    lastSaved = 0
}

function SaveSystem:init()
    self:load()
end

function SaveSystem:save(fishingSystem, journal, atmosphericEffects)
    -- Guard against nil subsystems
    if not fishingSystem or not journal then
        print("⚠️ SaveSystem:save called with missing subsystem(s)")
        return false
    end
    
    local data = {
        totalCatches = (fishingSystem.getTotalCatches and fishingSystem:getTotalCatches()) or 0,
        horrorLevel = (fishingSystem.getHorrorLevel and fishingSystem:getHorrorLevel()) or 0,
        nightsCaught = (fishingSystem.getNightsCaught and fishingSystem:getNightsCaught()) or 0,
        journalEntries = (journal.getEntryCount and journal:getEntryCount()) or 0,
        discoveries = atmosphericEffects and self:countDiscoveries() or 0,
        playTime = love.timer.getTime(),
        lastSaved = os.time()
    }
    
    -- Capture current day count from DayNightCycle
    local DayNightCycle = require("world.daynightcycle")
    if type(DayNightCycle.getCurrentDay) == "function" then
        data.currentDay = DayNightCycle:getCurrentDay()
    end
    
    -- Capture secret journal entries (serialized as day:text pairs)
    if type(journal.getSecretEntries) == "function" then
        local secrets = journal:getSecretEntries()
        if secrets and next(secrets) ~= nil then
            local secretStrs = {}
            for day, entries in pairs(secrets) do
                for _, entry in ipairs(entries) do
                    local text = type(entry) == "table" and (entry.name or "?") or tostring(entry)
                    table.insert(secretStrs, day .. ":" .. text)
                end
            end
            data.secretEntries = table.concat(secretStrs, ";")
        else
            data.secretEntries = ""
        end
    end
    
    local serialized = self:serialize(data)
    local ok, err = pcall(love.filesystem.write, "hopeless_catch_save.dat", serialized)
    if not ok then
        print("⚠️ Save failed: " .. tostring(err))
        return false
    end
    
    -- Update in-memory copy so getSaveData() reflects the latest save
    saveData = data
    print("💾 Game saved successfully!")
    return true
end

function SaveSystem:load()
    local ok, info = pcall(love.filesystem.getInfo, "hopeless_catch_save.dat")
    if not ok or not info then
        print("📁 No save file found - starting fresh")
        return false
    end
    
    local readOk, content = pcall(love.filesystem.read, "hopeless_catch_save.dat")
    if not readOk or not content then
        print("⚠️ Save file exists but could not be read - starting fresh")
        return false
    end
    
    local data = self:deserialize(content)
    if data and next(data) ~= nil then
        saveData = data
        
        -- Restore current day into DayNightCycle
        if data.currentDay then
            local DayNightCycle = require("world.daynightcycle")
            if type(DayNightCycle.setCurrentDay) == "function" then
                DayNightCycle:setCurrentDay(tonumber(data.currentDay) or 1)
            end
        end
        
        -- Restore secret journal entries into Journal
        if data.secretEntries and data.secretEntries ~= "" then
            local Journal = require("ui.journal")
            if type(Journal.unlockSecretEntry) == "function" then
                for pair in (tostring(data.secretEntries)):gmatch("[^;]+") do
                    local day, text = pair:match("^(%d+):(.+)$")
                    if day and text then
                        Journal:unlockSecretEntry(tonumber(day), text)
                    end
                end
            end
        end
        
        print("📁 Save file loaded!")
        return true
    end
    
    print("⚠️ Save file was empty or malformed - starting fresh")
    return false
end

function SaveSystem:serialize(data)
    -- Simple serialization (for a jam, this is fine)
    local result = {}
    for k, v in pairs(data) do
        table.insert(result, k .. "=" .. tostring(v))
    end
    return table.concat(result, "\n")
end

function SaveSystem:deserialize(content)
    local data = {}
    for line in content:gmatch("[^\r\n]+") do
        -- Skip empty lines and comments
        if line ~= "" and not line:match("^%s*#") then
            local key, value = line:match("^(%S+)%s*=%s*(.+)$")
            if key and value and #key > 0 then
                -- Try to convert to number if possible
                local num = tonumber(value)
                data[key] = num or value
            end
        end
    end
    return data
end

function SaveSystem:countDiscoveries()
    -- This would normally check with AtmosphericEffects
    -- For now, return a placeholder
    return 0
end

function SaveSystem:getSaveData()
    return saveData
end

function SaveSystem:autoSave()
    -- Auto-save every 5 minutes of play time
    if love.timer.getTime() - (saveData.lastSaved or 0) > 300 then
        -- We'd call the full save here if systems were available
        saveData.lastSaved = love.timer.getTime()
        return true
    end
    return false
end

return SaveSystem
