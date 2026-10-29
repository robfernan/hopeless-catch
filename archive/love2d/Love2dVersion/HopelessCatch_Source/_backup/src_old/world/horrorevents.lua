-- world/horrorevents.lua - Horror event system for Hopeless Catch
-- Manages escalating psychological horror triggers tied to gameplay milestones.

local HorrorEvents = {}

-- Event state tracking
local night1Triggered = false       -- Has the Night 1 sequence already fired?
local cabinLightFlickerActive = false
local cabinLightFlickerTimer = 0
local FLICKER_DURATION = 3.0        -- seconds of flickering
local FLICKER_INTERVAL = 0.15      -- seconds between on/off toggles
local flickerOn = true

-- Fishman stinger state (visual static + shake burst)
local fishmanStingerActive = false
local fishmanStingerTimer = 0
local FISHMAN_STINGER_DURATION = 1.2  -- seconds of visual distortion

-- === FEATURE 1: Fishman Scripted Encounter (Night 3+) ===
local fishmanEncounterTriggered = false   -- has the scripted encounter fired?
local fishmanEncounterActive = false      -- is the encounter sequence currently playing?
local fishmanEncounterPhase = "idle"      -- idle, desaturate, reel, resolve
local fishmanEncounterTimer = 0
local FISHMAN_ENCOUNTER_DURATION = 8.0   -- total scripted sequence length (seconds)

-- === FEATURE 2: Missable Nightly Visual Anomalies ===
local anomalyActive = false
local anomalyType = nil          -- "shore_figure", "cabin_window", "fish_shadow"
local anomalyTimer = 0
local ANOMALY_DURATION = 4.0     -- each anomaly lasts ~4 seconds (easy to miss)
local anomalyCooldown = 0       -- time until next anomaly can spawn
local ANOMALY_COOLDOWN_MIN = 25  -- min seconds between anomalies
local ANOMALY_COOLDOWN_MAX = 60  -- max seconds between anomalies
local anomalyX = 0              -- screen position for the anomaly
local anomalyAlpha = 0          -- fade in/out alpha

-- === FEATURE 3: Atmospheric Weather Escalation (Night 4+) ===
local weatherEscalationLevel = 0   -- 0=normal, 1=night4+, 2=night6+
local skyAnomalyActive = false     -- unnatural patterned lights in the sky
local skyAnomalyTimer = 0
local SKY_ANOMALY_INTERVAL = 8.0   -- seconds between sky anomaly pulses

-- Callback registry (other systems can subscribe)
local listeners = {}

--- Register a callback to be invoked when a named horror event fires.
-- @param eventName string e.g. "night1_first_catch", "cabin_light_flicker"
-- @param fn function(eventData) called with an optional data table
function HorrorEvents:on(eventName, fn)
    if type(fn) == "function" then
        listeners[eventName] = fn
    end
end

--- Internal: fire a registered event to all subscribers.
local function emit(eventName, data)
    local fn = listeners[eventName]
    if fn then
        fn(data or {})
    end
end

--- Initialize the horror events system. Call once at game startup.
function HorrorEvents:init()
    night1Triggered = false
    cabinLightFlickerActive = false
    cabinLightFlickerTimer = 0
    flickerOn = true
    fishmanStingerActive = false
    fishmanStingerTimer = 0
    -- Feature 1: Fishman encounter
    fishmanEncounterTriggered = false
    fishmanEncounterActive = false
    fishmanEncounterPhase = "idle"
    fishmanEncounterTimer = 0
    -- Feature 2: Nightly anomalies
    anomalyActive = false
    anomalyType = nil
    anomalyTimer = 0
    anomalyCooldown = math.random(ANOMALY_COOLDOWN_MIN, ANOMALY_COOLDOWN_MAX)
    anomalyAlpha = 0
    -- Feature 3: Weather escalation
    weatherEscalationLevel = 0
    skyAnomalyActive = false
    skyAnomalyTimer = 0
    listeners = {}
    print("👁️ Horror events system initialized")
end

--- Reset all horror state (e.g., on new game / load save).
function HorrorEvents:reset()
    night1Triggered = false
    cabinLightFlickerActive = false
    cabinLightFlickerTimer = 0
    flickerOn = true
    fishmanStingerActive = false
    fishmanStingerTimer = 0
    fishmanEncounterTriggered = false
    fishmanEncounterActive = false
    fishmanEncounterPhase = "idle"
    fishmanEncounterTimer = 0
    anomalyActive = false
    anomalyType = nil
    anomalyTimer = 0
    anomalyCooldown = math.random(ANOMALY_COOLDOWN_MIN, ANOMALY_COOLDOWN_MAX)
    anomalyAlpha = 0
    weatherEscalationLevel = 0
    skyAnomalyActive = false
    skyAnomalyTimer = 0
end

--- Check whether the Night 1 event has already been triggered.
function HorrorEvents:isNight1Triggered()
    return night1Triggered
end

--- Query whether the cabin light is currently in a "flickering" state.
-- Returns (isActive, isOn) so renderers can dim or brighten accordingly.
function HorrorEvents:getCabinLightState()
    if not cabinLightFlickerActive then
        return false, true  -- not flickering, light is on normally
    end
    return true, flickerOn
end

--- Core trigger: called when the player lands their first fish during night hours.
-- This fires the Night 1 horror sequence (cabin light flicker + journal unlock).
-- @param dayNightCycle optional DayNightCycle module reference for time verification
function HorrorEvents:onFirstNightCatch(dayNightCycle)
    if night1Triggered then return end

    -- Verify it's actually night (defensive check even if caller already checked)
    local isNight = false
    if dayNightCycle and type(dayNightCycle.isNightTime) == "function" then
        isNight = dayNightCycle:isNightTime()
    else
        -- Fallback: assume the caller verified it's night
        isNight = true
    end

    if not isNight then return end

    night1Triggered = true
    print("👁️ NIGHT 1 TRIGGERED - First catch in the dark...")

    -- Start the cabin light flicker sequence
    cabinLightFlickerActive = true
    cabinLightFlickerTimer = FLICKER_DURATION
    flickerOn = true

    -- Audio: duck the normal water ambient down to 0.3 and trigger low-frequency tension stinger
    local Assets = require("assets")
    if type(Assets.duckAmbientAudio) == "function" then
        Assets:duckAmbientAudio(0.3)  -- reduce lake ambience to 30%
    end
    if type(Assets.playHorrorSound) == "function" then
        Assets:playHorrorSound("sound_horror_hum", 0.6)
        Assets:playHorrorSound("sound_vinyl_crackle", 0.4)
    end

    -- Emit event so other systems (journal, audio, visual effects) can react
    emit("night1_first_catch", { day = os.date("%d") })
    emit("cabin_light_flicker_start", {})

    -- Auto-unlock the secret journal entry for Night 1
    local Journal = require("ui.journal")
    if type(Journal.unlockSecretEntry) == "function" then
        -- Use the current day from DayNightCycle if available, otherwise default to 1
        local dayNum = 1
        if dayNightCycle and type(dayNightCycle.getCurrentDay) == "function" then
            dayNum = dayNightCycle:getCurrentDay()
        end
        Journal:unlockSecretEntry(dayNum, "It saw you too.")
    end

    print("💡 Cabin light begins to flicker...")
end

--- Per-frame update. Call from the main game loop during "playing" state.
-- @param dt delta time in seconds
-- @param dayNightCycle optional DayNightCycle reference (for day/night checks)
function HorrorEvents:update(dt, dayNightCycle)
    -- === FEATURE 1: Fishman Scripted Encounter update ===
    self:_updateFishmanEncounter(dt)
    
    -- === FEATURE 2: Nightly Anomalies update ===
    self:_updateAnomalies(dt, dayNightCycle)
    
    -- === FEATURE 3: Weather Escalation / Sky Anomaly update ===
    self:_updateWeatherEscalation(dt, dayNightCycle)
    
    -- === Existing: Cabin light flicker ===
    if not cabinLightFlickerActive then return end

    cabinLightFlickerTimer = cabinLightFlickerTimer - dt

    -- Toggle flicker on/off at regular intervals for a strobing effect
    local phase = (cabinLightFlickerTimer % FLICKER_INTERVAL) / FLICKER_INTERVAL
    if phase < 0.5 then
        flickerOn = true
    else
        flickerOn = false
    end

    -- End the flicker sequence when timer expires
    if cabinLightFlickerTimer <= 0 then
        cabinLightFlickerActive = false
        flickerOn = true  -- light returns to normal (or stays off for dread)
        
        -- Audio: restore full water ambient volume
        local Assets = require("assets")
        if type(Assets.restoreAmbientAudio) == "function" then
            Assets:restoreAmbientAudio()
        end
        
        emit("cabin_light_flicker_end", {})
        print("💡 Cabin light steadies... but something feels different now.")
    end
end

--- Draw the cabin light flicker overlay. Call during the world render pass
-- if the cabin is visible on screen. Pass the cabin's lantern position.
-- @param x number - lantern X position
-- @param y number - lantern Y position
function HorrorEvents:drawCabinLight(x, y)
    local isActive, isOn = self:getCabinLightState()

    if not isActive then
        -- Normal steady light (warm glow)
        love.graphics.setColor(1.0, 0.85, 0.4, 0.3)
        love.graphics.circle("fill", x, y, 25)
        love.graphics.setColor(1.0, 0.9, 0.5, 0.6)
        love.graphics.circle("fill", x, y, 8)
    else
        -- Flickering: alternate between dim and bright with a cold tint shift
        if isOn then
            love.graphics.setColor(1.0, 0.7, 0.3, 0.25)
            love.graphics.circle("fill", x, y, 20)
            love.graphics.setColor(1.0, 0.8, 0.4, 0.5)
            love.graphics.circle("fill", x, y, 6)
        else
            -- Light is "off" - faint cold residual glow (dread)
            love.graphics.setColor(0.3, 0.3, 0.5, 0.1)
            love.graphics.circle("fill", x, y, 18)
        end
    end

    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

--- Convenience: check if a specific horror milestone has been reached.
-- @param eventName string
function HorrorEvents:hasFired(eventName)
    if eventName == "night1_first_catch" then
        return night1Triggered
    elseif eventName == "fishman_encounter" then
        return fishmanEncounterTriggered
    end
    return false
end

-- ============================================================
-- FEATURE 1: FISHMAN SCRIPTED ENCOUNTER (Night 3+)
-- ============================================================

--- Check if the Fishman scripted encounter should trigger.
-- Conditions: Night 3+, player hasn't caught Fishman yet, it's night time.
-- Call this from your game loop or after a day transition.
function HorrorEvents:checkFishmanEncounter(dayNightCycle)
    if fishmanEncounterTriggered then return false end
    
    local currentDay = 1
    local isNight = false
    if dayNightCycle then
        if type(dayNightCycle.getCurrentDay) == "function" then
            currentDay = dayNightCycle:getCurrentDay()
        end
        if type(dayNightCycle.isNightTime) == "function" then
            isNight = dayNightCycle:isNightTime()
        end
    end
    
    -- Must be Night 3+ and currently night
    if currentDay < 3 or not isNight then return false end
    
    -- Check if player has already caught the Fishman (via statistics)
    local FishingSystem = require("fishing.fishing")
    local stats = nil
    if type(FishingSystem.getStatistics) == "function" then
        stats = FishingSystem:getStatistics()
    end
    if stats and stats.fishCaughtByType and stats.fishCaughtByType["fishman"] and stats.fishCaughtByType["fishman"] > 0 then
        return false -- already caught, no scripted encounter needed
    end
    
    -- TRIGGER the scripted encounter!
    fishmanEncounterTriggered = true
    fishmanEncounterActive = true
    fishmanEncounterPhase = "desaturate"
    fishmanEncounterTimer = FISHMAN_ENCOUNTER_DURATION
    print("👁️ FISHMAN SCRIPTED ENCOUNTER - It knows you're here...")
    
    -- Audio: duck ambient, play deep stinger
    local Assets = require("assets")
    if type(Assets.duckAmbientAudio) == "function" then
        Assets:duckAmbientAudio(0.2)
    end
    if type(Assets.playHorrorSound) == "function" then
        Assets:playHorrorSound("sound_fishman_stinger", 0.8)
        Assets:playHorrorSound("sound_horror_hum", 0.7)
    end
    
    -- Screen shake for impact
    if _G.addScreenShake then
        _G.addScreenShake(0.6, 12)
    end
    
    emit("fishman_encounter_start", { day = currentDay })
    return true
end

--- Internal: update the Fishman encounter sequence phases.
function HorrorEvents:_updateFishmanEncounter(dt)
    if not fishmanEncounterActive then return end
    
    fishmanEncounterTimer = fishmanEncounterTimer - dt
    
    -- Phase transitions based on remaining time
    local total = FISHMAN_ENCOUNTER_DURATION
    if fishmanEncounterTimer > total * 0.6 then
        fishmanEncounterPhase = "desaturate"   -- first 40%: screen desaturates, water darkens
    elseif fishmanEncounterTimer > total * 0.2 then
        fishmanEncounterPhase = "reel"         -- middle 40%: high-tension reel minigame window
    else
        fishmanEncounterPhase = "resolve"      -- final 20%: resolve, journal entry
    end
    
    if fishmanEncounterTimer <= 0 then
        fishmanEncounterActive = false
        fishmanEncounterPhase = "idle"
        
        -- Restore ambient audio
        local Assets = require("assets")
        if type(Assets.restoreAmbientAudio) == "function" then
            Assets:restoreAmbientAudio()
        end
        
        -- Append the journal entry: "It remembers."
        local Journal = require("ui.journal")
        local DayNightCycle = require("world.daynightcycle")
        local dayNum = 1
        if type(DayNightCycle.getCurrentDay) == "function" then
            dayNum = DayNightCycle:getCurrentDay()
        end
        if type(Journal.unlockSecretEntry) == "function" then
            Journal:unlockSecretEntry(dayNum, "It remembers.")
        end
        
        emit("fishman_encounter_end", {})
        print("👁️ The water settles. It is watching still.")
    end
end

--- Query the Fishman encounter state for rendering (desaturation overlay, etc.)
-- Returns (isActive, phase, intensity) where intensity is 0..1 remaining time ratio.
function HorrorEvents:getFishmanEncounterState()
    if not fishmanEncounterActive then return false, "idle", 0 end
    local intensity = math.max(0, fishmanEncounterTimer / FISHMAN_ENCOUNTER_DURATION)
    return true, fishmanEncounterPhase, intensity
end

--- Draw the Fishman encounter visual overlay (desaturation + dark water tint).
-- Call during your render pass when getFishmanEncounterState() returns active.
function HorrorEvents:drawFishmanEncounter()
    local isActive, phase, intensity = self:getFishmanEncounterState()
    if not isActive then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Desaturation overlay: semi-transparent dark blue-grey wash
    local desatAlpha = 0.3 * intensity
    love.graphics.setColor(0.1, 0.12, 0.18, desatAlpha)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Dark water tint (bottom half of screen)
    local waterAlpha = 0.4 * intensity
    love.graphics.setColor(0.02, 0.05, 0.12, waterAlpha)
    love.graphics.rectangle("fill", 0, h * 0.5, w, h * 0.5)
    
    -- During "reel" phase: pulsing red vignette at edges (tension)
    if phase == "reel" then
        local pulse = 0.3 + 0.2 * math.sin(love.timer.getTime() * 6)
        love.graphics.setColor(0.5, 0.1, 0.1, pulse * intensity)
        local stripW = w * 0.12
        love.graphics.rectangle("fill", 0, 0, stripW, h)
        love.graphics.rectangle("fill", w - stripW, 0, stripW, h)
    end
    
    -- During "resolve" phase: brief white flash then fade
    if phase == "resolve" and intensity > 0.8 then
        local flashAlpha = (intensity - 0.8) * 5 * 0.3
        love.graphics.setColor(1, 1, 1, math.max(0, flashAlpha))
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

-- ============================================================
-- FEATURE 2: MISSABLE NIGHTLY VISUAL ANOMALIES
-- ============================================================

--- Internal: update anomaly spawning and lifecycle.
function HorrorEvents:_updateAnomalies(dt, dayNightCycle)
    local isNight = false
    if dayNightCycle and type(dayNightCycle.isNightTime) == "function" then
        isNight = dayNightCycle:isNightTime()
    end
    
    -- Only spawn anomalies at night
    if not isNight then
        anomalyActive = false
        anomalyAlpha = 0
        return
    end
    
    if anomalyActive then
        -- Active anomaly: count down and fade
        anomalyTimer = anomalyTimer - dt
        local remaining = math.max(0, anomalyTimer / ANOMALY_DURATION)
        -- Fade in first 20%, hold middle 60%, fade out last 20%
        if remaining > 0.8 then
            anomalyAlpha = (1 - remaining) * 5  -- fade in
        elseif remaining < 0.2 then
            anomalyAlpha = remaining * 5        -- fade out
        else
            anomalyAlpha = 1
        end
        
        if anomalyTimer <= 0 then
            anomalyActive = false
            anomalyType = nil
            anomalyAlpha = 0
            anomalyCooldown = math.random(ANOMALY_COOLDOWN_MIN, ANOMALY_COOLDOWN_MAX)
        end
    else
        -- Cooldown: count down until next anomaly can spawn
        anomalyCooldown = anomalyCooldown - dt
        if anomalyCooldown <= 0 then
            -- Spawn a random anomaly!
            local types = {"shore_figure", "cabin_window", "fish_shadow"}
            anomalyType = types[math.random(#types)]
            anomalyActive = true
            anomalyTimer = ANOMALY_DURATION
            anomalyAlpha = 0
            
            -- Position: random along the far shore / water area
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            if anomalyType == "shore_figure" then
                anomalyX = math.random(w * 0.1, w * 0.9)  -- somewhere on the far shore
            elseif anomalyType == "cabin_window" then
                anomalyX = w * 0.75  -- near the cabin area
            else
                anomalyX = math.random(w * 0.3, w * 0.7)  -- near the bobber area
            end
        end
    end
end

--- Query whether an anomaly is currently active (for rendering).
-- Returns (isActive, type, x, alpha)
function HorrorEvents:getAnomalyState()
    if not anomalyActive then return false, nil, 0, 0 end
    return true, anomalyType, anomalyX, anomalyAlpha
end

--- Draw the current nightly anomaly. Call during your world render pass.
-- These are SUBTLE and EASY TO MISS by design.
function HorrorEvents:drawAnomaly()
    local isActive, aType, ax, alpha = self:getAnomalyState()
    if not isActive or alpha <= 0 then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local shoreY = h * 0.55  -- approximate far shore line
    
    if aType == "shore_figure" then
        -- A tall, thin silhouette standing on the far shore.
        -- Very dark, slightly taller than it should be for a person.
        local figH = 28 + math.sin(love.timer.getTime() * 0.3) * 2  -- subtle sway
        local figW = 6
        love.graphics.setColor(0.05, 0.05, 0.1, alpha * 0.7)
        -- Body (elongated rectangle - too tall to be natural)
        love.graphics.rectangle("fill", ax - figW/2, shoreY - figH, figW, figH)
        -- Head (small circle on top)
        love.graphics.circle("fill", ax, shoreY - figH - 4, 3)
        
    elseif aType == "cabin_window" then
        -- A warm light flickering in the cabin window (should be dark at night).
        local winX = ax
        local winY = h * 0.38
        local flicker = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
        love.graphics.setColor(1.0, 0.7, 0.2, alpha * 0.4 * flicker)
        love.graphics.rectangle("fill", winX - 6, winY - 8, 12, 16)
        -- Glow
        love.graphics.setColor(1.0, 0.8, 0.3, alpha * 0.15 * flicker)
        love.graphics.circle("fill", winX, winY, 14)
        
    elseif aType == "fish_shadow" then
        -- A dark fish-shaped shadow passing beneath the bobber area.
        local t = love.timer.getTime()
        local shadowX = ax + math.sin(t * 0.8) * 30  -- slow lateral drift
        local shadowY = h * 0.62 + math.cos(t * 0.5) * 5
        love.graphics.setColor(0.05, 0.08, 0.15, alpha * 0.5)
        -- Elongated fish body
        love.graphics.push()
        love.graphics.translate(shadowX, shadowY)
        love.graphics.rotate(math.sin(t * 0.6) * 0.1)
        love.graphics.ellipse("fill", 0, 0, 20, 7)
        -- Tail
        love.graphics.polygon("fill", -18, 0, -28, -5, -28, 5)
        love.graphics.pop()
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

-- ============================================================
-- FEATURE 3: ATMOSPHERIC WEATHER ESCALATION (Night 4+)
-- ============================================================

--- Internal: update weather escalation level and sky anomalies.
function HorrorEvents:_updateWeatherEscalation(dt, dayNightCycle)
    local currentDay = 1
    local isNight = false
    if dayNightCycle then
        if type(dayNightCycle.getCurrentDay) == "function" then
            currentDay = dayNightCycle:getCurrentDay()
        end
        if type(dayNightCycle.isNightTime) == "function" then
            isNight = dayNightCycle:isNightTime()
        end
    end
    
    -- Escalation levels based on day count
    if currentDay >= 6 and isNight then
        weatherEscalationLevel = 2  -- extreme
    elseif currentDay >= 4 and isNight then
        weatherEscalationLevel = 1  -- elevated
    else
        weatherEscalationLevel = 0  -- normal
    end
    
    -- Sky anomaly: patterned lights that appear during escalation
    if weatherEscalationLevel > 0 and isNight then
        skyAnomalyTimer = skyAnomalyTimer + dt
        if skyAnomalyTimer >= SKY_ANOMALY_INTERVAL then
            skyAnomalyTimer = 0
            skyAnomalyActive = true
            -- Brief pulse of unnatural lights (handled in draw)
        end
    else
        skyAnomalyActive = false
    end
end

--- Get the current weather escalation level (0, 1, or 2).
-- Use this to boost storm frequency and rare fish spawn rates.
function HorrorEvents:getWeatherEscalationLevel()
    return weatherEscalationLevel
end

--- Get a rarity multiplier based on escalation level.
-- Pass this into your fish selection as an additional weight bonus.
function HorrorEvents:getRarityMultiplier()
    if weatherEscalationLevel >= 2 then return 1.5 end  -- Night 6+: +50% rare weight
    if weatherEscalationLevel == 1 then return 1.25 end  -- Night 4+: +25% rare weight
    return 1.0
end

--- Get a storm probability boost (add to your storm chance in weather selection).
function HorrorEvents:getStormBoost()
    if weatherEscalationLevel >= 2 then return 0.15 end  -- +15% storm chance
    if weatherEscalationLevel == 1 then return 0.08 end   -- +8% storm chance
    return 0
end

--- Draw the sky anomaly (unnatural patterned light formations).
-- Call during your sky/background render pass.
function HorrorEvents:drawSkyAnomaly()
    if weatherEscalationLevel == 0 then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local t = love.timer.getTime()
    
    -- Level 1 (Night 4+): faint geometric light patterns in the sky
    if weatherEscalationLevel >= 1 then
        local alpha = 0.08 + 0.04 * math.sin(t * 0.7)
        love.graphics.setColor(0.3, 0.2, 0.6, alpha)
        -- Triangular formation (unnatural, too symmetrical)
        local cx, cy = w * 0.5, h * 0.15
        local size = 40 + 10 * math.sin(t * 0.3)
        love.graphics.polygon("fill",
            cx, cy - size,
            cx - size * 0.866, cy + size * 0.5,
            cx + size * 0.866, cy + size * 0.5
        )
    end
    
    -- Level 2 (Night 6+): multiple patterned lights, pulsing in sequence
    if weatherEscalationLevel >= 2 then
        local alpha = 0.12 + 0.08 * math.sin(t * 1.2)
        love.graphics.setColor(0.4, 0.15, 0.6, alpha)
        -- Row of evenly-spaced lights (too regular to be stars)
        for i = 1, 5 do
            local lx = w * 0.2 + (i - 1) * (w * 0.15)
            local ly = h * 0.12 + math.sin(t * 0.8 + i * 1.3) * 8
            love.graphics.circle("fill", lx, ly, 3 + math.sin(t * 2 + i) * 1.5)
        end
        -- Connecting lines (geometric, unnatural)
        love.graphics.setColor(0.4, 0.15, 0.6, alpha * 0.4)
        love.graphics.setLineWidth(1)
        for i = 1, 4 do
            local x1 = w * 0.2 + (i - 1) * (w * 0.15)
            local y1 = h * 0.12 + math.sin(t * 0.8 + i * 1.3) * 8
            local x2 = w * 0.2 + i * (w * 0.15)
            local y2 = h * 0.12 + math.sin(t * 0.8 + (i+1) * 1.3) * 8
            love.graphics.line(x1, y1, x2, y2)
        end
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

--- Trigger the Fishman stinger sequence.
-- Called when a Fishman is hooked or caught during night hours.
-- Activates a brief visual static/shake overlay (queried via getFishmanStingerState)
-- and emits an event for audio/other systems to react to.
function HorrorEvents:triggerFishmanStinger()
    fishmanStingerActive = true
    fishmanStingerTimer = FISHMAN_STINGER_DURATION
    print("👁️ FISHMAN STINGER - Something writhes in the dark...")
    emit("fishman_stinger", {})
end

--- Query whether the Fishman stinger visual effect is currently active.
-- Returns (isActive, intensity) where intensity is 0..1 (fades over duration).
-- Call from your render pass to draw a static overlay or apply screen shake.
function HorrorEvents:getFishmanStingerState()
    if not fishmanStingerActive then
        return false, 0
    end
    local remaining = math.max(0, fishmanStingerTimer / FISHMAN_STINGER_DURATION)
    return true, remaining
end

--- Per-frame update for the Fishman stinger timer.
-- (Call alongside HorrorEvents:update(dt) in your game loop.)
function HorrorEvents:updateFishmanStinger(dt)
    if not fishmanStingerActive then return end
    fishmanStingerTimer = fishmanStingerTimer - dt
    if fishmanStingerTimer <= 0 then
        fishmanStingerActive = false
        emit("fishman_stinger_end", {})
    end
end

return HorrorEvents
