-- ui/imgui/hud.lua - In-game HUD rendered with Dear ImGui
local imgui = require("cimgui")

local HUD = {}
HUD.visible = true

--- Draw the in-game HUD overlay. Call during "playing" state, after world render.
function HUD:draw()
    if not self.visible then return end
    
    local FishingSystem = require("fishing.fishing")
    local DayNightCycle = require("world.daynightcycle")
    local Weather = require("world.weather")
    
    local w, h = love.graphics.getDimensions()
    local fishingState = FishingSystem:getState()
    local isBiting = FishingSystem:isBiting()
    
    -- === TOP-LEFT: Time / Day / Weather panel ===
    imgui.SetNextWindowPos(12, 12)
    imgui.Begin("##HUD_Time", nil, 
        imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize + 
        imgui.WindowFlags_NoMove + imgui.WindowFlags_AlwaysAutoResize +
        imgui.WindowFlags_NoSavedSettings)
    
    local day = DayNightCycle:getCurrentDay()
    local timeStr = DayNightCycle:getTimeString()
    local phase = DayNightCycle:getCurrentPhase()
    local weatherName = Weather:getWeatherData().name
    
    -- Day counter with subtle glow at night
    if DayNightCycle:isNightTime() then
        imgui.PushStyleColor(imgui.Col_Text, {0.7, 0.65, 0.85, 1})
    end
    imgui.Text("Day %d", day)
    if DayNightCycle:isNightTime() then
        imgui.PopStyleColor()
    end
    
    imgui.Text("%s  ·  %s", timeStr, phase)
    
    -- Weather indicator
    local weatherColors = {
        clear = {0.6, 0.75, 0.9, 1},
        rain  = {0.5, 0.6, 0.8, 1},
        fog   = {0.6, 0.6, 0.65, 1},
        storm = {0.7, 0.5, 0.4, 1},
    }
    local wc = weatherColors[Weather:getCurrentWeather()] or {0.7, 0.7, 0.7, 1}
    imgui.PushStyleColor(imgui.Col_Text, wc)
    imgui.Text(weatherName)
    imgui.PopStyleColor()
    
    imgui.End()
    
    -- === TOP-RIGHT: Fishing state panel ===
    if fishingState ~= "waiting" and fishingState ~= "idle" then
        local panelW = 280
        imgui.SetNextWindowPos(w - panelW - 12, 12)
        imgui.Begin("##HUD_Fishing", nil,
            imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize +
            imgui.WindowFlags_NoMove + imgui.WindowFlags_AlwaysAutoResize +
            imgui.WindowFlags_NoSavedSettings)
        
        -- State label
        local stateLabels = {
            casting    = "CASTING",
            bobbing    = "WAITING FOR BITE...",
            struggling = "FIGHT!",
            reeling    = "REEL IN!",
        }
        local label = stateLabels[fishingState] or fishingState:upper()
        
        if isBiting then
            -- Flashing red for bite alert
            local flash = 0.7 + 0.3 * math.sin(love.timer.getTime() * 12)
            imgui.PushStyleColor(imgui.Col_Text, {1.0, 0.25 * flash, 0.2 * flash, 1})
            imgui.Text("!! BITE DETECTED - PRESS SPACE !!")
            imgui.PopStyleColor()
        else
            local stateColors = {
                casting    = {0.8, 0.7, 0.5, 1},
                bobbing    = {0.6, 0.7, 0.8, 1},
                struggling = {0.9, 0.4, 0.3, 1},
                reeling    = {0.4, 0.85, 0.4, 1},
            }
            local sc = stateColors[fishingState] or {0.8, 0.8, 0.8, 1}
            imgui.PushStyleColor(imgui.Col_Text, sc)
            imgui.Text(label)
            imgui.PopStyleColor()
        end
        
        -- === Tension bar (during struggling/reeling) ===
        if fishingState == "struggling" or fishingState == "reeling" then
            local tension = FishingSystem:getLineStress() / FishingSystem:getMaxLineStress()
            
            imgui.Spacing()
            imgui.Text("LINE TENSION")
            
            -- Color based on danger level
            local barColor
            if tension > 0.8 then
                local flash = 0.6 + 0.4 * math.sin(love.timer.getTime() * 15)
                barColor = {1.0, 0.2 * flash, 0.15 * flash, 1}
            elseif tension > 0.5 then
                barColor = {1.0, 0.75, 0.2, 1}
            else
                barColor = {0.3, 0.85, 0.3, 1}
            end
            
            imgui.PushStyleColor(imgui.Col_FrameBg, {0.08, 0.08, 0.1, 1})
            imgui.PushStyleColor(imgui.Col_PlotHistogram, barColor)
            imgui.ProgressBar(tension, nil, "")
            imgui.PopStyleColor(2)
            
            -- === Reel progress (during reeling) ===
            if fishingState == "reeling" then
                local progress = FishingSystem:getReelProgress() / FishingSystem:getMaxReelProgress()
                
                imgui.Spacing()
                imgui.Text("REEL PROGRESS")
                
                imgui.PushStyleColor(imgui.Col_FrameBg, {0.08, 0.1, 0.08, 1})
                imgui.PushStyleColor(imgui.Col_PlotHistogram, {0.25, 0.75, 0.3, 1})
                imgui.ProgressBar(progress, nil, "")
                imgui.PopStyleColor(2)
            end
            
            -- Fish pulling indicator
            if FishingSystem:isFishPulling() then
                imgui.Spacing()
                local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 8)
                imgui.PushStyleColor(imgui.Col_Text, {1.0, 0.35 * pulse, 0.25 * pulse, 1})
                imgui.Text("⚠ FISH IS PULLING - EASE OFF!")
                imgui.PopStyleColor()
            end
        end
        
        -- === Cast power (during casting) ===
        if fishingState == "casting" then
            local power = FishingSystem:getCastPower()
            imgui.Spacing()
            imgui.Text("CAST POWER")
            
            local pColor
            if power > 0.8 then pColor = {0.3, 0.9, 0.3, 1}
            elseif power > 0.4 then pColor = {0.9, 0.8, 0.3, 1}
            else pColor = {0.9, 0.5, 0.2, 1} end
            
            imgui.PushStyleColor(imgui.Col_FrameBg, {0.08, 0.08, 0.1, 1})
            imgui.PushStyleColor(imgui.Col_PlotHistogram, pColor)
            imgui.ProgressBar(power, nil, "")
            imgui.PopStyleColor(2)
            
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col_Text, {0.6, 0.58, 0.5, 0.9})
            imgui.Text("Release SPACE at desired power")
            imgui.PopStyleColor()
        end
        
        -- === Bite countdown (during bobbing) ===
        if fishingState == "bobbing" and not isBiting then
            local biteTimer = FishingSystem:getBiteTimer() or 0
            local biteDelay = FishingSystem:getBiteDelay() or 0
            if biteDelay > 0 then
                local timeLeft = math.max(0, biteDelay - biteTimer)
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col_Text, {0.5, 0.55, 0.65, 0.8})
                imgui.Text("Something stirs in the deep...")
                imgui.PopStyleColor()
            end
        end
        
        -- Current bait info
        local bait = FishingSystem:getCurrentBait()
        if bait then
            imgui.Spacing()
            imgui.Separator()
            imgui.PushStyleColor(imgui.Col_Text, {0.55, 0.52, 0.48, 0.9})
            imgui.Text("Bait: %s", bait.name)
            imgui.PopStyleColor()
        end
        
        imgui.End()
    end
    
    -- === BOTTOM-LEFT: Controls hint (subtle) ===
    imgui.SetNextWindowPos(12, h - 36)
    imgui.Begin("##HUD_Controls", nil,
        imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize +
        imgui.WindowFlags_NoMove + imgui.WindowFlags_AlwaysAutoResize +
        imgui.WindowFlags_NoSavedSettings)
    
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.43, 0.40, 0.7})
    imgui.Text("WASD Move · SPACE Cast/Reel · B Tacklebox · TAB Journal · H Rest")
    imgui.PopStyleColor()
    
    imgui.End()
end

return HUD