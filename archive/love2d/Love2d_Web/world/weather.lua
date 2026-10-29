-- Weather.lua - Dynamic weather system that affects gameplay and horror
local Weather = {}

local currentWeather = "clear"
local forcedWeather = nil
local weatherTimer = 0
local weatherDuration = 0

local windStrength = 0
local windDirection = 0

-- Weather types and their effects
local weatherTypes = {
    clear = {
        name = "Clear",
        fishingMultiplier = 1.0,
        visibilityRange = 1.0,
        castingAccuracy = 1.0,
        duration = {60, 120} -- 1-2 minutes
    },
    rain = {
        name = "Rain",
        fishingMultiplier = 0.7, -- Harder to see bites
        visibilityRange = 0.6,
        castingAccuracy = 0.8,
        duration = {45, 90}
    },
    storm = {
        name = "Storm",
        fishingMultiplier = 0.3, -- Nearly impossible
        visibilityRange = 0.4,
        castingAccuracy = 0.5,
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

    local FishingSystem = require("fishing.fishing")
    local DayNightCycle = require("world.daynightcycle")
    local isNight = DayNightCycle:isNightTime()

    -- Weather probability based on horror level and time
    local weatherChances = {
        clear = 0.4,
        rain = 0.2,
        storm = (isNight) and 0.2 or 0.05,
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

-- Getters for other systems
function Weather:getCurrentWeather()
    return currentWeather
end

function Weather:getWeatherData()
    return weatherTypes[currentWeather]
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
