-- fishing/reelingsystem.lua - Fish fighting and reeling mechanics
local ReelingSystem = {}

-- Reeling state
local lineStress = 0
local maxLineStress = 100
local reelProgress = 0
local fishPulling = false
local fishPullTimer = 0
local fishPullDuration = 2.0
local strugglingIntensity = 0
local fishResistance = 0

function ReelingSystem:init()
    lineStress = 0
    reelProgress = 0
    fishPulling = false
    fishPullTimer = 0
    fishPullDuration = 2.0
    strugglingIntensity = 0
    fishResistance = 0
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
    
    local oldIntensity = strugglingIntensity
    
    if playerReeling then
        -- Player is impatient - fish fights harder!
        strugglingIntensity = strugglingIntensity + dt * 5 -- Fish gets MORE energized
        print("🐟 Fish fights harder because you're pulling!")
        
        -- Add line stress when pulling during struggling
        lineStress = lineStress + dt * 10 -- Much higher stress when fighting struggling fish
    else
        -- Patient waiting - fish gets tired naturally
        strugglingIntensity = math.max(0, strugglingIntensity - dt * 1.5) -- Normal tire rate when patient
        
        -- Line stress stays low when waiting patiently
        lineStress = math.max(0, lineStress - dt * 5) -- Actually reduce stress when waiting
    end
    
    -- Debug output
    if math.floor(oldIntensity) ~= math.floor(strugglingIntensity) and strugglingIntensity % 2 < 1 then
        if playerReeling then
            print("Fish struggling harder due to impatience... intensity:", math.floor(strugglingIntensity))
        else
            print("Fish getting tired from waiting... intensity:", math.floor(strugglingIntensity))
        end
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

function ReelingSystem:updateReeling(dt, currentCatch)
    -- Check if currentCatch exists
    if not currentCatch then
        print("ERROR: No current catch data available in updateReeling")
        return "line_break" -- Exit reeling state if no catch data
    end
    
    -- Update fish pulling behavior
    fishPullTimer = fishPullTimer + dt
    
    -- Fish pulls every 3-6 seconds based on difficulty
    local pullInterval = 3 + (currentCatch.difficulty or 1)
    if fishPullTimer > pullInterval then
        fishPulling = true
        fishPullTimer = 0
        print("Fish is pulling hard! Stop reeling!")
    end
    
    -- Fish pulling lasts 1-3 seconds based on difficulty
    if fishPulling then
        fishPullDuration = fishPullDuration - dt
        if fishPullDuration <= 0 then
            fishPulling = false
            fishPullDuration = 1 + (currentCatch.difficulty or 1) * 0.5
            print("Fish stopped pulling, continue reeling!")
        end
    end
    
    -- Handle reeling input
    if love.keyboard.isDown("space") then
        if fishPulling then
            -- Reeling while fish pulls increases line stress dramatically
            lineStress = lineStress + 40 * dt
            print("⚠️ Fish is pulling! You're adding too much stress!")
        elseif lineStress < maxLineStress * 0.8 then
            -- Normal reeling (slower pace for better gameplay)
            local reelingSpeed = 15 - (currentCatch.difficulty or 1) * 2 -- Much slower, harder fish are even slower
            reelProgress = reelProgress + reelingSpeed * dt
            lineStress = lineStress + 6 * dt -- Less line stress buildup
        else
            print("Line stress too high! Stop reeling!")
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
    
    -- Check for line break
    if lineStress >= maxLineStress then
        print("The line snapped! The fish was too strong!")
        return "line_break"
    end
    
    -- Check for successful catch
    if reelProgress >= 100 then
        return "catch_success"
    end
    
    -- Check if fish escaped (only if they had progress and lost it all)
    -- Removed the immediate escape check - give player a fair chance to start reeling
    
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
    return maxReelProgress
end

function ReelingSystem:isFishPulling()
    return fishPulling
end

function ReelingSystem:getStrugglingIntensity()
    return strugglingIntensity
end

return ReelingSystem
