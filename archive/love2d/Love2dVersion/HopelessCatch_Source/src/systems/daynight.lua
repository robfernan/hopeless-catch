-- src/systems/daynight.lua - 24-Hour Horror Time Cycle
local DayNight = {
    time = 0.35, -- 0.0 to 1.0 (0.0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk)
    day = 1,
    timeScale = 0.0022, -- Substantially slower (approx 7.5 real minutes per in-game day)
    isNight = false,
    rottenTideLevel = 1.0, -- Multiplier that grows with days
    
    ambientColors = {
        night = {0.10, 0.14, 0.26}, -- Atmospheric deep moonlit blue (visible silhouettes)
        dawn  = {0.52, 0.32, 0.36},
        day   = {0.85, 0.88, 0.90},
        dusk  = {0.58, 0.28, 0.24}
    }
}

function DayNight.update(dt)
    DayNight.time = (DayNight.time + dt * DayNight.timeScale) % 1.0
    DayNight.isNight = (DayNight.time < 0.22 or DayNight.time > 0.78)
end

function DayNight.advanceDay()
    DayNight.day = DayNight.day + 1
    DayNight.time = 0.28 -- Start at foggy dawn
    DayNight.rottenTideLevel = 1.0 + (DayNight.day - 1) * 0.35
end

function DayNight.getPhase()
    local t = DayNight.time
    if t < 0.20 then return "Dead of Night"
    elseif t < 0.30 then return "Pale Dawn"
    elseif t < 0.70 then return "Daylight"
    elseif t < 0.80 then return "Bleeding Dusk"
    else return "Nightfall" end
end

function DayNight.getClockString()
    local totalMinutes = math.floor(DayNight.time * 24 * 60)
    local hours = math.floor(totalMinutes / 60)
    local mins = totalMinutes % 60
    return string.format("%02d:%02d", hours, mins)
end

function DayNight.getAmbientColor()
    local t = DayNight.time
    local c1, c2, blend
    
    if t < 0.25 then
        c1 = DayNight.ambientColors.night
        c2 = DayNight.ambientColors.dawn
        blend = t / 0.25
    elseif t < 0.50 then
        c1 = DayNight.ambientColors.dawn
        c2 = DayNight.ambientColors.day
        blend = (t - 0.25) / 0.25
    elseif t < 0.75 then
        c1 = DayNight.ambientColors.day
        c2 = DayNight.ambientColors.dusk
        blend = (t - 0.50) / 0.25
    else
        c1 = DayNight.ambientColors.dusk
        c2 = DayNight.ambientColors.night
        blend = (t - 0.75) / 0.25
    end
    
    return {
        c1[1] + (c2[1] - c1[1]) * blend,
        c1[2] + (c2[2] - c1[2]) * blend,
        c1[3] + (c2[3] - c1[3]) * blend
    }
end

return DayNight
