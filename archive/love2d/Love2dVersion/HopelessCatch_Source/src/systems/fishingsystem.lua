-- src/systems/fishingsystem.lua - Cast Physics, Waiting Tension, and Reeling Battle
local Assets = require("src.core.assets")
local FishData = require("src.data.fishdata")
local BaitData = require("src.data.baitdata")

local FishingSystem = {
    state = "idle", -- "idle", "charging", "flying", "bobbing", "biting", "reeling", "caught"
    castPower = 0,
    castDir = 1,
    bobber = { x = 0, y = 0, targetX = 0, targetY = 0 },
    
    biteTimer = 0,
    biteWindow = 0,
    currentFish = nil,
    
    -- Reeling mini-game mechanics
    tension = 0.2,       -- 0.0 to 1.0 (danger above 0.8)
    reelProgress = 0.0,  -- 0.0 to 1.0 (win at 1.0)
    fishPull = 0,
    fishPullTimer = 0,
    
    caughtFish = nil,
    stats = { totalCaught = 0, totalLost = 0 }
}

function FishingSystem.reset()
    FishingSystem.state = "idle"
    FishingSystem.castPower = 0
    FishingSystem.tension = 0.2
    FishingSystem.reelProgress = 0.0
    FishingSystem.currentFish = nil
    FishingSystem.caughtFish = nil
end

function FishingSystem.update(dt, input, player, dayNight, horizonY, dockEdgeY)
    local state = FishingSystem.state
    horizonY = horizonY or (love.graphics.getHeight() * 0.44)
    dockEdgeY = dockEdgeY or (love.graphics.getHeight() * 0.78)
    
    if state == "idle" then
        if input.isPressed("action") then
            local b = BaitData.getSelected()
            if b and b.count > 0 then
                FishingSystem.state = "charging"
                FishingSystem.castPower = 0
            end
        end
        
    elseif state == "charging" then
        if input.isDown("action") then
            FishingSystem.castPower = math.min(1.0, FishingSystem.castPower + dt * 1.4)
        else
            -- Release cast forward into open water in front of the dock!
            FishingSystem.state = "flying"
            local tipX, tipY = player.getRodTip("charging")
            FishingSystem.bobber.x = tipX
            FishingSystem.bobber.y = tipY
            
            -- Open water range: between dock front edge and distant horizon
            local minCastY = dockEdgeY - 30 -- just off the dock edge into open water
            local maxCastY = horizonY + 45  -- deep lake water near far horizon
            local lakeDepthY = minCastY - (FishingSystem.castPower * (minCastY - maxCastY))
            local spreadX = player.x + (math.random() - 0.5) * (60 + FishingSystem.castPower * 140)
            
            FishingSystem.bobber.targetX = spreadX
            FishingSystem.bobber.targetY = lakeDepthY
            FishingSystem.distanceMeters = 10 + math.floor(FishingSystem.castPower * 25)
            
            BaitData.consumeSelected()
            Assets.play("splash", 0.1, 0.4)
        end
        
    elseif state == "flying" then
        local b = FishingSystem.bobber
        b.x = b.x + (b.targetX - b.x) * dt * 7
        b.y = b.y + (b.targetY - b.y) * dt * 7
        
        if math.abs(b.x - b.targetX) < 5 and math.abs(b.y - b.targetY) < 5 then
            FishingSystem.state = "bobbing"
            Assets.play("splash", 0.2, 0.8)
            -- Roll bite delay between 2.5 and 6 seconds
            FishingSystem.biteTimer = 2.5 + math.random() * 3.5
        end
        
    elseif state == "bobbing" then
        -- Allow player to actively reel the lure in during bobbing!
        if input.isDown("action") then
            local b = FishingSystem.bobber
            b.y = b.y + dt * 45 -- moves toward dock
            if math.random() < 0.25 then Assets.play("reel_click", 0.1, 0.3) end
            
            -- Lure retrieved all the way to dock
            if b.y >= dockEdgeY - 20 then
                FishingSystem.state = "idle"
                Assets.play("splash", 0.1, 0.4)
            end
        end
        
        FishingSystem.biteTimer = FishingSystem.biteTimer - dt
        if FishingSystem.biteTimer <= 0 then
            FishingSystem.state = "biting"
            FishingSystem.biteWindow = 2.4 -- Generous reaction window in seconds
            Assets.play("bite_stinger", 0.0, 1.0)
            
            -- Determine if hooked in Forbidden Waters (far left buoy zone)
            local isForbidden = (FishingSystem.bobber.x < 240)
            local bait = BaitData.getSelected()
            FishingSystem.currentFish = FishData.selectFish(dayNight.isNight, isForbidden, bait and bait.id)
        end
        
    elseif state == "biting" then
        FishingSystem.biteWindow = FishingSystem.biteWindow - dt
        
        if input.isPressed("action") or input.isDown("action") then
            -- Successfully hooked!
            FishingSystem.state = "reeling"
            FishingSystem.tension = 0.30
            FishingSystem.reelProgress = 0.05
            FishingSystem.fishPullTimer = 0.5
            Assets.play("splash", 0.2, 0.9)
        elseif FishingSystem.biteWindow <= 0 then
            -- Missed bite
            FishingSystem.state = "idle"
            FishingSystem.stats.totalLost = FishingSystem.stats.totalLost + 1
        end
        
    elseif state == "reeling" then
        local diff = (FishingSystem.currentFish and FishingSystem.currentFish.difficulty) or 2
        
        -- Fish pulling behavior
        FishingSystem.fishPullTimer = FishingSystem.fishPullTimer - dt
        if FishingSystem.fishPullTimer <= 0 then
            FishingSystem.fishPull = (math.random() < 0.65) and (0.55 + diff * 0.16) or 0
            FishingSystem.fishPullTimer = 0.7 + math.random() * 1.0
        end
        
        -- Player reeling
        if input.isDown("action") then
            FishingSystem.tension = FishingSystem.tension + (0.45 + FishingSystem.fishPull * 0.45) * dt
            FishingSystem.reelProgress = FishingSystem.reelProgress + (0.35 / diff) * dt
            if math.random() < 0.35 then Assets.play("reel_click", 0.1, 0.4) end
        else
            -- Tension relieves when not reeling
            FishingSystem.tension = math.max(0.05, FishingSystem.tension - 0.70 * dt)
        end
        
        -- Pull bobber physically closer to dock as progress increases
        local minCastY = dockEdgeY - 25
        local startY = FishingSystem.bobber.targetY or (dockEdgeY - 120)
        FishingSystem.bobber.y = startY + (minCastY - startY) * FishingSystem.reelProgress
        FishingSystem.distanceMeters = math.max(0.2, (1.0 - FishingSystem.reelProgress) * 25.0)
        
        -- Line snapped condition
        if FishingSystem.tension >= 1.0 then
            Assets.play("line_snap", 0.0, 1.0)
            FishingSystem.state = "idle"
            FishingSystem.stats.totalLost = FishingSystem.stats.totalLost + 1
        -- Catch condition
        elseif FishingSystem.reelProgress >= 1.0 then
            FishingSystem.state = "caught"
            FishingSystem.caughtFish = FishingSystem.currentFish
            FishingSystem.stats.totalCaught = FishingSystem.stats.totalCaught + 1
            Assets.play("splash", 0.2, 0.9)
        end
    end
end

function FishingSystem.draw(player, horizonY, dockEdgeY)
    local state = FishingSystem.state
    horizonY = horizonY or (love.graphics.getHeight() * 0.44)
    dockEdgeY = dockEdgeY or (love.graphics.getHeight() * 0.78)
    local tipX, tipY = player.getRodTip(state)
    local f = player.facing or 1
    
    if state == "idle" then
        -- Line hangs gracefully from the tip of the rod with a dangling lure
        local sway = math.sin(love.timer.getTime() * 2.5) * 2
        local lureX = tipX + sway
        local lureY = tipY + 24
        
        love.graphics.setColor(0.9, 0.9, 0.95, 0.65)
        love.graphics.setLineWidth(1)
        love.graphics.line(tipX, tipY, lureX, lureY)
        -- Dangling red lure
        love.graphics.setColor(0.85, 0.15, 0.15, 0.85)
        love.graphics.circle("fill", lureX, lureY, 3)
        love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        love.graphics.line(lureX, lureY + 1, lureX, lureY + 5)
        
    elseif state == "charging" then
        -- Line pulled taut from rod tip back to the arched lure
        local lureX = tipX - (f * 12)
        local lureY = tipY + 16
        love.graphics.setColor(0.95, 0.95, 1.0, 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.line(tipX, tipY, lureX, lureY)
        love.graphics.setColor(0.85, 0.2, 0.2, 0.9)
        love.graphics.circle("fill", lureX, lureY, 3)
        
        -- Forward cast trajectory preview arc aiming into open lake
        love.graphics.setColor(1, 1, 1, 0.45)
        local minCastY = dockEdgeY - 30
        local maxCastY = horizonY + 45
        local targetY = minCastY - (FishingSystem.castPower * (minCastY - maxCastY))
        local ctrlX = (tipX + player.x) * 0.5
        local ctrlY = math.min(tipY, targetY) - 30
        local curve = love.math.newBezierCurve(tipX, tipY, ctrlX, ctrlY, player.x, targetY)
        love.graphics.line(curve:render())
        
        -- Pulsing target reticle in the open water
        love.graphics.setColor(0.4, 0.8, 1.0, 0.75)
        love.graphics.circle("line", player.x, targetY, 8 + 4 * math.sin(love.timer.getTime() * 8))
        love.graphics.setColor(0.2, 0.6, 1.0, 0.3)
        love.graphics.circle("fill", player.x, targetY, 6)
        
    elseif state == "flying" or state == "bobbing" or state == "biting" or state == "reeling" then
        local bx = FishingSystem.bobber.x
        local by = FishingSystem.bobber.y
        local t = love.timer.getTime()
        
        -- Depth perspective ratio: 0.0 near horizon, 1.0 near dock
        local depthFrac = math.max(0.0, math.min(1.0, (by - horizonY) / (dockEdgeY - horizonY)))
        local bobberScale = 0.6 + 0.6 * depthFrac -- scales between 0.6x and 1.2x
        
        -- Float movement and violent fish tugging
        if state == "bobbing" then
            by = by + math.sin(t * 3.5) * 2.5
        elseif state == "biting" then
            -- Sharp violent downward and sideways tugs as the fish bites
            local tugX = math.sin(t * 24) * 8
            local tugY = (math.sin(t * 18) > 0) and 12 or -2
            bx = bx + tugX
            by = by + tugY
        elseif state == "reeling" then
            -- Thrashing and pulling left/right in water during battle
            local struggleX = math.sin(t * 16 + FishingSystem.tension * 5) * (12 * FishingSystem.tension)
            local struggleY = math.sin(t * 12) * 5
            bx = bx + struggleX
            by = by + struggleY
        end
        
        -- Fishing Line (curved bezier curve)
        local ctrlX = (tipX + bx) * 0.5
        local ctrlY = math.min(tipY, by) + (state == "reeling" and 5 or 25)
        local curve = love.math.newBezierCurve(tipX, tipY, ctrlX, ctrlY, bx, by)
        
        -- Line glows bright when under high tension
        if state == "reeling" and FishingSystem.tension > 0.75 then
            love.graphics.setColor(1.0, 0.3, 0.25, 0.9)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.9, 0.9, 0.95, 0.75)
            love.graphics.setLineWidth(1)
        end
        love.graphics.line(curve:render())
        love.graphics.setLineWidth(1)
        
        -- Water splash ripples around float
        if state == "biting" or state == "reeling" then
            local rPulse = math.sin(t * 12) * 6
            love.graphics.setColor(1.0, 1.0, 1.0, 0.75)
            love.graphics.circle("line", bx, by + 4, (14 + rPulse) * bobberScale)
            love.graphics.setColor(0.4, 0.75, 1.0, 0.45)
            love.graphics.circle("line", bx, by + 4, (22 + rPulse) * bobberScale)
            
            -- Water droplets / splash particles
            for s = 1, 4 do
                local ang = (t * 8 + s * 1.5) % (math.pi * 2)
                local dist = (10 + (s * 4)) * bobberScale
                love.graphics.setColor(0.9, 0.95, 1.0, 0.8)
                love.graphics.rectangle("fill", bx + math.cos(ang) * dist, by + math.sin(ang) * dist - 4, 2, 2)
            end
        else
            -- Calm water concentric ripple
            local calmR = ((t * 15) % 18) * bobberScale
            love.graphics.setColor(0.7, 0.85, 1.0, (1 - calmR / (18 * bobberScale)) * 0.4)
            love.graphics.circle("line", bx, by + 3, calmR)
        end
        
        -- The Bobber Float (Red & White capsule with 2.5D perspective scale)
        local br = 5 * bobberScale
        love.graphics.setColor(0.85, 0.15, 0.15, 1.0)
        love.graphics.circle("fill", bx, by - (2.5 * bobberScale), br)
        love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
        love.graphics.circle("fill", bx, by + (2.0 * bobberScale), br)
        -- Bobber stem / antenna
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.line(bx, by - (7 * bobberScale), bx, by - (2 * bobberScale))
    end
end

return FishingSystem
