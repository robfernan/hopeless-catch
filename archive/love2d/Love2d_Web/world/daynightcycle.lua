-- DayNightCycle.lua - Manages day/night transitions and lighting
local DayNightCycle = {}

local timeOfDay = 0 -- 0 = midnight, 0.5 = noon, 1 = midnight again
local cycleSpeed = 0.0007 -- How fast time passes - Full cycle ~24 minutes (much slower)
local lightingCanvas
local ambientColor = {1, 1, 1, 1}
local isNight = false
local nightTransitionCooldown = 0
local NIGHT_TRANSITION_COOLDOWN_TIME = 2 -- seconds
local timeScale = 1.0 -- Always use recommended default timing
local currentDay = 1 -- Track which day we're on
local lastTimeOfDay = 0 -- Track previous time to detect day changes

-- Time phases
local phases = {
    {name = "Night", start = 0, r = 0.1, g = 0.1, b = 0.3},
    {name = "Dawn", start = 0.2, r = 0.8, g = 0.4, b = 0.2},
    {name = "Morning", start = 0.3, r = 1, g = 1, b = 0.9},
    {name = "Day", start = 0.4, r = 1, g = 1, b = 1},
    {name = "Evening", start = 0.7, r = 1, g = 0.7, b = 0.4},
    {name = "Dusk", start = 0.8, r = 0.4, g = 0.2, b = 0.6},
    {name = "Night", start = 0.9, r = 0.1, g = 0.1, b = 0.3}
}

function DayNightCycle:init()
    lightingCanvas = love.graphics.newCanvas(love.graphics.getDimensions())
    timeOfDay = 0.3 -- Start in morning
    self:updateAmbientColor()
    self.preloadedPhase = nil
end

function DayNightCycle:preloadNextPhase()
    -- Find next phase that we'll transition to
    local nextTime = timeOfDay + cycleSpeed * timeScale * 0.5
    if nextTime >= 1 then nextTime = nextTime - 1 end
    
    local nextPhase = nil
    for i, phase in ipairs(phases) do
        if nextTime >= phase.start and (i == #phases or nextTime < phases[i + 1].start) then
            nextPhase = phase
            break
        end
    end
    
    -- Preload if it's different from current
    if nextPhase and nextPhase ~= self.preloadedPhase then
        self.preloadedPhase = nextPhase
        collectgarbage("collect")  -- Help prevent stuttering
    end
end

function DayNightCycle:update(dt)
    -- Store previous time to detect day changes
    lastTimeOfDay = timeOfDay
    
    -- Advance time with smoother timing
    timeOfDay = (timeOfDay + cycleSpeed * timeScale * dt) % 1
    
    -- Check if we've crossed midnight (new day)
    if lastTimeOfDay > timeOfDay then
        currentDay = currentDay + 1
        self:onNewDay()
    end
    
    -- Preload any resources needed for next phase
    self:preloadNextPhase()
    
    -- Update ambient lighting with interpolation
    self:updateAmbientColor()
    
    -- Smooth night transition check
    local wasNight = isNight
    local newIsNight = timeOfDay < 0.3 or timeOfDay > 0.8
    
    -- Only update night state after cooldown
    if nightTransitionCooldown <= 0 then
        if wasNight ~= newIsNight then
            nightTransitionCooldown = NIGHT_TRANSITION_COOLDOWN_TIME
            isNight = newIsNight
        end
    else
        nightTransitionCooldown = nightTransitionCooldown - dt
    end
    
    -- Trigger night transition events instantly for fluid transitions
    if not wasNight and isNight then
        self:onNightFall()
    elseif wasNight and not isNight then
        self:onDayBreak()
    end
end

function DayNightCycle:updateAmbientColor()
    -- Find current phase
    local currentPhase = phases[1]
    for i = #phases, 1, -1 do
        if timeOfDay >= phases[i].start then
            currentPhase = phases[i]
            break
        end
    end
    
    -- Find next phase for interpolation
    local nextPhaseIndex = 1
    for i = 1, #phases do
        if phases[i].start > timeOfDay then
            nextPhaseIndex = i
            break
        end
    end
    
    local nextPhase = phases[nextPhaseIndex]
    
    -- Interpolate colors
    local progress = 0
    if nextPhase.start > currentPhase.start then
        progress = (timeOfDay - currentPhase.start) / (nextPhase.start - currentPhase.start)
    end
    
    progress = math.min(1, math.max(0, progress))
    
    ambientColor[1] = currentPhase.r + (nextPhase.r - currentPhase.r) * progress
    ambientColor[2] = currentPhase.g + (nextPhase.g - currentPhase.g) * progress
    ambientColor[3] = currentPhase.b + (nextPhase.b - currentPhase.b) * progress
    ambientColor[4] = 1
end

function DayNightCycle:beginLighting()
    love.graphics.push("all")
    love.graphics.setColor(ambientColor)
end

function DayNightCycle:endLighting()
    love.graphics.pop()
end

function DayNightCycle:drawTimeIndicator()
    -- Draw time indicator UI
    local x, baseY = 10, love.graphics.getHeight() - 140
    local boxWidth, boxHeight = 220, 120
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 5, baseY - 5, boxWidth, boxHeight)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Day: " .. tostring(currentDay), x, baseY)
    love.graphics.print("Time: " .. self:getTimeString(), x, baseY + 20)
    love.graphics.print("Phase: " .. self:getCurrentPhase(), x, baseY + 40)
    love.graphics.print("Speed: " .. string.format("%.1fx", timeScale), x, baseY + 60)

    -- Day/night progress bar (moved to speed bar position, no speed bar)
    local barY = baseY + 85
    local barWidth = 120
    local barHeight = 10
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", x, barY, barWidth, barHeight)
    love.graphics.setColor(1, 1, 0.8, 1) -- Day color
    love.graphics.rectangle("fill", x + barWidth * 0.3, barY, barWidth * 0.5, barHeight)
    love.graphics.setColor(0.1, 0.1, 0.3, 1) -- Night color
    love.graphics.rectangle("fill", x, barY, barWidth * 0.3, barHeight)
    love.graphics.rectangle("fill", x + barWidth * 0.8, barY, barWidth * 0.2, barHeight)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", x + barWidth * timeOfDay - 2, barY - 2, 4, barHeight + 4)
end

function DayNightCycle:getCurrentPhase()
    for i = #phases, 1, -1 do
        if timeOfDay >= phases[i].start then
            return phases[i].name
        end
    end
    return phases[1].name
end

function DayNightCycle:isNightTime()
    -- Direct time check instead of relying on isNight flag
    return timeOfDay < 0.3 or timeOfDay > 0.8
end

function DayNightCycle:getTimeOfDay()
    return timeOfDay
end

function DayNightCycle:setTime(time)
    timeOfDay = math.max(0, math.min(1, time))
    self:updateAmbientColor()
end

function DayNightCycle:onNightFall()
    print("Night falls... the horror begins...")
    -- Horror events disabled - no horrorevents module
    -- Audio disabled - no audiomanager module
end

function DayNightCycle:onDayBreak()
    print("Dawn breaks... safety returns...")
    -- Audio disabled - no audiomanager module
end

function DayNightCycle:onNewDay()
    print("A new day begins... Day " .. currentDay)
    -- Horror events disabled - no horrorevents module
end

-- Debug/Testing functions for time control
function DayNightCycle:setTimeScale(scale)
    timeScale = math.max(0, scale)
end

function DayNightCycle:getTimeScale()
    return timeScale
end

function DayNightCycle:pauseTime()
    timeScale = 0
end

function DayNightCycle:resumeTime()
    timeScale = 1.0
end

function DayNightCycle:fastForward(scale)
    timeScale = scale or 5.0
end

-- Get readable time format
function DayNightCycle:getTimeString()
    local hours = math.floor(timeOfDay * 24)
    local minutes = math.floor((timeOfDay * 24 * 60) % 60)
    return string.format("%02d:%02d", hours, minutes)
end

-- Get current day number
function DayNightCycle:getCurrentDay()
    return currentDay
end

-- Set day number (for save/load functionality)
function DayNightCycle:setCurrentDay(day)
    currentDay = day or 1
end

-- Advance to next day (for cabin sleep)
function DayNightCycle:advanceToNextDay()
    currentDay = currentDay + 1
    print("📅 Advanced to Day " .. currentDay)
end

return DayNightCycle
