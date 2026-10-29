-- fishing/reelingsystem.lua - Fish fighting and reeling mechanics
local ReelingSystem = {}

-- Reeling state
local lineStress = 0
local maxLineStress = 100
local reelProgress = 0
local maxReelProgress = 100
local fishPulling = false
local fishPullTimer = 0
local fishPullDuration = 2.0
local strugglingIntensity = 0
local fishResistance = 0

-- Dynamic tension (normalized 0..1+ range, where 1.0 = breaking point)
local tension = 0
local tensionFlashTimer = 0  -- for critical flashing effect

-- Thrash spike system (sudden tension surges for night/horror species)
local thrashActive = false
local thrashTimer = 0          -- remaining time in current thrash (seconds)
local thrashCooldown = 0      -- time until next thrash can trigger
local THRASH_DURATION = 0.5   -- each surge lasts 0.5 seconds
local THRASH_COOLDOWN_MIN = 2.0  -- minimum seconds between surges
local THRASH_COOLDOWN_MAX = 4.0  -- maximum seconds between surges
local thrashIntensity = 0     -- current spike magnitude added to tension

function ReelingSystem:init()
    lineStress = 0
    reelProgress = 0
    maxReelProgress = 100
    fishPulling = false
    fishPullTimer = 0
    fishPullDuration = 2.0
    strugglingIntensity = 0
    fishResistance = 0
    tension = 0
    tensionFlashTimer = 0
    thrashActive = false
    thrashTimer = 0
    thrashCooldown = math.random(THRASH_COOLDOWN_MIN, THRASH_COOLDOWN_MAX)
    thrashIntensity = 0
end

function ReelingSystem:startStruggling(currentCatch)
    if currentCatch then
        -- Make struggling much shorter - just a brief initial fight
        strugglingIntensity = (currentCatch.difficulty or 1) * math.random(3, 8) -- Much shorter: 3-8 seconds
        fishResistance = strugglingIntensity
        lineStress = 0
        reelProgress = 0
        fishPulling = false
        fishPullTimer = 0
        print("Fish hooked! Brief struggle before reeling...")
        print("Fish will tire quickly, then you can reel it in!")
        return true
    end
    return false
end

function ReelingSystem:updateStruggling(dt)
    -- Check if player is trying to reel during struggling (bad!)
    local playerReeling = love.keyboard.isDown("space")
    
    if playerReeling then
        -- Player is impatient - fish fights harder!
        strugglingIntensity = strugglingIntensity + dt * 5
        lineStress = lineStress + dt * 10
    else
        -- Patient waiting - fish gets tired naturally
        strugglingIntensity = math.max(0, strugglingIntensity - dt * 1.5) -- Normal tire rate when patient
        
        -- Line stress stays low when waiting patiently
        lineStress = math.max(0, lineStress - dt * 5) -- Actually reduce stress when waiting
    end
    

    
    -- Line stress should NOT break during struggling phase unless player is very impatient
    if lineStress >= maxLineStress then
        if playerReeling then
            print("💔 Your impatience broke the line! The fish was fighting too hard!")
            return "line_break"
        else
            print("The line is under stress, but holding...")
            lineStress = maxLineStress * 0.9 -- Keep it just below breaking
        end
    end
    
    -- Transition to reeling when fish is tired
    if strugglingIntensity <= 0 then
        print("Fish is tired! Now you can reel it in!")
        -- Reset line stress for fair start to reeling phase
        lineStress = math.min(20, lineStress) -- Start reeling with low stress
        return "start_reeling"
    end
    
    return "continue_struggling"
end

-- Horror/night species that trigger thrash spikes during reeling
local HORROR_SPECIES = {
    ["Pale Crawler"] = true,
    ["Bleeding Carp"] = true,
    ["Whispering Eel"] = true,
    ["Fishman"] = true
}

--- Check if the current catch is a horror species eligible for thrash spikes.
local function isHorrorSpecies(catch)
    return catch and HORROR_SPECIES[catch.name] == true
end

function ReelingSystem:updateReeling(dt, currentCatch)
    -- Check if currentCatch exists
    if not currentCatch then
        print("ERROR: No current catch data available in updateReeling")
        return "line_break" -- Exit reeling state if no catch data
    end
    
    -- Update tension flash timer (for critical flashing effect)
    tensionFlashTimer = tensionFlashTimer + dt
    
    -- Thrash spike system: random sudden tension surges for horror species
    local thrashTriggeredThisFrame = false
    if isHorrorSpecies(currentCatch) then
        if thrashActive then
            -- Active thrash: count down and apply intensity
            thrashTimer = thrashTimer - dt
            if thrashTimer <= 0 then
                thrashActive = false
                thrashIntensity = 0
                -- Schedule next thrash after a random cooldown
                thrashCooldown = math.random(THRASH_COOLDOWN_MIN, THRASH_COOLDOWN_MAX)
            end
        else
            -- Cooldown: count down until next surge can fire
            thrashCooldown = thrashCooldown - dt
            if thrashCooldown <= 0 then
                -- Trigger a sudden thrash spike!
                thrashActive = true
                thrashTimer = THRASH_DURATION
                thrashIntensity = math.random(0.25, 0.45)  -- adds 25-45% to tension
                thrashTriggeredThisFrame = true
            end
        end
    else
        -- Non-horror species: no thrash spikes (reset state)
        thrashActive = false
        thrashIntensity = 0
    end
    
    -- Update fish pulling behavior
    fishPullTimer = fishPullTimer + dt
    
    -- Fish pulls every 3-6 seconds based on difficulty
    local pullInterval = 3 + (currentCatch.difficulty or 1)
    if fishPullTimer > pullInterval then
        fishPulling = true
        fishPullTimer = 0
    end
    
    -- Fish pulling lasts 1-3 seconds based on difficulty
    if fishPulling then
        fishPullDuration = fishPullDuration - dt
        if fishPullDuration <= 0 then
            fishPulling = false
            fishPullDuration = 1 + (currentCatch.difficulty or 1) * 0.5
        end
    end
    
    -- Handle reeling input
    if love.keyboard.isDown("space") then
        if fishPulling then
            lineStress = lineStress + 40 * dt
        elseif lineStress < maxLineStress * 0.8 then
            local reelingSpeed = 15 - (currentCatch.difficulty or 1) * 2
            reelProgress = reelProgress + reelingSpeed * dt
            lineStress = lineStress + 6 * dt
        end
    else
        -- Fish pulls back when not reeling (slower fish pullback)
        local fishStrength = 8 + (currentCatch.difficulty or 1) * 1.5 -- Reduced fish strength
        if fishPulling then
            -- Fish pulls harder when actively pulling
            reelProgress = math.max(0, reelProgress - fishStrength * 1.5 * dt) -- Reduced pullback
        else
            reelProgress = math.max(0, reelProgress - fishStrength * 0.7 * dt) -- Much reduced passive pullback
        end
    end
    
    -- Reduce line stress over time when not reeling aggressively
    if not love.keyboard.isDown("space") or not fishPulling then
        lineStress = math.max(0, lineStress - 20 * dt)
    end
    
    -- Dynamic tension calculation:
    -- Tension is a normalized value (0..1+) combining base stress and active pull.
    -- It rises faster when the fish is pulling AND the player is reeling simultaneously,
    -- creating a risk/reward window for aggressive reeling.
    local baseTension = lineStress / maxLineStress
    local pullMultiplier = fishPulling and 1.3 or 1.0
    local targetTension = math.min(1.2, baseTension * pullMultiplier)
    
    -- Add thrash spike intensity (sudden surge for horror species)
    if thrashActive then
        targetTension = math.min(1.25, targetTension + thrashIntensity)
    end
    
    -- Smooth interpolation toward target (avoids jarring jumps)
    -- During an active thrash, use a faster lerp for a snappier spike feel
    local tensionLerpSpeed = thrashActive and 14.0 or 8.0
    tension = tension + (targetTension - tension) * math.min(1, tensionLerpSpeed * dt)
    
    -- Check for line break (tension exceeds 100%)
    if tension >= 1.0 then
        print("The line snapped! The fish was too strong!")
        return "line_break"
    end
    
    -- Check for successful catch
    if reelProgress >= 100 then
        return "catch_success"
    end
    
    -- Check if fish escaped (only if they had progress and lost it all)
    -- Removed the immediate escape check - give player a fair chance to start reeling
    
    -- Return thrash flag so the controller can trigger screen shake
    if thrashTriggeredThisFrame then
        return "continue_reeling_thrash"
    end
    
    return "continue_reeling"
end

function ReelingSystem:pullLine()
    lineStress = math.max(0, lineStress - 15)
    strugglingIntensity = math.max(0, strugglingIntensity - 10)
    print("Pulling line! Fish struggle: " .. math.floor(strugglingIntensity))
end

function ReelingSystem:manualReel()
    if lineStress < maxLineStress * 0.8 then
        reelProgress = reelProgress + 5
        lineStress = lineStress + 3
        print("Reeling... " .. math.floor(reelProgress) .. "%")
    end
end

--- Get the current dynamic tension (0..1+ range).
-- 0.0 = slack, 0.7 = high, 1.0 = breaking point.
function ReelingSystem:getTension()
    return tension
end

--- Get the line color for rendering based on current tension level.
-- Returns r, g, b values (0..1) ready for love.graphics.setColor().
--   Safe zone   (tension < 0.5):  green (0, 1, 0)
--   High zone   (0.5 <= t < 0.8): yellow (1, 1, 0)
--   Critical    (t >= 0.8):       flashing red (1, 0, 0) with oscillation
function ReelingSystem:getTensionColor()
    if tension < 0.5 then
        -- Safe: solid green
        return 0, 1, 0
    elseif tension < 0.8 then
        -- High: interpolate green -> yellow
        local t = (tension - 0.5) / 0.3  -- 0..1 within this band
        local r = t          -- 0 -> 1
        local g = 1          -- stays 1
        return r, g, 0
    else
        -- Critical: flashing red (oscillate brightness)
        local flash = 0.5 + 0.5 * math.sin(tensionFlashTimer * 12)  -- ~2Hz flash
        return 1, flash * 0.3, flash * 0.1
    end
end

--- Check if tension is in the critical (flashing red) zone.
function ReelingSystem:isTensionCritical()
    return tension >= 0.8
end

--- Query whether a thrash spike is currently active.
-- Returns (isActive, intensity) where intensity is the added tension magnitude.
function ReelingSystem:getThrashState()
    if not thrashActive then return false, 0 end
    local remaining = math.max(0, thrashTimer / THRASH_DURATION)
    return true, thrashIntensity * remaining
end

-- Getters
function ReelingSystem:getLineStress()
    return lineStress
end

function ReelingSystem:getMaxLineStress()
    return maxLineStress
end

function ReelingSystem:getReelProgress()
    return reelProgress
end

function ReelingSystem:getMaxReelProgress()
    return maxReelProgress or 100
end

function ReelingSystem:isFishPulling()
    return fishPulling
end

function ReelingSystem:getStrugglingIntensity()
    return strugglingIntensity
end

return ReelingSystem
