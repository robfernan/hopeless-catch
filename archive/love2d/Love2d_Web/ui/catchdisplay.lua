-- Catch Display System
-- Beautiful fish presentation when catching fish

local CatchDisplay = {}
local Assets = require("assets")

-- Display state
local catchInfo = nil
local displayTimer = 0
local animationPhase = "hidden" -- hidden, appearing, showing, disappearing
local fishScale = 0
local fishRotation = 0
local particleSystem = nil

-- Animation parameters
local APPEAR_TIME = 0.8
local SHOW_TIME = 3.0
local DISAPPEAR_TIME = 0.6

function CatchDisplay:init()
    -- Initialize particle system for sparkles/splash effects
    local texture = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(texture)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 2, 2, 2)
    love.graphics.setCanvas()
    
    particleSystem = love.graphics.newParticleSystem(texture, 50)
    particleSystem:setParticleLifetime(0.5, 1.5)
    particleSystem:setEmissionRate(30)
    particleSystem:setSizeVariation(0.5)
    particleSystem:setLinearAcceleration(-20, -50, 20, -30)
    particleSystem:setColors(
        0.8, 0.9, 1.0, 1.0,
        0.6, 0.8, 1.0, 0.8,
        0.4, 0.6, 0.9, 0.0
    )
end

function CatchDisplay:showCatch(fish)
    catchInfo = {
    name = fish.name,
    description = fish.description,
    weight = fish.weight or (math.random(5, 50) / 10),
    rarity = fish.rarity or "Common",
    isNew = fish.isNew or false
    }
    
    displayTimer = 0
    animationPhase = "appearing"
    fishScale = 0
    fishRotation = math.random() * math.pi * 2
    
    -- Start particle effect
    if particleSystem then
        particleSystem:emit(20)
    end
    
    print("🐟 Displaying catch: " .. fish.name)
end

function CatchDisplay:update(dt)
    if not catchInfo then return end
    
    displayTimer = displayTimer + dt
    
    if animationPhase == "appearing" then
        -- Fish grows and spins into view
        local progress = displayTimer / APPEAR_TIME
        if progress >= 1 then
            animationPhase = "showing"
            displayTimer = 0
            fishScale = 1
            fishRotation = 0
        else
            -- Easing function for smooth appearance
            local eased = 1 - (1 - progress) ^ 3
            fishScale = eased * (1 + 0.2 * math.sin(progress * math.pi * 4))
            fishRotation = fishRotation + dt * (1 - progress) * 8
        end
    elseif animationPhase == "showing" then
        -- Gentle floating animation, stays until user presses a key
        fishScale = 1 + 0.05 * math.sin(displayTimer * 2)
    elseif animationPhase == "disappearing" then
        -- Fish fades out
        local progress = displayTimer / DISAPPEAR_TIME
        if progress >= 1 then
            animationPhase = "hidden"
            catchInfo = nil
            fishScale = 0
        else
            fishScale = (1 - progress) * (1 + 0.1 * math.sin(displayTimer * 4))
        end
    end
    
    -- Update particles
    if particleSystem then
        particleSystem:update(dt)
    end
end

function CatchDisplay:draw()
    if not catchInfo or animationPhase == "hidden" then return end
    
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local centerX, centerY = screenWidth / 2, screenHeight / 2 - 50
    
    -- Background panel
    local panelWidth, panelHeight = 520, 380
    local panelX, panelY = centerX - panelWidth/2, centerY - panelHeight/2
    local panelAlpha = fishScale * 0.95
    
    -- Panel background (different style for horror fish)
    -- Use horror catch display for horror fish by name
    local horrorFishNames = {
        ["Pale Crawler"] = true,
        ["Whispering Eel"] = true,
        ["Bleeding Carp"] = true,
        ["Fishman"] = true
    }
    if horrorFishNames[catchInfo.name] then
        love.graphics.setColor(0.1, 0.05, 0.05, panelAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
        love.graphics.setColor(0.6, 0.1, 0.1, panelAlpha)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
        love.graphics.setColor(0.4, 0.1, 0.1, panelAlpha * 0.5)
        for i = 1, 5 do
            love.graphics.rectangle("line", panelX - i, panelY - i, panelWidth + i*2, panelHeight + i*2)
        end
    else
        love.graphics.setColor(0.9, 0.95, 1.0, panelAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
        love.graphics.setColor(0.3, 0.5, 0.7, panelAlpha)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
        love.graphics.setColor(0.4, 0.6, 0.8, panelAlpha)
        local cornerSize = 20
        for _, corner in ipairs({{panelX, panelY}, {panelX + panelWidth - cornerSize, panelY}, 
                                {panelX, panelY + panelHeight - cornerSize}, {panelX + panelWidth - cornerSize, panelY + panelHeight - cornerSize}}) do
            love.graphics.rectangle("fill", corner[1], corner[2], cornerSize, 3)
            love.graphics.rectangle("fill", corner[1], corner[2], 3, cornerSize)
        end
    end
    
    -- Draw fish sprite
    love.graphics.setColor(1, 1, 1, fishScale)
    local fishDrawn = Assets:drawFish(catchInfo.name, centerX, centerY - 30, fishScale * 2, fishRotation)
    
    if not fishDrawn then
        -- Fallback fish drawing
        local fishColor = {0.6, 0.7, 0.8}
        if horrorFishNames[catchInfo.name] then
            fishColor = {0.7, 0.3, 0.3}
        end
        
        love.graphics.setColor(fishColor[1], fishColor[2], fishColor[3], fishScale)
        love.graphics.push()
        love.graphics.translate(centerX, centerY - 30)
        love.graphics.scale(fishScale * 2)
        love.graphics.rotate(fishRotation)
        
        -- Simple fish shape
        love.graphics.ellipse("fill", 0, 0, 30, 15)
        love.graphics.polygon("fill", 25, 0, 40, -8, 40, 8) -- tail
        
        -- Eye
        love.graphics.setColor(1, 1, 1, fishScale)
        love.graphics.circle("fill", -10, -5, 4)
        love.graphics.setColor(0, 0, 0, fishScale)
        love.graphics.circle("fill", -8, -5, 2)
        
        love.graphics.pop()
    end
    
        -- Fish name centered
        local nameColor = horrorFishNames[catchInfo.name] and {0.9, 0.4, 0.4} or {0.2, 0.4, 0.6}
        love.graphics.setColor(nameColor[1], nameColor[2], nameColor[3], fishScale)
        local defaultFont = love.graphics.getFont()  -- Store current font
        local nameFont = love.graphics.newFont(28)
        love.graphics.setFont(nameFont)
        love.graphics.printf(catchInfo.name, panelX, centerY + 40, panelWidth, "center")
        love.graphics.setFont(defaultFont)  -- Restore original font for other text
    
    -- Fish details
    local detailsY = centerY + 90
    local textColor = horrorFishNames[catchInfo.name] and {0.8, 0.6, 0.6} or {0.3, 0.3, 0.3}
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], fishScale)
    
    love.graphics.printf("Weight: " .. string.format("%.1f", catchInfo.weight) .. " lbs", panelX, detailsY, panelWidth, "center")
    love.graphics.printf("Rarity: " .. catchInfo.rarity, panelX, detailsY + 20, panelWidth, "center")
    
    if catchInfo.isNew then
        love.graphics.setColor(0.9, 0.7, 0.2, fishScale)
        love.graphics.printf("★ NEW SPECIES DISCOVERED! ★", panelX, detailsY + 40, panelWidth, "center")
    end
    
    if horrorFishNames[catchInfo.name] then
        local DayNightCycle = require("world.daynightcycle")
        if DayNightCycle:isNightTime() then
            love.graphics.setColor(0.8, 0.2, 0.2, fishScale * (0.8 + 0.2 * math.sin(displayTimer * 8)))
            love.graphics.printf("Something is wrong with this creature...", panelX, detailsY + 60, panelWidth, "center")
        end
    end
    
    -- Draw particles
    if particleSystem and animationPhase == "appearing" then
        love.graphics.setColor(1, 1, 1, fishScale)
        love.graphics.draw(particleSystem, centerX, centerY)
    end
    
    -- Subtle instruction
    if animationPhase == "showing" then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
        love.graphics.printf("Press any key to continue...", panelX, panelY + panelHeight - 25, panelWidth, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function CatchDisplay:isShowing()
    return catchInfo ~= nil and animationPhase ~= "hidden"
end

function CatchDisplay:dismiss()
    if animationPhase == "showing" then
        animationPhase = "disappearing"
        displayTimer = 0
    end
end

return CatchDisplay
