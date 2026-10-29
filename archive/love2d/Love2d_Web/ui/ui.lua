-- ui.lua - UI System Connector - connects all UI components
local UI = {}

-- Import all UI components
local VisualTacklebox = require("ui.visualtacklebox")
local CatchDisplay = require("ui.catchdisplay")
-- Journal is in ui folder
local Journal = require("ui.journal")

-- Initialize all UI components
function UI:init()
    VisualTacklebox:init()
    CatchDisplay:init()
    -- Journal:init()
end

-- Update all UI components  
function UI:update(dt)
    VisualTacklebox:update(dt)
    CatchDisplay:update(dt)
    -- Journal:update(dt)
end

-- State flags for overlays
UI.showSurvivalStats = true
UI.showFishingState = true
UI.showControls = true
UI.showWeather = true
UI.showTackleBox = false
UI.showJournal = false

-- Accessibility option: toggle high contrast UI
UI.highContrast = false
function UI:toggleHighContrast()
    self.highContrast = not self.highContrast
end

function UI:drawControls()
    if not self.showControls then return end
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("WASD/Arrows: Move | SPACE: Cast/Reel | B: Tacklebox | TAB: Journal | ESC: Pause | H: Cabin", 10, 10)
end

function UI:drawWeather()
    if not self.showWeather then return end
    local Weather = require("world.weather")
    local weatherData = Weather:getWeatherData()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Weather: " .. weatherData.name, love.graphics.getWidth() - 200, 32)
end

function UI:drawSurvivalStats()
    -- Statistics display removed for cleaner UI
    return
end

function UI:drawFishingState()
    if not self.showFishingState then return end
    local FishingSystem = require("fishing.fishing")
    local fishingState = FishingSystem:getState()
    local isBiting = false
    if FishingSystem.isBiting then
        isBiting = FishingSystem:isBiting()
    end
    love.graphics.setColor(1, 1, 1, 0.8)
    local tutorialY = 60
    local tutorialX = love.graphics.getWidth() - 420
    -- Add subtle background for visibility
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", tutorialX - 10, tutorialY - 5, 340, 28)
    love.graphics.setColor(1, 1, 1, 0.9)
    local bait = FishingSystem.getCurrentBait and FishingSystem:getCurrentBait() or nil
    -- Removed bait check message since bait is unlimited
    if fishingState == "casting" then
        love.graphics.print("CASTING: Release SPACE at desired power!", tutorialX, tutorialY)
    elseif isBiting then
        -- Show bite detected regardless of state when there's an active bite
        love.graphics.setColor(1, 1, 0, 1) -- Yellow for attention
        love.graphics.print("🎣 BITE DETECTED! Press SPACE quickly! 🎣", tutorialX - 20, tutorialY)
        love.graphics.setColor(1, 1, 1, 0.9)
    elseif fishingState == "bobbing" then
        love.graphics.print("WAITING FOR BITE: Watch for the bite message!", tutorialX, tutorialY)
        
        -- Show bite countdown (if available)
        if FishingSystem.getBiteTimer and FishingSystem.getBiteDelay then
            local biteTimer = FishingSystem:getBiteTimer()
            local biteDelay = FishingSystem:getBiteDelay()
            if biteTimer and biteDelay and biteDelay > 0 then
                local timeLeft = biteDelay - biteTimer
                if timeLeft > 0 then
                    love.graphics.print("Bite expected in: " .. string.format("%.1f", timeLeft) .. "s", tutorialX, tutorialY + 20)
                end
            end
        end
    elseif fishingState == "struggling" then
        love.graphics.print("STRUGGLING: Wait patiently! Don't press SPACE", tutorialX, tutorialY)
        
        -- Show struggling intensity if available
        if FishingSystem.getStrugglingIntensity then
            local intensity = FishingSystem:getStrugglingIntensity()
            if intensity then
                local intensityPercent = intensity / 100 -- Assuming max intensity is 100
                local barWidth = 200
                local barHeight = 15
                local barX = tutorialX
                local barY = tutorialY + 25
                
                -- Background bar
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
                
                -- Intensity bar (red when fish is fighting hard)
                love.graphics.setColor(1, 0.2 + intensityPercent * 0.6, 0.2, 0.9)
                love.graphics.rectangle("fill", barX, barY, barWidth * intensityPercent, barHeight)
                
                -- Border
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
                
                -- Label
                love.graphics.print("Fish Energy: " .. math.floor(intensityPercent * 100) .. "%", barX + barWidth + 10, barY)
            end
        end
        
    elseif fishingState == "reeling" then
        love.graphics.print("REELING: Keep pressing SPACE to reel in the fish!", tutorialX, tutorialY)
        
        -- Show reel progress bar
        local reelProgress = 0
        local maxProgress = 100
        if FishingSystem.getReelProgress then
            reelProgress = FishingSystem:getReelProgress() or 0
            maxProgress = FishingSystem:getMaxReelProgress() or 100
        end
        
        local progressPercent = reelProgress / maxProgress
        local progressBarWidth = 250
        local progressBarHeight = 20
        local progressBarX = tutorialX
        local progressBarY = tutorialY + 30
        
        -- Background bar
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth, progressBarHeight)
        
        -- Progress bar (green when making progress)
        love.graphics.setColor(0.2, 0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth * progressPercent, progressBarHeight)
        
        -- Border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", progressBarX, progressBarY, progressBarWidth, progressBarHeight)
        
        -- Progress text
        love.graphics.print("Progress: " .. math.floor(progressPercent * 100) .. "%", progressBarX + progressBarWidth + 10, progressBarY + 3)
        
        -- Show line stress indicator during reeling
        local lineStress = FishingSystem:getLineStress()
        local maxStress = FishingSystem:getMaxLineStress()
        if lineStress and maxStress then
            local stressPercent = lineStress / maxStress
            local barWidth = 200
            local barHeight = 15
            local barX = tutorialX
            local barY = tutorialY + 55
            
            -- Background bar
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
            
            -- Stress bar (changes color based on stress level)
            if stressPercent > 0.8 then
                love.graphics.setColor(1, 0.2, 0.2, 0.9) -- Red when dangerous
            elseif stressPercent > 0.5 then
                love.graphics.setColor(1, 0.8, 0.2, 0.9) -- Yellow when moderate
            else
                love.graphics.setColor(0.2, 1, 0.2, 0.9) -- Green when safe
            end
            love.graphics.rectangle("fill", barX, barY, barWidth * stressPercent, barHeight)
            
            -- Border
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
            
            -- Label
            love.graphics.print("Line Tension: " .. math.floor(stressPercent * 100) .. "%", barX + barWidth + 10, barY)
        end
        
    elseif fishingState == "waiting" then
        love.graphics.print("WAITING: Cast your line to begin fishing.", tutorialX, tutorialY)
    elseif fishingState == "idle" then
        love.graphics.print("WAITING: Cast your line to begin fishing.", tutorialX, tutorialY)
    end
end

function UI:drawTackleBox()
    if not self.showTackleBox then return end
    local VisualTacklebox = require("ui.visualtacklebox")
        
    VisualTacklebox:draw(require("fishing.fishing").getBaitInventory())
end

-- Tooltip for bait in tackle box
function UI:drawTackleBoxTooltip()
    if not self.showTackleBox then return end
    local VisualTacklebox = require("ui.visualtacklebox")
        
    local baitInventory = require("fishing.fishing").getBaitInventory()
    local selectedSlot = VisualTacklebox.getSelectedSlot and VisualTacklebox:getSelectedSlot() or 1
    local bait = baitInventory[selectedSlot]
    if bait and bait.description then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 40, love.graphics.getHeight() - 80, 320, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(bait.description, 50, love.graphics.getHeight() - 70, 300, "left")
    end
end

function UI:drawJournal()
    -- Always call Journal:drawUI() regardless of showJournal flag
    -- Journal module handles its own visibility with isOpen
    Journal:drawUI()
end

-- Sound cue for high tension
function UI:playTensionSound(stressRatio)
    if stressRatio > 0.8 then
        -- AudioManager removed
    end
end


-- Update drawAll to include buoy
function UI:drawAll()
    self:drawControls()
    self:drawWeather()
    self:drawSurvivalStats()
    self:drawFishingState()
    self:drawTackleBox()
    self:drawTackleBoxTooltip()
    -- Move journal to last so it draws in front
    self:drawJournal()
end

return UI
