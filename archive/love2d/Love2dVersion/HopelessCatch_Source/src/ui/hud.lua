-- src/ui/hud.lua - In-game Retro Horror HUD & Line Tension Meter
local Assets = require("src.core.assets")
local BaitData = require("src.data.baitdata")

local HUD = {}

function HUD.draw(w, h, dayNight, fishingSystem)
    love.graphics.setFont(Assets.fonts.medium)
    
    -- 1. Top-Left: Day & Atmosphere Panel
    love.graphics.setColor(0.04, 0.05, 0.08, 0.85)
    love.graphics.rectangle("fill", 20, 20, 230, 80, 6, 6)
    love.graphics.setColor(0.35, 0.28, 0.22, 0.9)
    love.graphics.rectangle("line", 20, 20, 230, 80, 6, 6)
    
    love.graphics.setColor(0.95, 0.90, 0.82, 1.0)
    love.graphics.print(string.format("DAY %d  •  %s", dayNight.day, dayNight.getClockString()), 32, 28)
    
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.70, 0.65, 0.60, 0.9)
    love.graphics.print(dayNight.getPhase(), 32, 50)
    
    -- Rotten tide warning if escalating
    if dayNight.rottenTideLevel > 1.2 then
        love.graphics.setColor(0.85, 0.25, 0.2, 0.95)
        love.graphics.print(string.format("Rotten Tide: Lv. %.1f", dayNight.rottenTideLevel), 32, 70)
    end
    
    -- 2. Top-Right: Selected Bait Indicator
    local bait = BaitData.getSelected()
    if bait then
        love.graphics.setColor(0.04, 0.05, 0.08, 0.85)
        love.graphics.rectangle("fill", w - 240, 20, 220, 65, 6, 6)
        love.graphics.setColor(0.35, 0.28, 0.22, 0.9)
        love.graphics.rectangle("line", w - 240, 20, 220, 65, 6, 6)
        
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(0.95, 0.90, 0.82, 1.0)
        love.graphics.print(string.format("Bait: %s", bait.name), w - 225, 28)
        love.graphics.setFont(Assets.fonts.small)
        love.graphics.setColor(0.75, 0.70, 0.65, 0.9)
        love.graphics.print(string.format("Count: %d  (Key: B to swap)", bait.count), w - 225, 52)
    end
    
    -- 3. Center Status Alerts (Cast / Bobbing / Bite / Reeling Battle)
    local fState = fishingSystem.state
    
    if fState == "charging" then
        -- Cast Power Bar (Sega arcade style power meter)
        local barW = 320
        local barX = (w - barW) * 0.5
        local barY = h * 0.72
        
        love.graphics.setColor(0.04, 0.05, 0.08, 0.92)
        love.graphics.rectangle("fill", barX - 6, barY - 28, barW + 12, 58, 6, 6)
        love.graphics.setColor(0.45, 0.35, 0.22, 1.0)
        love.graphics.rectangle("line", barX - 6, barY - 28, barW + 12, 58, 6, 6)
        
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(1.0, 0.9, 0.4, 1.0)
        love.graphics.printf("CAST POWER", barX, barY - 24, barW, "center")
        
        -- Segmented power meter
        love.graphics.setColor(0.12, 0.12, 0.16, 1.0)
        love.graphics.rectangle("fill", barX, barY + 2, barW, 20, 4, 4)
        
        local powerCol = (fishingSystem.castPower > 0.8) and {1.0, 0.25, 0.2} or {0.2, 0.85, 0.4}
        love.graphics.setColor(powerCol[1], powerCol[2], powerCol[3], 1.0)
        love.graphics.rectangle("fill", barX, barY + 2, barW * fishingSystem.castPower, 20, 4, 4)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", barX, barY + 2, barW, 20, 4, 4)
        
    elseif fState == "bobbing" then
        -- Lure floating prompt
        local promptW = 340
        local promptX = (w - promptW) * 0.5
        local promptY = h * 0.16
        love.graphics.setColor(0.04, 0.05, 0.08, 0.85)
        love.graphics.rectangle("fill", promptX, promptY, promptW, 36, 6, 6)
        love.graphics.setColor(0.3, 0.4, 0.5, 0.9)
        love.graphics.rectangle("line", promptX, promptY, promptW, 36, 6, 6)
        love.graphics.setFont(Assets.fonts.small)
        local pulse = 0.75 + 0.25 * math.sin(love.timer.getTime() * 4)
        love.graphics.setColor(0.7, 0.85, 1.0, pulse)
        love.graphics.printf("HOLD SPACE TO REEL IN LURE  •  WAITING FOR STRIKE...", promptX, promptY + 10, promptW, "center")
        
    elseif fState == "biting" then
        -- Dramatic Flashing Bite Alert
        local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 18)
        love.graphics.setColor(0.15, 0.02, 0.02, 0.92)
        love.graphics.rectangle("fill", w * 0.5 - 240, h * 0.20, 480, 56, 8, 8)
        love.graphics.setColor(1.0, 0.2 * pulse, 0.2 * pulse, 1.0)
        love.graphics.rectangle("line", w * 0.5 - 240, h * 0.20, 480, 56, 8, 8)
        love.graphics.setFont(Assets.fonts.large)
        love.graphics.printf("!! FISH ON! TAP SPACE TO HOOK !!", 0, h * 0.20 + 12, w, "center")
        
    elseif fState == "reeling" then
        -- Sega Bass Fishing Arcade Battle HUD
        local boxW = 420
        local boxH = 135
        local boxX = (w - boxW) * 0.5
        local boxY = h * 0.14
        local isDanger = (fishingSystem.tension > 0.78)
        local tFlick = math.sin(love.timer.getTime() * 16)
        
        -- Chassis
        love.graphics.setColor(0.04, 0.05, 0.08, 0.95)
        love.graphics.rectangle("fill", boxX - 12, boxY - 10, boxW + 24, boxH, 8, 8)
        
        -- Border glows/flashes red during high tension
        if isDanger then
            love.graphics.setColor(1.0, 0.15, 0.15, 0.7 + 0.3 * tFlick)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.35, 0.5, 0.35, 0.9)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", boxX - 12, boxY - 10, boxW + 24, boxH, 8, 8)
        love.graphics.setLineWidth(1)
        
        -- Header: Fish Target & Distance
        love.graphics.setFont(Assets.fonts.medium)
        local fishName = (fishingSystem.currentFish and fishingSystem.currentFish.name) or "UNKNOWN HORROR"
        love.graphics.setColor(0.95, 0.85, 0.65, 1.0)
        love.graphics.print("TARGET: " .. fishName, boxX, boxY)
        
        -- Distance meter (Sega style digital readout)
        local dist = fishingSystem.distanceMeters or 15.0
        love.graphics.setColor(0.4, 0.85, 1.0, 1.0)
        love.graphics.printf(string.format("DIST: %.1fm", dist), boxX, boxY, boxW, "right")
        
        -- 1. LINE TENSION METER
        love.graphics.setFont(Assets.fonts.small)
        if isDanger then
            love.graphics.setColor(1.0, 0.2, 0.2, 1.0)
            love.graphics.print("LINE TENSION: DANGER! (RELEASE SPACE)", boxX, boxY + 28)
        else
            love.graphics.setColor(0.4, 0.9, 0.45, 1.0)
            love.graphics.print("LINE TENSION: SAFE (HOLD SPACE TO REEL)", boxX, boxY + 28)
        end
        
        -- Tension bar background
        love.graphics.setColor(0.12, 0.14, 0.16, 1.0)
        love.graphics.rectangle("fill", boxX, boxY + 46, boxW, 16, 3, 3)
        
        -- Tension fill color (Green -> Amber -> Red)
        local t = fishingSystem.tension
        if t < 0.60 then
            love.graphics.setColor(0.25, 0.85, 0.4, 1.0)
        elseif t < 0.80 then
            love.graphics.setColor(0.95, 0.75, 0.2, 1.0)
        else
            love.graphics.setColor(1.0, 0.15, 0.15, 0.85 + 0.15 * tFlick)
        end
        love.graphics.rectangle("fill", boxX, boxY + 46, boxW * t, 16, 3, 3)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        love.graphics.rectangle("line", boxX, boxY + 46, boxW, 16, 3, 3)
        
        -- 2. REEL PROGRESS / LANDING METER
        love.graphics.setColor(0.7, 0.85, 1.0, 1.0)
        love.graphics.print("LANDING PROGRESS", boxX, boxY + 70)
        love.graphics.setColor(0.12, 0.14, 0.16, 1.0)
        love.graphics.rectangle("fill", boxX, boxY + 88, boxW, 16, 3, 3)
        love.graphics.setColor(0.3, 0.75, 0.95, 1.0)
        love.graphics.rectangle("fill", boxX, boxY + 88, boxW * fishingSystem.reelProgress, 16, 3, 3)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        love.graphics.rectangle("line", boxX, boxY + 88, boxW, 16, 3, 3)
    end
    
    -- 4. Bottom Controls Reference Bar
    love.graphics.setColor(0.04, 0.05, 0.08, 0.8)
    love.graphics.rectangle("fill", 0, h - 30, w, 30)
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.7, 0.65, 0.6, 0.85)
    love.graphics.printf("WASD: Move  •  SPACE: Cast/Reel  •  B: Bait Box  •  TAB: Journal  •  H: Rest in Cabin  •  ESC: Pause", 0, h - 22, w, "center")
end

return HUD
