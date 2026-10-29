-- fishing.lua - Fishing System Connector - connects all fishing components
local Fishing = {}

-- Import the main fishing controller (which handles all subsystems)
local FishingController = require("fishing.fishingcontroller")
local CastingSystem = require("fishing.castingsystem")

-- Initialize all fishing components (delegate to controller)
function Fishing:init()
    FishingController:init()
end

-- Update all fishing components (delegate to controller)
function Fishing:update(dt)
    local Weather = require("world.weather")
    local DayNightCycle = require("world.daynightcycle")
    local weatherData = Weather:getWeatherData()
    FishingController:update(dt, weatherData, DayNightCycle)
end

-- Draw all fishing components
function Fishing:draw()
    if FishingController:getState() ~= "idle" then
        local playerX, playerY = require("player"):getPosition()
        local playerWidth, playerHeight = require("player"):getDimensions()
        
        -- Draw fishing rod (more realistic angle and position)
        love.graphics.setColor(0.4, 0.25, 0.1, 1) -- Darker brown for rod
        love.graphics.setLineWidth(4)
        
        -- Rod extends from player's right hand position at an angle
        local rodStartX = playerX + playerWidth/3  -- Start more to the right
        local rodStartY = playerY - playerHeight/4 -- Start from player's hand level
        
        -- Add rod bend effect when fish is biting or struggling
        local fishingState = FishingController:getState()
        local isBiting = self:isBiting()
        local bendOffset = 0
        
        if isBiting or fishingState == "struggling" or fishingState == "reeling" then
            -- Rod bends under pressure
            local time = love.timer.getTime()
            bendOffset = math.sin(time * 8) * 3 + 5 -- Rod bends down
        end
        
        local rodEndX = playerX + 40  -- Extend further right
        local rodEndY = playerY - playerHeight - 30 + bendOffset  -- Higher up, with bend
        
        -- Draw the rod
        love.graphics.line(rodStartX, rodStartY, rodEndX, rodEndY)
        
        -- Draw rod handle (thicker part near player)
        love.graphics.setColor(0.3, 0.2, 0.1, 1)
        love.graphics.setLineWidth(6)
        local handleLength = 0.25
        local handleEndX = rodStartX + (rodEndX - rodStartX) * handleLength
        local handleEndY = rodStartY + (rodEndY - rodStartY) * handleLength
        love.graphics.line(rodStartX, rodStartY, handleEndX, handleEndY)
        
        -- Reset line width and draw the casting system
        love.graphics.setLineWidth(1)
        local isBiting = self:isBiting()
        CastingSystem:draw(rodEndX, rodEndY, FishingController:getState(), isBiting)
    end
end

function Fishing:drawUI()
    -- UI drawing is handled by the original systems in main.lua
    -- Individual components don't have separate drawUI methods
end

-- Delegate all methods to FishingController
function Fishing:getState()
    return FishingController:getState()
end

function Fishing:setState(state)
    return FishingController:setState(state)
end

function Fishing:getBaitInventory()
    return FishingController:getBaitInventory()
end

function Fishing:getCurrentBait()
    return FishingController:getCurrentBait()
end

function Fishing:selectBait(index)
    return FishingController:selectBait(index)
end

function Fishing:toggleCasting()
    return FishingController:toggleCasting()
end

function Fishing:attemptHookSet()
    return FishingController:attemptHookSet()
end

function Fishing:manualReel()
    return FishingController:manualReel()
end

function Fishing:forceBite()
    return FishingController:forceBite()
end

function Fishing:getCastPower()
    return FishingController:getCastPower()
end

function Fishing:getTotalCatches()
    return FishingController:getTotalCatches()
end

function Fishing:getNightsCaught()
    return FishingController:getNightsCaught()
end

function Fishing:getLineStress()
    return FishingController:getLineStress()
end

function Fishing:getMaxLineStress()
    return FishingController:getMaxLineStress()
end

function Fishing:isFishPulling()
    return FishingController:isFishPulling()
end

function Fishing:getReelProgress()
    return FishingController:getReelProgress()
end

function Fishing:getMaxReelProgress()
    return FishingController:getMaxReelProgress()
end

function Fishing:getStrugglingIntensity()
    return FishingController:getStrugglingIntensity()
end

function Fishing:getCurrentCatch()
    return FishingController:getCurrentCatch()
end

function Fishing:isBiting()
    return FishingController:isBiting()
end

function Fishing:getBiteTimer()
    return FishingController:getBiteTimer()
end

function Fishing:getBiteDelay()
    return FishingController:getBiteDelay()
end

function Fishing:keypressed(key)
    return FishingController:keypressed(key)
end

return Fishing
