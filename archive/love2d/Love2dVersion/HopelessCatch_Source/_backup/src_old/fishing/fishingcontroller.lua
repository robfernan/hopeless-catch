-- fishing/fishingcontroller.lua - Main controller that coordinates all fishing modules
local FishingController = {}

-- Import all fishing modules
local FishData = require("fishing.fishdata")
local BaitSystem = require("fishing.baitsystem")
local CastingSystem = require("fishing.castingsystem")
local ReelingSystem = require("fishing.reelingsystem")
local BiteDetection = require("fishing.bitedetection")
local StatisticsSystem = require("fishing.statisticssystem")
local Player = require("player")

-- Fishing state management
local fishingState = "waiting" -- waiting, casting, bobbing, biting, struggling, reeling, caught
local currentCatch = nil
local fightStartTime = 0

function FishingController:init()
    BaitSystem:init()
    CastingSystem:init()
    ReelingSystem:init()
    BiteDetection:init()
    StatisticsSystem:init()
    fishingState = "waiting"
    currentCatch = nil
    print("Fishing Controller initialized - All systems ready!")
end

function FishingController:update(dt, weatherData, dayNightCycle)
    -- Update all systems
    CastingSystem:update(dt, weatherData, fishingState)
    
    -- Auto-finalize cast when power oscillation completes a full cycle (reaches 0 going down)
    if fishingState == "casting" then
        local power = CastingSystem:getCastPower()
        if power <= 0.01 and CastingSystem.isCastingDown and CastingSystem:isCastingDown() then
            self:finalizeCast(dayNightCycle)
        end
    end
    
    if fishingState == "bobbing" then
        local biteResult = BiteDetection:update(dt, weatherData)
        if biteResult == "bite_missed" then
            self:resetToWaiting()
            StatisticsSystem:recordBiteMissed()
        end
    elseif fishingState == "struggling" then
        local struggleResult = ReelingSystem:updateStruggling(dt)
        if struggleResult == "line_break" then
            self:handleLineBreak()
        elseif struggleResult == "start_reeling" then
            fishingState = "reeling"
            print("🎣 Fish is tired! Now reel it in - press SPACE to reel!")
        end
    elseif fishingState == "reeling" then
        local reelingResult = ReelingSystem:updateReeling(dt, currentCatch)
        if reelingResult == "line_break" then
            self:handleLineBreak()
        elseif reelingResult == "catch_success" then
            self:handleSuccessfulCatch()
        elseif reelingResult == "fish_escaped" then
            self:handleFishEscape()
        elseif reelingResult == "continue_reeling_thrash" then
            -- Thrash spike just triggered: quick screen shake for visual impact
            if _G.addScreenShake then
                local _, intensity = ReelingSystem:getThrashState()
                local shakeMag = 4 + (intensity or 0.3) * 10  -- scale with thrash power
                _G.addScreenShake(0.25, shakeMag)
            end
        end
    end
end

function FishingController:startCasting()
    if fishingState == "waiting" then
        local currentBait = BaitSystem:getCurrentBait()
        
        -- Auto-select first bait if none selected
        if not currentBait then
            BaitSystem:selectBait(1)
            currentBait = BaitSystem:getCurrentBait()
        end
        
        if currentBait then
            local baitCount = BaitSystem:getBaitCount(currentBait.type)
            if baitCount > 0 then
                fishingState = "casting"
                CastingSystem:startCasting()
                print("Started casting with " .. currentBait.name .. "...")
                return true
            end
        end
        print("No bait selected or out of bait!")
        return false
    else
        print("DEBUG: Not in waiting state, current state:", fishingState)
        return false
    end
end

function FishingController:finalizeCast(dayNightCycle)
    if fishingState == "casting" then
        local castPower = CastingSystem:getCastPower()
        local rodX, rodY = Player:getPosition()
        local currentBait = BaitSystem:getCurrentBait()
        
        -- Perform the cast
        local castSuccess = CastingSystem:cast(rodX, rodY, currentBait)
        
        if castSuccess and castPower > 0 then
            -- Use bait
            BaitSystem:useBait(currentBait)
            StatisticsSystem:recordCast()
            StatisticsSystem:recordBaitUsed(currentBait.type)
            
            -- Determine what fish might bite based on time and bait
            currentCatch = FishData:selectFish(dayNightCycle, currentBait)
            
            -- Start bite detection
            fishingState = "bobbing"
            BiteDetection:startBiteTimer()
            
            print("Cast completed! Waiting for a bite...")
            return true
        else
            self:resetToWaiting()
        end
    end
    return false
end

function FishingController:toggleCasting()
    if fishingState == "waiting" then
        return self:startCasting()
    elseif fishingState == "casting" then
        local DayNightCycle = require("world.daynightcycle")
        return self:finalizeCast(DayNightCycle)
    else
        return false
    end
end

function FishingController:attemptHookSet()
    if fishingState == "bobbing" then
        local hookResult, reactionTime = BiteDetection:handleBiteAttempt()
        if hookResult == "fish_hooked" then
            fishingState = "struggling"
            fightStartTime = love.timer.getTime()
            StatisticsSystem:recordReactionTime(reactionTime)
            ReelingSystem:startStruggling(currentCatch)
            print("✅ Fish hooked! Wait for it to tire, then reel!")
            return true
        elseif hookResult == "bite_missed" then
            self:resetToWaiting()
            StatisticsSystem:recordBiteMissed()
        end
    end
    return false
end

function FishingController:handleLineBreak()
    local fishName = (currentCatch and currentCatch.name) or "fish"
    print("💔 Your line broke! The fish was too strong.")
    print("🐟 The " .. fishName .. " got away!")
    
    -- Line snap visual/audio effect
    self:playLineSnapEffect()
    
    StatisticsSystem:recordLineBreak()
    self:resetToWaiting()
end

--- Play the line-snap feedback: screen shake + optional sound.
-- Called when tension exceeds 100% and the line breaks.
function FishingController:playLineSnapEffect()
    -- Screen shake (uses the global addScreenShake defined in main.lua)
    if _G.addScreenShake then
        _G.addScreenShake(0.4, 8)  -- 0.4s duration, intensity 8
    end
    
    -- Play snap sound if available (non-fatal if missing)
    local Assets = require("assets")
    local snapSound = nil
    if type(Assets.getSound) == "function" then
        snapSound = Assets:getSound("sound_line_snap")
    end
    if snapSound then
        snapSound:play()
    else
        print("🎵 [line snap sound - add assets/audio/line_snap.ogg for audio feedback]")
    end
end

function FishingController:handleSuccessfulCatch()
    local fightDuration = love.timer.getTime() - fightStartTime
    print("🎉 You caught a " .. (currentCatch.name or "fish") .. "!")
    print("Fight duration: " .. string.format("%.1f", fightDuration) .. " seconds")
    
    StatisticsSystem:recordCatch(currentCatch.type, fightDuration)
    
    -- Show catch details
    print("Fish details:")
    print("  Type: " .. (currentCatch.name or "Unknown"))
    print("  Difficulty: " .. (currentCatch.difficulty or 1) .. "/5")
    if currentCatch.rarity then
        print("  Rarity: " .. currentCatch.rarity)
    end
    
    -- Trigger the catch display UI (ImGui and legacy)
    local CatchDisplay = require("ui.catchdisplay")
    CatchDisplay:showCatch(currentCatch)
    local CatchDisplayUI = require("ui.imgui.catchdisplay")
    CatchDisplayUI:show(currentCatch)
    
    -- Record catch in journal
    local Journal = require("ui.journal")
    local DayNightCycle = require("world.daynightcycle")
    local currentDay = DayNightCycle:getCurrentDay() or 1
    Journal:addCatch(currentDay, currentCatch.name, currentCatch)
    
    self:resetToWaiting()
end

function FishingController:handleFishEscape()
    print("The fish escaped! Better luck next time.")
    StatisticsSystem:recordFishEscaped()
    self:resetToWaiting()
end

function FishingController:resetToWaiting()
    fishingState = "waiting"
    currentCatch = nil
    CastingSystem:init()
    ReelingSystem:init()
    BiteDetection:init()
    fightStartTime = 0
end

-- Manual controls for advanced players
function FishingController:pullLine()
    if fishingState == "struggling" then
        ReelingSystem:pullLine()
    end
end

function FishingController:manualReel()
    if fishingState == "reeling" then
        ReelingSystem:manualReel()
    end
end

function FishingController:forceBite()
    if fishingState == "bobbing" then
        BiteDetection:forceBite()
    end
end

-- Tackle box controls
function FishingController:openTackleBox()
    return BaitSystem:toggleTacklebox()
end

function FishingController:closeTackleBox()
    if BaitSystem:isTackleboxOpen() then
        BaitSystem:toggleTacklebox()
    end
end

function FishingController:navigateTackleBox(direction)
    if direction == "up" then
        BaitSystem:navigateTackleboxUp()
    elseif direction == "down" then
        BaitSystem:navigateTackleboxDown()
    end
end

function FishingController:selectBaitFromTackleBox()
    BaitSystem:selectTackleboxBait()
end

-- Getters for UI and game state
function FishingController:setState(state)
    local validStates = {waiting = true, casting = true, bobbing = true, struggling = true, reeling = true}
    if validStates[state] then
        fishingState = state
    end
end

function FishingController:getState()
    return fishingState
end

function FishingController:getCurrentCatch()
    return currentCatch
end

function FishingController:getCastingPower()
    return CastingSystem:getCastPower()
end

function FishingController:isCasting()
    return fishingState == "casting"
end

function FishingController:getBobberPosition()
    return CastingSystem:getBobberPosition()
end

function FishingController:getTension()
    return ReelingSystem:getTension()
end

function FishingController:getTensionColor()
    return ReelingSystem:getTensionColor()
end

function FishingController:isTensionCritical()
    return ReelingSystem:isTensionCritical()
end

function FishingController:getLineStress()
    return ReelingSystem:getLineStress()
end

function FishingController:getMaxLineStress()
    return ReelingSystem:getMaxLineStress()
end

function FishingController:getReelProgress()
    return ReelingSystem:getReelProgress()
end

function FishingController:isFishPulling()
    return ReelingSystem:isFishPulling()
end

function FishingController:isBiting()
    return BiteDetection:isBiting()
end

function FishingController:getBiteTimeRemaining()
    return BiteDetection:getBiteTimeRemaining()
end

function FishingController:getBiteTimer()
    return BiteDetection:getBiteTimer()
end

function FishingController:getBiteDelay()
    return BiteDetection:getBiteDelay()
end

function FishingController:getCurrentBait()
    return BaitSystem:getCurrentBait()
end

function FishingController:getBaitInventory()
    return BaitSystem:getBaitInventory()
end

function FishingController:selectBait(index)
    return BaitSystem:selectBait(index)
end

function FishingController:getCastPower()
    return CastingSystem:getCastPower()
end

function FishingController:getTotalCatches()
    local stats = StatisticsSystem:getStatistics()
    return stats.totalCatches or 0
end

function FishingController:getNightsCaught()
    -- Count night fish caught from statistics
    local stats = StatisticsSystem:getStatistics()
    local count = 0
    if stats.fishCaughtByType then
        count = (stats.fishCaughtByType.pale_crawler or 0) +
                (stats.fishCaughtByType.bleeding_carp or 0) +
                (stats.fishCaughtByType.whispering_eel or 0) +
                (stats.fishCaughtByType.fishman or 0)
    end
    return count
end

function FishingController:getMaxReelProgress()
    return ReelingSystem:getMaxReelProgress()
end

function FishingController:getStrugglingIntensity()
    return ReelingSystem:getStrugglingIntensity()
end

function FishingController:getBaitCount(baitType)
    return BaitSystem:getBaitCount(baitType)
end

function FishingController:isTackleBoxOpen()
    return BaitSystem:isTackleBoxOpen()
end

function FishingController:getTackleBoxState()
    return BaitSystem:getTackleBoxState()
end

function FishingController:getStatistics()
    return StatisticsSystem:getStatistics()
end

function FishingController:printSessionSummary()
    StatisticsSystem:printSessionSummary()
end

return FishingController
