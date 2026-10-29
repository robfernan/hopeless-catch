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
    local data = {
        totalCatches = fishingSystem:getTotalCatches(),
        horrorLevel = fishingSystem:getHorrorLevel(),
        nightsCaught = fishingSystem:getNightsCaught(),
        journalEntries = journal:getEntryCount(),
        discoveries = atmosphericEffects and self:countDiscoveries() or 0,
        playTime = love.timer.getTime(),
        lastSaved = os.time()
    }
    
    local serialized = self:serialize(data)
    love.filesystem.write("hopeless_catch_save.dat", serialized)
    
    print("💾 Game saved successfully!")
    return true
end

function SaveSystem:load()
    if love.filesystem.getInfo("hopeless_catch_save.dat") then
        local content = love.filesystem.read("hopeless_catch_save.dat")
        if content then
            local data = self:deserialize(content)
            if data then
                saveData = data
                print("📁 Save file loaded!")
                return true
            end
        end
    end
    
    print("📁 No save file found - starting fresh")
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
    for line in content:gmatch("[^\n]+") do
        local key, value = line:match("([^=]+)=(.+)")
        if key and value then
            -- Try to convert to number if possible
            local num = tonumber(value)
            data[key] = num or value
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
