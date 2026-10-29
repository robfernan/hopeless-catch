-- fishing/bitedetection.lua - Bite detection and timing mechanics
local BiteDetection = {}

-- Bite timing state
local biteTimer = 0
local biteDelay = 0
local hasBite = false
local biteStartTime = 0
local biteWindow = 5.0 -- seconds to react (increased from 3.0 for easier response)
local fishOnHook = false

function BiteDetection:init()
    biteTimer = 0
    biteDelay = 0
    hasBite = false
    biteStartTime = 0
    biteWindow = 3.0
    fishOnHook = false
end

function BiteDetection:startBiteTimer()
    -- Random delay between 2-8 seconds (shorter for testing)
    biteDelay = math.random(2, 8)
    biteTimer = 0
    hasBite = false
    fishOnHook = false
    print("Waiting for a bite... (will happen in " .. biteDelay .. " seconds)")
end

function BiteDetection:update(dt, weatherData)
    if not hasBite and not fishOnHook then
        biteTimer = biteTimer + dt
        
        -- Weather affects bite timing
        local weatherMultiplier = 1.0
        if weatherData then
            if weatherData.isRaining then
                weatherMultiplier = 0.7 -- Fish bite more frequently in rain
            elseif weatherData.windSpeed and weatherData.windSpeed > 15 then
                weatherMultiplier = 1.3 -- Fish bite less in high wind
            end
        end
        
        local adjustedDelay = biteDelay * weatherMultiplier
        
        if biteTimer >= adjustedDelay then
            hasBite = true
            biteStartTime = love.timer.getTime()
            print("🎣 You got a bite! Press SPACE quickly!")
            print("DEBUG: Bite detected, hasBite =", hasBite, "biteStartTime =", biteStartTime)
            
            -- Simple audio cue for bite (you could replace this with actual sound file)
            -- love.audio.newSource("path/to/bite_sound.wav", "static"):play()
            
            -- Screen shake effect for dramatic bite
            if _G.addScreenShake then
                _G.addScreenShake(0.1, 5)
            end
        end
    elseif hasBite and not fishOnHook then
        -- Check if player missed the bite window
        local currentTime = love.timer.getTime()
        local elapsedTime = currentTime - biteStartTime
        if elapsedTime > biteWindow then
            print("The fish got away! You were too slow. (Elapsed:", string.format("%.2f", elapsedTime), "s)")
            hasBite = false  -- Reset the bite state
            return "bite_missed"
        end
    end
    
    return "waiting"
end

function BiteDetection:handleBiteAttempt()
    if hasBite and not fishOnHook then
        local currentTime = love.timer.getTime()
        local reactionTime = currentTime - biteStartTime
        
        if reactionTime <= biteWindow then
            fishOnHook = true
            hasBite = false
            print("Fish hooked! Reaction time: " .. string.format("%.2f", reactionTime) .. "s")
            return "fish_hooked", reactionTime
        else
            print("Too late! The fish got away.")
            return "bite_missed", reactionTime
        end
    end
    
    return "no_bite", 0
end

function BiteDetection:isBiting()
    local result = hasBite and not fishOnHook
    print("DEBUG: isBiting() called - hasBite:", hasBite, "fishOnHook:", fishOnHook, "result:", result)
    if hasBite then
        local currentTime = love.timer.getTime()
        local timeRemaining = biteWindow - (currentTime - biteStartTime)
        print("DEBUG: Bite window time remaining:", timeRemaining)
    end
    return result
end

function BiteDetection:isFishOnHook()
    return fishOnHook
end

function BiteDetection:getBiteTimeRemaining()
    if hasBite then
        local currentTime = love.timer.getTime()
        return math.max(0, biteWindow - (currentTime - biteStartTime))
    end
    return 0
end

function BiteDetection:getBiteTimer()
    return biteTimer
end

function BiteDetection:getBiteDelay()
    return biteDelay
end

function BiteDetection:forceBite()
    hasBite = true
    biteStartTime = love.timer.getTime()
    fishOnHook = false
    print("DEBUG: Forced bite - hasBite:", hasBite, "biteStartTime:", biteStartTime)
end

return BiteDetection
