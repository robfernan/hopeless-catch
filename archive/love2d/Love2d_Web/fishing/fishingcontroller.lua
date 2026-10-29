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
    
    if fishingState == "bobbing" then
        local biteResult = BiteDetection:update(dt, weatherData)
        if biteResult == "bite_missed" then
            self:resetToWaiting()
            StatisticsSystem:recordBiteMissed()
        end
    elseif fishingState == "struggling" then
        local struggleResult = ReelingSystem:updateStruggling(dt)
        print("DEBUG: updateStruggling returned:", struggleResult)
        if struggleResult == "line_break" then
            print("DEBUG: Line broke during struggling - player was too impatient!")
            self:handleLineBreak()
        elseif struggleResult == "start_reeling" then
            print("DEBUG: Fish is tired! Transitioning to reeling phase!")
            fishingState = "reeling"
            print("Now reel in the fish! Press SPACE to reel, but watch the line stress!")
        end
    elseif fishingState == "reeling" then
        local reelingResult = ReelingSystem:updateReeling(dt, currentCatch)
        if reelingResult == "line_break" then
            self:handleLineBreak()
        elseif reelingResult == "catch_success" then
            self:handleSuccessfulCatch()
        elseif reelingResult == "fish_escaped" then
            self:handleFishEscape()
        end
    end
end

function FishingController:startCasting()
    print("DEBUG: startCasting called, fishingState =", fishingState)
    if fishingState == "waiting" then
        local currentBait = BaitSystem:getCurrentBait()
        print("DEBUG: currentBait =", currentBait and currentBait.name or "nil")
        
        -- Auto-select first bait if none selected
        if not currentBait then
            print("DEBUG: No bait selected, auto-selecting worms")
            BaitSystem:selectBait(1)
            currentBait = BaitSystem:getCurrentBait()
        end
        
        if currentBait then
            local baitCount = BaitSystem:getBaitCount(currentBait.type)
            print("DEBUG: baitCount =", baitCount)
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
            StatisticsSystem:recordBaitUsed(currentBait)
            
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
    print("DEBUG: FishingController:toggleCasting called, fishingState =", fishingState)
    if fishingState == "waiting" then
        print("DEBUG: Calling startCasting()")
        return self:startCasting()
    elseif fishingState == "casting" then
        -- Get day/night cycle for finalizeCast
        local DayNightCycle = require("world.daynightcycle")
        print("DEBUG: Calling finalizeCast()")
        return self:finalizeCast(DayNightCycle)
    else
        print("DEBUG: Cannot toggle casting in state:", fishingState)
        return false
    end
end

function FishingController:attemptHookSet()
    print("DEBUG: attemptHookSet called, fishingState =", fishingState)
    print("DEBUG: currentCatch =", currentCatch and currentCatch.name or "nil")
    if fishingState == "bobbing" then
        local hookResult, reactionTime = BiteDetection:handleBiteAttempt()
        print("DEBUG: BiteDetection:handleBiteAttempt returned:", hookResult, reactionTime)
        if hookResult == "fish_hooked" then
            fishingState = "struggling"
            fightStartTime = love.timer.getTime()
            StatisticsSystem:recordReactionTime(reactionTime)
            ReelingSystem:startStruggling(currentCatch)
            print("✅ Fish hooked successfully! It's struggling!")
            print("DEBUG: State changed to 'struggling', waiting for fish to tire...")
            return true
        elseif hookResult == "bite_missed" then
            print("❌ Bite missed! Resetting to waiting...")
            self:resetToWaiting()
            StatisticsSystem:recordBiteMissed()
        elseif hookResult == "no_bite" then
            print("❌ No active bite to respond to!")
        end
    else
        print("DEBUG: Cannot attempt hook set in state:", fishingState)
    end
    return false
end

function FishingController:handleLineBreak()
    print("💔 Your line broke! The fish was too strong.")
    print("🐟 The " .. (currentCatch and currentCatch.name or "fish") .. " got away!")
    StatisticsSystem:recordLineBreak()
    self:resetToWaiting()
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
    
    -- Trigger the catch display UI
    local CatchDisplay = require("ui.catchdisplay")
    CatchDisplay:showCatch(currentCatch)
    
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
    print("DEBUG: ForceBite called")
    if fishingState == "bobbing" then
        BiteDetection:forceBite()
        print("DEBUG: Forced bite, state is still:", fishingState)
    end
end

-- Tackle box controls
function FishingController:openTackleBox()
    return BaitSystem:openTackleBox()
end

function FishingController:closeTackleBox()
    BaitSystem:closeTackleBox()
end

function FishingController:navigateTackleBox(direction)
    BaitSystem:navigate(direction)
end

function FishingController:selectBaitFromTackleBox()
    BaitSystem:selectCurrentBait()
end

-- Getters for UI and game state
function FishingController:getState()
    return fishingState
end

function FishingController:getCurrentCatch()
    return currentCatch
end

function FishingController:getCastingPower()
    return CastingSystem:getCastingPower()
end

function FishingController:isCasting()
    return CastingSystem:isCasting()
end

function FishingController:getBobberPosition()
    return CastingSystem:getBobberPosition()
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
    return StatisticsSystem:getTotalCatches()
end

function FishingController:getNightsCaught()
    return StatisticsSystem:getNightsCaught()
end

function FishingController:getLineStress()
    return ReelingSystem:getLineStress()
end

function FishingController:getMaxLineStress()
    return ReelingSystem:getMaxLineStress()
end

function FishingController:isFishPulling()
    return ReelingSystem:isFishPulling()
end

function FishingController:getReelProgress()
    return ReelingSystem:getReelProgress()
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
