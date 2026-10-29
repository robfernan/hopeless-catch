-- src/world/weather.lua - Dynamic Weather, Lake Rain, Clouds, and Mist
local Assets = require("src.core.assets")

local Weather = {
    current = "sunny", -- "sunny", "rain", "fog", "storm"
    drops = {},
    ripples = {},
    clouds = {},
    fogTimer = 0,
    thunderTimer = 10,
    flashAlpha = 0
}

function Weather.init()
    Weather.drops = {}
    Weather.ripples = {}
    Weather.clouds = {}
    
    -- Generate drifting clouds
    for i = 1, 6 do
        table.insert(Weather.clouds, {
            x = math.random() * 1400 - 100,
            y = 30 + math.random() * 120,
            speed = 12 + math.random() * 18,
            width = 120 + math.random() * 100,
            height = 35 + math.random() * 25,
            alpha = 0.55 + math.random() * 0.3
        })
    end
    
    -- Generate pool of raindrops
    for i = 1, 140 do
        table.insert(Weather.drops, {
            x = math.random() * 1350,
            y = math.random() * 720,
            speed = 480 + math.random() * 220,
            length = 10 + math.random() * 8
        })
    end
end

function Weather.setWeather(weatherType)
    Weather.current = weatherType
    if (weatherType == "rain" or weatherType == "storm") and Assets.sounds.ambient_rain then
        if not Assets.sounds.ambient_rain:isPlaying() then
            Assets.sounds.ambient_rain:play()
        end
    else
        if Assets.sounds.ambient_rain and Assets.sounds.ambient_rain:isPlaying() then
            Assets.sounds.ambient_rain:stop()
        end
    end
end

function Weather.update(dt, dayNight, horizonY, dockEdgeY)
    horizonY = horizonY or 316
    dockEdgeY = dockEdgeY or 562
    
    -- Automatically set atmospheric weather based on in-game Day
    local targetWeather = "sunny"
    if dayNight.day == 2 then
        targetWeather = "rain"
    elseif dayNight.day == 3 then
        targetWeather = "fog"
    elseif dayNight.day >= 4 then
        targetWeather = (dayNight.rottenTideLevel > 1.8) and "storm" or "fog"
    end
    
    if Weather.current ~= targetWeather then
        Weather.setWeather(targetWeather)
    end
    
    -- Update clouds
    for _, c in ipairs(Weather.clouds) do
        c.x = c.x + c.speed * dt
        if c.x > 1350 then c.x = -c.width - 50 end
    end
    
    -- Update rain if active
    if Weather.current == "rain" or Weather.current == "storm" then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        
        for _, d in ipairs(Weather.drops) do
            d.y = d.y + d.speed * dt
            d.x = d.x - d.speed * dt * 0.22 -- wind angle
            
            -- Hit water surface
            if d.y >= horizonY and d.y <= dockEdgeY then
                if math.random() < 0.15 then
                    table.insert(Weather.ripples, {
                        x = d.x,
                        y = d.y,
                        radius = 2,
                        maxRadius = 8 + math.random() * 6,
                        alpha = 0.6
                    })
                end
            end
            
            if d.y > h then
                d.y = -20
                d.x = math.random() * (w + 200)
            end
        end
        
        -- Update rain ripples on lake
        for i = #Weather.ripples, 1, -1 do
            local r = Weather.ripples[i]
            r.radius = r.radius + dt * 18
            r.alpha = r.alpha - dt * 1.8
            if r.alpha <= 0 then
                table.remove(Weather.ripples, i)
            end
        end
        
        -- Storm lightning & thunder
        if Weather.current == "storm" then
            Weather.thunderTimer = Weather.thunderTimer - dt
            if Weather.thunderTimer <= 0 then
                Weather.flashAlpha = 0.85
                Weather.thunderTimer = 8 + math.random() * 12
                Assets.play("thunder", 0.1, 0.9)
            end
            if Weather.flashAlpha > 0 then
                Weather.flashAlpha = math.max(0, Weather.flashAlpha - dt * 3.5)
            end
        end
    end
    
    Weather.fogTimer = Weather.fogTimer + dt
end

function Weather.drawSky(w, h, dayNight)
    -- Sunny Clouds
    if Weather.current == "sunny" and not dayNight.isNight then
        for _, c in ipairs(Weather.clouds) do
            love.graphics.setColor(1.0, 1.0, 1.0, c.alpha * 0.75)
            love.graphics.rectangle("fill", c.x, c.y, c.width, c.height, 16, 16)
            love.graphics.rectangle("fill", c.x + 20, c.y - 12, c.width * 0.65, c.height + 14, 18, 18)
        end
    -- Overcast Rainy Sky Tint
    elseif Weather.current == "rain" or Weather.current == "storm" then
        love.graphics.setColor(0.12, 0.14, 0.18, 0.35)
        love.graphics.rectangle("fill", 0, 0, w, h * 0.44)
    end
end

function Weather.drawOverlays(w, h, horizonY, dockEdgeY)
    horizonY = horizonY or 316
    dockEdgeY = dockEdgeY or 562
    
    -- 1. Rain and Water Ripples
    if Weather.current == "rain" or Weather.current == "storm" then
        -- Falling raindrops
        love.graphics.setColor(0.85, 0.92, 1.0, (Weather.current == "storm") and 0.65 or 0.45)
        love.graphics.setLineWidth(1)
        for _, d in ipairs(Weather.drops) do
            love.graphics.line(d.x, d.y, d.x - 3, d.y + d.length)
        end
        
        -- Splash rings on water
        for _, r in ipairs(Weather.ripples) do
            love.graphics.setColor(0.85, 0.95, 1.0, r.alpha)
            love.graphics.ellipse("line", r.x, r.y, r.radius * 1.5, r.radius * 0.6)
        end
        
        -- Lightning flash
        if Weather.flashAlpha > 0 then
            love.graphics.setColor(1.0, 1.0, 1.0, Weather.flashAlpha)
            love.graphics.rectangle("fill", 0, 0, w, h)
        end
    end
    
    -- 2. Rolling Lake Fog / Rotten Tide Mist
    if Weather.current == "fog" or Weather.current == "storm" then
        local t = Weather.fogTimer
        love.graphics.setColor(0.75, 0.82, 0.88, 0.18)
        for f = 0, 3 do
            local fy = horizonY + f * 45
            local fx = math.sin(t * 0.4 + f) * 60
            love.graphics.rectangle("fill", fx - 100, fy, w + 200, 30 + f * 8)
        end
    end
end

return Weather
