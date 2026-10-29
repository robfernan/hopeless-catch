-- Weather.lua - Dynamic weather system that affects gameplay and horror
local Weather = {}

local currentWeather = "clear"
local forcedWeather = nil
local weatherTimer = 0
local weatherDuration = 0

local windStrength = 0
local windDirection = 0
local rainParticles = {}
local lightningTimer = 0
local lightningFlash = 0

-- Weather types and their effects
-- `biteSpeedMult`   : multiplier applied to bite delay (lower = faster bites)
-- `rarityBoost`     : additive bonus to rare/horror fish weight in selection
local weatherTypes = {
    clear = {
        name = "Clear",
        fishingMultiplier = 1.0,
        visibilityRange = 1.0,
        castingAccuracy = 1.0,
        biteSpeedMult = 1.0,     -- normal bite timing
        rarityBoost = 0.0,       -- no extra rare weight
        duration = {60, 120}
    },
    rain = {
        name = "Rain",
        fishingMultiplier = 0.7,
        visibilityRange = 0.6,
        castingAccuracy = 0.8,
        biteSpeedMult = 0.6,     -- fish are more active in rain → faster bites
        rarityBoost = 0.1,       -- slight increase in unusual catches
        duration = {45, 90}
    },
    fog = {
        name = "Fog",
        fishingMultiplier = 0.8,
        visibilityRange = 0.3,
        castingAccuracy = 0.7,
        biteSpeedMult = 1.2,     -- bites are slower (harder to see)
        rarityBoost = 0.4,       -- fog attracts strange, rare creatures
        duration = {60, 150}
    },
    storm = {
        name = "Storm",
        fishingMultiplier = 0.3,
        visibilityRange = 0.4,
        castingAccuracy = 0.5,
        biteSpeedMult = 0.8,     -- moderate speed (chaotic water)
        rarityBoost = 0.25,      -- storms stir up deep things
        duration = {20, 40}
    },
}

function Weather:init()
    currentWeather = "clear"
    weatherTimer = 0
    weatherDuration = math.random(60, 120) -- Start with clear weather
    rainParticles = {}
    lightningTimer = 0
    lightningFlash = 0
end

function Weather:update(dt)
    weatherTimer = weatherTimer + dt

    -- If weather is forced, don't change it automatically
    if forcedWeather then
        currentWeather = forcedWeather
        -- Keep timer reset so transitions don't occur
        weatherTimer = 0
    else
        -- Check if weather should change
        if weatherTimer >= weatherDuration then
            self:changeWeather()
        end
    end

    -- Update weather effects
    if currentWeather == "rain" or currentWeather == "storm" then
        self:updateRain(dt)
    end

    -- Lightning effects for storms
    if currentWeather == "storm" then
        self:updateLightning(dt)
    end

    -- Gradual weather transitions
    self:updateTransitions(dt)
end

function Weather:changeWeather()
    if forcedWeather then
        currentWeather = forcedWeather
        weatherTimer = 0
        local weatherData = weatherTypes[currentWeather]
        weatherDuration = math.random(weatherData.duration[1], weatherData.duration[2])
        -- Reset weather-specific values
        if currentWeather == "rain" or currentWeather == "storm" then
            self:initRain()
        end
        return
    end

    local DayNightCycle = require("world.daynightcycle")
    local isNight = DayNightCycle:isNightTime()

    -- Weather probability based on horror level and time
    local weatherChances = {
        clear = 0.35,
        rain = 0.2,
        fog = (isNight) and 0.15 or 0.08,  -- fog is more common at night
        storm = (isNight) and 0.2 or 0.07,
    }

    -- Select new weather
    local roll = math.random()
    local cumulative = 0

    for weather, chance in pairs(weatherChances) do
        cumulative = cumulative + chance
        if roll <= cumulative then
            currentWeather = weather
            break
        end
    end

    local weatherData = weatherTypes[currentWeather]
    if not weatherData then
        currentWeather = "clear"
        weatherData = weatherTypes.clear
    end
    weatherDuration = math.random(weatherData.duration[1], weatherData.duration[2])
    weatherTimer = 0

    print("🌤️ Weather changed to: " .. weatherData.name)

    -- Reset weather-specific values
    if currentWeather == "rain" or currentWeather == "storm" then
        self:initRain()
    end
end

-- Force weather for boss encounters or story events
function Weather:forceWeather(weatherType)
    if weatherTypes[weatherType] then
        forcedWeather = weatherType
        currentWeather = weatherType
        local weatherData = weatherTypes[currentWeather]
        weatherDuration = math.random(weatherData.duration[1], weatherData.duration[2])
        weatherTimer = 0
        if currentWeather == "rain" or currentWeather == "storm" then
            self:initRain()
        elseif currentWeather == "windy" then
            windStrength = math.random(0.5, 1.0)
            windDirection = math.random() * math.pi * 2
        end
        print("⛈️ Forced weather: " .. weatherData.name)
    end
end

function Weather:clearForcedWeather()
    forcedWeather = nil
    print("🌤️ Forced weather cleared, resuming normal transitions.")
end

function Weather:initRain()
    rainParticles = {}
    local particleCount = currentWeather == "storm" and 150 or 80
    
    for i = 1, particleCount do
        table.insert(rainParticles, {
            x = math.random(0, love.graphics.getWidth() + 100),
            y = math.random(-100, 0),
            speed = math.random(200, 400),
            length = math.random(10, 25),
            alpha = math.random(0.3, 0.8)
        })
    end
end

function Weather:updateRain(dt)
    for i, drop in ipairs(rainParticles) do
        drop.y = drop.y + drop.speed * dt
        drop.x = drop.x - 50 * dt -- Diagonal rain
        
        if drop.y > love.graphics.getHeight() + 50 then
            drop.y = -50
            drop.x = math.random(0, love.graphics.getWidth() + 100)
        end
    end
end

function Weather:updateLightning(dt)
    lightningTimer = lightningTimer + dt
    
    -- Random lightning strikes
    if lightningTimer > math.random(3, 8) then
        lightningFlash = 1.0
        lightningTimer = 0
        
        -- Lightning reveals things in the water briefly
        if _G.addHorrorFlicker then
            _G.addHorrorFlicker(0.1) -- Very brief flash
        end
        
        print("⚡ Lightning illuminates the water...")
    end
    
    -- Fade lightning flash
    if lightningFlash > 0 then
        lightningFlash = math.max(0, lightningFlash - dt * 5)
    end
end

function Weather:updateTransitions(dt)
    -- Smooth transitions between weather states
    -- This is handled in the drawing functions
end

function Weather:draw()
    -- Draw weather effects
    if currentWeather == "rain" or currentWeather == "storm" then
        self:drawRain()
    end
    
    if currentWeather == "storm" and lightningFlash > 0 then
        self:drawLightning()
    end
    
    -- Fog vignette overlay (always active during fog, intensified at night)
    if currentWeather == "fog" then
        self:drawFogVignette()
    end
end

--- Draw a subtle fog vignette that creeps in from the screen edges.
-- During daytime this is a light grey haze; at night it becomes a cold
-- blue-grey mist that reduces peripheral visibility and adds dread.
function Weather:drawFogVignette()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Check if it's night for the darker fog variant
    local DayNightCycle = require("world.daynightcycle")
    local isNight = false
    if type(DayNightCycle.isNightTime) == "function" then
        isNight = DayNightCycle:isNightTime()
    end
    
    -- Base alpha: subtle during day, more oppressive at night
    local baseAlpha = isNight and 0.35 or 0.2
    
    -- Slow pulsing for organic feel (breathing fog)
    local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 0.5)
    local alpha = baseAlpha * pulse
    
    if isNight then
        -- Night fog: cold blue-grey, heavier at edges
        love.graphics.setColor(0.15, 0.18, 0.28, alpha)
    else
        -- Day fog: neutral grey, lighter
        love.graphics.setColor(0.6, 0.65, 0.7, alpha * 0.6)
    end
    
    -- Draw layered edge strips for a soft vignette effect
    local stripWidth = w * 0.18
    local stripHeight = h * 0.15
    
    -- Top
    love.graphics.rectangle("fill", 0, 0, w, stripHeight)
    -- Bottom
    love.graphics.rectangle("fill", 0, h - stripHeight, w, stripHeight)
    -- Left
    love.graphics.rectangle("fill", 0, 0, stripWidth, h)
    -- Right
    love.graphics.rectangle("fill", w - stripWidth, 0, stripWidth, h)
    
    -- Inner layer (slightly less opaque for depth)
    local innerAlpha = alpha * 0.5
    if isNight then
        love.graphics.setColor(0.12, 0.14, 0.22, innerAlpha)
    else
        love.graphics.setColor(0.55, 0.6, 0.65, innerAlpha)
    end
    
    local innerW = w * 0.3
    local innerH = h * 0.25
    love.graphics.rectangle("fill", 0, 0, w, innerH)
    love.graphics.rectangle("fill", 0, h - innerH, w, innerH)
    love.graphics.rectangle("fill", 0, 0, innerW, h)
    love.graphics.rectangle("fill", w - innerW, 0, innerW, h)
    
    -- Subtle horizontal mist bands drifting across the screen
    local t = love.timer.getTime()
    if isNight then
        love.graphics.setColor(0.2, 0.22, 0.35, alpha * 0.3)
    else
        love.graphics.setColor(0.7, 0.72, 0.78, alpha * 0.2)
    end
    for i = 1, 3 do
        local bandY = (h * 0.3) + (i * h * 0.2) + math.sin(t * 0.3 + i * 2) * 15
        love.graphics.rectangle("fill", 0, bandY, w, 8 + i * 4)
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

function Weather:drawRain()
    love.graphics.setColor(0.7, 0.7, 1, 0.6)
    love.graphics.setLineWidth(2)
    
    for _, drop in ipairs(rainParticles) do
        love.graphics.setColor(0.7, 0.7, 1, drop.alpha)
        love.graphics.line(drop.x, drop.y, drop.x - 10, drop.y + drop.length)
    end
    
    love.graphics.setLineWidth(1) -- Reset
end

function Weather:drawLightning()
    if lightningFlash > 0 then
        -- Full screen flash
        love.graphics.setColor(1, 1, 1, lightningFlash * 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Lightning bolt in the sky
        love.graphics.setColor(1, 1, 0.8, lightningFlash)
        love.graphics.setLineWidth(3)
        local x = math.random(100, love.graphics.getWidth() - 100)
        love.graphics.line(x, 0, x + math.random(-50, 50), love.graphics.getHeight() * 0.3)
        love.graphics.setLineWidth(1)
    end
end

--- Get the active weather modifiers as a flat table.
-- Returns fields that downstream systems (bitedetection, fishdata) can use:
--   biteSpeedMult  : multiply bite delay by this (lower = faster bites)
--   rarityBoost    : additive bonus to rare/horror fish selection weight
--   isRaining      : boolean convenience flag
--   isFog          : boolean convenience flag
function Weather:getModifiers()
    local data = weatherTypes[currentWeather]
    return {
        biteSpeedMult = data.biteSpeedMult or 1.0,
        rarityBoost = data.rarityBoost or 0.0,
        isRaining = (currentWeather == "rain" or currentWeather == "storm"),
        isFog = (currentWeather == "fog"),
    }
end

-- Getters for other systems
function Weather:getCurrentWeather()
    return currentWeather
end

function Weather:getWeatherData()
    local data = weatherTypes[currentWeather]
    -- Return a copy with modifier fields so consumers can check .isRaining / .biteSpeedMult
    -- without mutating the shared table.
    local result = {}
    for k, v in pairs(data) do result[k] = v end
    result.isRaining = (currentWeather == "rain" or currentWeather == "storm")
    result.isFog = (currentWeather == "fog")
    return result
end

function Weather:getFishingMultiplier()
    return weatherTypes[currentWeather].fishingMultiplier
end


function Weather:getCastingAccuracy()
    return weatherTypes[currentWeather].castingAccuracy
end

function Weather:getVisibilityRange()
    return weatherTypes[currentWeather].visibilityRange
end

function Weather:getWindEffect()
    return {
        strength = windStrength,
        direction = windDirection
    }
end

return Weather
