-- settings.lua - Game settings management
local Settings = {
    peacefulMode = false,  -- When true, disables horror elements and night fish
    volume = 1.0,         -- Game volume (0.0 to 1.0)
    settings_version = 1, -- For future compatibility
    fullscreen = false,   -- Fullscreen state
    currentWidth = 800,   -- Current resolution width
    currentHeight = 600,  -- Current resolution height
    resolutions = {
        {width = 800, height = 600, name = "800x600 (Fixed)"}
    }
}

-- Load settings from file
function Settings:load()
    -- Reset to defaults first
    self.peacefulMode = false
    self.volume = 1.0
    self.settings_version = 1
    
    -- Get current window state
    self.currentWidth, self.currentHeight = love.graphics.getDimensions()
    self.fullscreen = love.window.getFullscreen()
    
    if love.filesystem.getInfo("settings.dat") then
        local content = love.filesystem.read("settings.dat")
        if content then
            local success, data = pcall(function()
                return love.data.decode("string", "base64", content)
            end)
            if success and data then
                -- Convert the decoded string back to settings
                for line in data:gmatch("[^\n]+") do
                    local key, value = line:match("^(.+)=(.+)$")
                    if key and value then
                        if value == "true" then value = true
                        elseif value == "false" then value = false
                        elseif tonumber(value) then value = tonumber(value)
                        end
                        self[key] = value
                    end
                end
            end
        end
    end
    
    print("Settings loaded: " .. self.currentWidth .. "x" .. self.currentHeight .. ", Fullscreen: " .. tostring(self.fullscreen))
end

-- Save settings to file
function Settings:save()
    -- Convert settings to string format
    local settingsStr = string.format(
        "peacefulMode=%s\nvolume=%s\nsettings_version=%s\nfullscreen=%s\ncurrentWidth=%s\ncurrentHeight=%s",
        tostring(self.peacefulMode),
        tostring(self.volume),
        tostring(self.settings_version),
        tostring(self.fullscreen),
        tostring(self.currentWidth),
        tostring(self.currentHeight)
    )
    
    -- Encode and save
    local content = love.data.encode("string", "base64", settingsStr)
    love.filesystem.write("settings.dat", content)
    print("Settings saved: " .. self.currentWidth .. "x" .. self.currentHeight .. ", Fullscreen: " .. tostring(self.fullscreen))
end

-- Toggle peaceful mode
function Settings:togglePeacefulMode()
    self.peacefulMode = not self.peacefulMode
    self:save()
end

-- Get peaceful mode state
function Settings:isPeacefulMode()
    -- Ensure peacefulMode is initialized
    if self.peacefulMode == nil then
        self.peacefulMode = false
    end
    print("Peaceful Mode Check:", self.peacefulMode)  -- Debug print
    return self.peacefulMode
end

-- Set resolution
function Settings:setResolution(width, height)
    self.currentWidth = width
    self.currentHeight = height
    love.window.setMode(width, height, {fullscreen = self.fullscreen, resizable = true})
    self:save()
    print("Resolution set to: " .. width .. "x" .. height)
end

-- Fullscreen methods
function Settings:getFullscreen()
    return self.fullscreen
end

function Settings:setFullscreen(enabled)
    self.fullscreen = enabled
    love.window.setMode(self.currentWidth, self.currentHeight, {fullscreen = self.fullscreen, resizable = true})
    self:save()
    print("Fullscreen set to: " .. tostring(self.fullscreen))
end

function Settings:toggleFullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setMode(self.currentWidth, self.currentHeight, {fullscreen = self.fullscreen, resizable = true})
    self:save()
    print("Fullscreen toggled: " .. tostring(self.fullscreen))
    return self.fullscreen
end

-- Get current resolution index
function Settings:getCurrentResolutionIndex()
    for i, res in ipairs(self.resolutions) do
        if res.width == self.currentWidth and res.height == self.currentHeight then
            return i
        end
    end
    return 1 -- Default to first resolution if not found
end

-- Auto-save methods
function Settings:getAutoSave()
    return true -- Default to true
end

function Settings:setAutoSave(enabled)
    -- Placeholder for autosave setting
    return true
end

function Settings:toggleAutoSave()
    -- Placeholder for autosave toggle
    return true
end

-- Volume methods
function Settings:getSoundVolume()
    return math.floor(self.volume * 100)
end

function Settings:setSoundVolume(volume)
    self.volume = math.max(0, math.min(100, volume)) / 100
    self:save()
end

function Settings:getMusicVolume()
    return math.floor(self.volume * 100) -- Using same volume for now
end

function Settings:setMusicVolume(volume)
    self.volume = math.max(0, math.min(100, volume)) / 100
    self:save()
end

-- Menu drawing function
function Settings:drawMenu(currentMenu, menus, selectedOption, animationTimer, titleGlowTimer, showResolutionDropdown, selectedResolution)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Background gradient
    love.graphics.setColor(0.05, 0.1, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    local menu = menus[currentMenu]
    if not menu then return end
    
    -- Title
    local titleFont = love.graphics.newFont(48)
    local subtitleFont = love.graphics.newFont(20)
    local optionFont = love.graphics.newFont(24)
    
    love.graphics.setFont(titleFont)
    local titleGlow = 0.3 + 0.2 * math.sin(titleGlowTimer)
    love.graphics.setColor(0.8, 0.9, 1, titleGlow)
    local titleWidth = titleFont:getWidth(menu.title)
    love.graphics.print(menu.title, screenWidth/2 - titleWidth/2, 80)
    
    if menu.subtitle then
        love.graphics.setFont(subtitleFont)
        love.graphics.setColor(0.6, 0.7, 0.8, 0.8)
        local subtitleWidth = subtitleFont:getWidth(menu.subtitle)
        love.graphics.print(menu.subtitle, screenWidth/2 - subtitleWidth/2, 140)
    end
    
    -- Menu text content (for credits/how_to_play)
    if menu.text then
        love.graphics.setFont(optionFont)
        local startY = 180
        for i, line in ipairs(menu.text) do
            love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
            local textWidth = optionFont:getWidth(line)
            love.graphics.print(line, screenWidth/2 - textWidth/2, startY + (i-1) * 30)
        end
        
        -- Draw back option at bottom
        if menu.options and #menu.options > 0 then
            local backY = startY + #menu.text * 30 + 40
            local option = menu.options[1]
            local isSelected = selectedOption == 1
            
            if isSelected then
                love.graphics.setColor(1, 0.8, 0.3, 1)
                local pulse = 0.8 + 0.2 * math.sin(animationTimer * 4)
                love.graphics.setColor(pulse, pulse * 0.8, pulse * 0.3, 1)
            else
                love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
            end
            
            local textWidth = optionFont:getWidth(option.text)
            love.graphics.print(option.text, screenWidth/2 - textWidth/2, backY)
        end
        return
    end
    
    -- Menu options
    love.graphics.setFont(optionFont)
    local startY = 220
    
    for i, option in ipairs(menu.options) do
        local y = startY + (i-1) * 60
        local isSelected = selectedOption == i
        
        if isSelected then
            local pulse = 0.8 + 0.2 * math.sin(animationTimer * 4)
            love.graphics.setColor(pulse, pulse * 0.8, pulse * 0.3, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        end
        
        local displayText = option.text
        
        -- Add current values for settings
        if currentMenu == "settings" then
            if option.action == "toggle_fullscreen" then
                displayText = displayText .. (self:getFullscreen() and "ON" or "OFF")
            elseif option.action == "toggle_resolution" then
                local resIndex = self:getCurrentResolutionIndex()
                displayText = displayText .. self.resolutions[resIndex].name
            elseif option.action == "adjust_volume" then
                displayText = displayText .. self:getSoundVolume() .. "%"
            elseif option.action == "adjust_music" then
                displayText = displayText .. self:getMusicVolume() .. "%"
            elseif option.action == "toggle_autosave" then
                displayText = displayText .. (self:getAutoSave() and "ON" or "OFF")
            end
        end
        
        love.graphics.print(displayText, 100, y)
        
        -- Resolution dropdown
        if currentMenu == "settings" and option.action == "toggle_resolution" and showResolutionDropdown and isSelected then
            local dropdownY = y + 40
            love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
            love.graphics.rectangle("fill", 120, dropdownY, 400, #self.resolutions * 30)
            
            for j, res in ipairs(self.resolutions) do
                local resY = dropdownY + (j-1) * 30
                if j == selectedResolution then
                    love.graphics.setColor(0.8, 0.6, 0.2, 1)
                else
                    love.graphics.setColor(0.6, 0.6, 0.6, 1)
                end
                love.graphics.print("  " .. res.name, 125, resY)
            end
        end
    end
end

return Settings
