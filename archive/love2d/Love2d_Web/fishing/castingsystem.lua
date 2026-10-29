-- fishing/castingsystem.lua - Casting mechanics and power system
local CastingSystem = {}

-- Import required modules
local Weather = require("world.weather")

-- Casting state
local castDistance = 0
local maxCastDistance = 200
local castPower = 0
local castingUp = true
local bobberX, bobberY = 0, 0
local particles = {}

function CastingSystem:init()
    castDistance = 0
    castPower = 0
    castingUp = true
    bobberX, bobberY = 0, 0
    particles = {}
end

function CastingSystem:update(dt, weatherData, fishingState)
    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt -- Gravity
        p.alpha = p.alpha - dt * 2
        
        if p.life <= 0 or p.alpha <= 0 then
            table.remove(particles, i)
        end
    end
    
    -- Update casting power if in casting state
    if fishingState == "casting" then
        self:updateCastingPower(dt)
    end
end

function CastingSystem:updateCastingPower(dt)
    -- Build up cast power with timing
    if castingUp then
        castPower = castPower + dt * 1.5
        if castPower >= 1 then
            castPower = 1
            castingUp = false
        end
    else
        castPower = castPower - dt * 1.5
        if castPower <= 0 then
            castPower = 0
            castingUp = true
        end
    end
end

function CastingSystem:startCasting()
    castPower = 0
    castingUp = true
    print("Hold and release SPACE for power...")
end

function CastingSystem:cast(rodX, rodY, currentBait)
    if not currentBait then
        print("Select bait first! Press B for tackle box.")
        return false
    end
    
    castDistance = castPower * maxCastDistance
    
    -- Apply weather effects
    local weatherData = Weather:getWeatherData()
    local windEffect = Weather:getWindEffect()
    
    castDistance = castDistance * weatherData.castingAccuracy
    
    -- Calculate bobber position
    local angle = -math.pi/2
    local windOffset = windEffect.strength * 30 * math.cos(windEffect.direction)
    
    bobberX = rodX + math.cos(angle) * castDistance * 0.4 + windOffset
    bobberY = rodY + 120 + math.sin(angle) * castDistance * 0.2
    
    -- Create splash effect
    self:createSplashEffect(bobberX, bobberY)
    
    -- Cast feedback
    if castPower > 0.8 then
        print("Perfect cast!")
    elseif castPower > 0.5 then
        print("Good cast!")
    else
        print("Weak cast...")
    end
    
    return true
end

function CastingSystem:createSplashEffect(x, y)
    for i = 1, 8 do
        local particle = {
            x = x + math.random(-10, 10),
            y = y + math.random(-5, 5),
            vx = (math.random() - 0.5) * 100,
            vy = -math.random(30, 80),
            life = math.random() * 1.5 + 0.5,
            alpha = 1.0,
            size = math.random(2, 6)
        }
        table.insert(particles, particle)
    end
end

-- Drawing Functions
function CastingSystem:draw(rodX, rodY, fishingState, isBiting)
    -- Draw particles
    for _, p in ipairs(particles) do
        love.graphics.setColor(0.6, 0.8, 1, p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    if fishingState == "idle" then
        return
    end
    
    if fishingState == "casting" then
        -- Draw fishing line for casting arc
        love.graphics.setColor(0.8, 0.8, 0.6, 0.8) -- Light fishing line color
        love.graphics.setLineWidth(1.5)
        
        -- Show casting power with a curved arc
        local power = castPower * maxCastDistance * 0.5
        local angle = math.rad(-45) -- 45-degree casting angle
        
        -- Draw predicted cast arc
        local segments = 15
        local prevX, prevY = rodX, rodY
        
        for i = 1, segments do
            local t = i / segments
            local x = rodX + math.cos(angle) * power * t
            local y = rodY + math.sin(angle) * power * t + (t * t * 50) -- Gravity curve
            
            if i == 1 then
                prevX, prevY = x, y
            else
                love.graphics.line(prevX, prevY, x, y)
                prevX, prevY = x, y
            end
        end
        
        -- Draw power indicator at end of arc
        love.graphics.setColor(1, 0.5, 0, 0.7)
        love.graphics.circle("fill", prevX, prevY, 3)
        
    elseif (fishingState == "waiting" or fishingState == "bobbing" or fishingState == "struggling" or fishingState == "reeling") and bobberX ~= 0 and bobberY ~= 0 then
        local time = love.timer.getTime()
        local bobberDrawY = bobberY
        local bobberSize = 5
        
        if fishingState == "struggling" or fishingState == "reeling" then
            -- During struggling/reeling: line under tension, bobber pulled down
            bobberDrawY = bobberY + 15 -- Bobber pulled deeper
            bobberSize = 3 -- Smaller, mostly submerged
            
            -- Struggling fish bubbles and splash
            love.graphics.setColor(1, 1, 1, 0.7)
            for i = 1, 4 do
                local bubbleX = bobberX + math.sin(time * 6 + i) * 8
                local bubbleY = bobberDrawY + math.cos(time * 4 + i) * 5
                love.graphics.circle("fill", bubbleX, bubbleY, 2)
            end
            
            -- Intense water disturbance
            love.graphics.setColor(0.4, 0.7, 1, 0.6)
            love.graphics.setLineWidth(3)
            for i = 1, 4 do
                local rippleSize = 8 + i * 6 + math.sin(time * 8 + i) * 6
                love.graphics.circle("line", bobberX, bobberY + 8, rippleSize)
            end
            
        elseif isBiting then
            -- Dramatic bite animation - bobber dips and jerks
            local biteIntensity = math.sin(time * 10) * 4 -- Fast jerky motion
            local dipAmount = 8 -- Bobber dips deeper when fish bites
            bobberDrawY = bobberY + dipAmount + biteIntensity
            bobberSize = 4 -- Slightly smaller when submerged
        else
            -- Normal gentle bobbing
            local bob = math.sin(time * 2) * 1.5 -- Gentle bobbing
            bobberDrawY = bobberY + bob
        end
        
        -- Single unified line drawing section (no duplicates)        
        -- Calculate line position and draw based on current state
        if fishingState == "struggling" or fishingState == "reeling" then
            -- Tense line animation with vibration
            love.graphics.setColor(0.9, 0.7, 0.5, 0.9) -- Tighter line color
            love.graphics.setLineWidth(1.5)
            local tension = math.sin(time * 8) * 2 
            local midX = (rodX + bobberX) / 2 + tension
            local midY = (rodY + bobberDrawY) / 2 + 5 -- Less sag, tighter line
            love.graphics.line(rodX, rodY, midX, midY)
            love.graphics.line(midX, midY, bobberX, bobberDrawY)
        elseif isBiting then
            -- Line with tension during bite
            love.graphics.setColor(1, 0.8, 0.6, 0.9)
            love.graphics.setLineWidth(1.5)
            local midX = (rodX + bobberX) / 2
            local midY = (rodY + bobberDrawY) / 2 + 10 -- Slight sag
            love.graphics.line(rodX, rodY, midX, midY)
            love.graphics.line(midX, midY, bobberX, bobberDrawY)
        else
            -- Normal relaxed line
            love.graphics.setColor(0.8, 0.8, 0.6, 0.8) -- Light fishing line color
            love.graphics.setLineWidth(1.5)
            local midX = (rodX + bobberX) / 2
            local midY = (rodY + bobberDrawY) / 2 + 15 -- Normal sag
            love.graphics.line(rodX, rodY, midX, midY)
            love.graphics.line(midX, midY, bobberX, bobberDrawY)
        end
        
        -- Draw bobber with bite-responsive animation
        if isBiting then
            -- Flashing red bobber when biting
            local flash = math.sin(time * 8) * 0.5 + 0.5
            love.graphics.setColor(1, 0.2 * flash, 0.2 * flash, 1)
            love.graphics.circle("fill", bobberX, bobberDrawY, bobberSize + 1)
            -- White splash effect around bobber
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.circle("line", bobberX, bobberDrawY, bobberSize + 3 + math.sin(time * 12) * 2)
        else
            -- Normal bobber colors
            love.graphics.setColor(1, 0.2, 0.2, 1) -- Red bobber top
            love.graphics.circle("fill", bobberX, bobberDrawY, bobberSize)
            love.graphics.setColor(1, 1, 1, 1) -- White bobber bottom
            love.graphics.circle("fill", bobberX, bobberDrawY + 2, 3)
        end
        
        -- Water ripples (enhanced when biting)
        if isBiting then
            -- More intense ripples when fish is biting
            love.graphics.setColor(0.4, 0.7, 1, 0.5)
            love.graphics.setLineWidth(2)
            for i = 1, 3 do
                local rippleSize = 10 + i * 8 + math.sin(time * 6 + i) * 4
                love.graphics.circle("line", bobberX, bobberY + 5, rippleSize)
            end
        else
            -- Gentle ripples during normal bobbing
            love.graphics.setColor(0.4, 0.7, 1, 0.3)
            love.graphics.setLineWidth(2)
            local ripple = math.sin(time * 4) * 0.5
            love.graphics.circle("line", bobberX, bobberY + 2, 8 + ripple * 2)
            love.graphics.circle("line", bobberX, bobberY + 2, 12 + ripple * 3)
        end
    end
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Getters
function CastingSystem:getCastPower()
    return castPower
end

function CastingSystem:getBobberPosition()
    return bobberX, bobberY
end

return CastingSystem
