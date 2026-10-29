-- world/skyrenderer.lua - Sky gradient, sun, moon, stars, and clouds
local SkyRenderer = {}

function SkyRenderer:drawSky(timeOfDay)
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Dynamic sky color based on time
    local skyColors = self:getSkyColors(timeOfDay)
    
    -- Draw gradient sky
    local mesh = love.graphics.newMesh(4, "strip", "static")
    mesh:setVertices({
        {0, 0, 0, 0, skyColors.top.r, skyColors.top.g, skyColors.top.b, skyColors.top.a},
        {width, 0, 1, 0, skyColors.top.r, skyColors.top.g, skyColors.top.b, skyColors.top.a},
        {0, height * 0.7, 0, 1, skyColors.horizon.r, skyColors.horizon.g, skyColors.horizon.b, skyColors.horizon.a},
        {width, height * 0.7, 1, 1, skyColors.horizon.r, skyColors.horizon.g, skyColors.horizon.b, skyColors.horizon.a}
    })
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh)
end

function SkyRenderer:getSkyColors(timeOfDay)
    local colors = {}
    
    if timeOfDay >= 0.0 and timeOfDay < 0.25 then -- Dawn (5-11 AM)
        local t = timeOfDay / 0.25
        colors.top = {r = 0.4 + t * 0.4, g = 0.5 + t * 0.3, b = 0.8, a = 1}
        colors.horizon = {r = 0.8 + t * 0.2, g = 0.4 + t * 0.4, b = 0.6 + t * 0.2, a = 1}
        
    elseif timeOfDay >= 0.25 and timeOfDay < 0.5 then -- Day (11 AM - 5 PM)
        colors.top = {r = 0.5, g = 0.8, b = 1, a = 1}
        colors.horizon = {r = 0.8, g = 0.9, b = 1, a = 1}
        
    elseif timeOfDay >= 0.5 and timeOfDay < 0.75 then -- Sunset (5-11 PM)
        local t = (timeOfDay - 0.5) / 0.25
        colors.top = {r = 0.8 - t * 0.3, g = 0.4 - t * 0.2, b = 0.6 - t * 0.4, a = 1}
        colors.horizon = {r = 1, g = 0.5 - t * 0.2, b = 0.3 - t * 0.2, a = 1}
        
    else -- Night (11 PM - 5 AM)
        colors.top = {r = 0.1, g = 0.1, b = 0.3, a = 1}
        colors.horizon = {r = 0.2, g = 0.2, b = 0.4, a = 1}
    end
    
    return colors
end

function SkyRenderer:drawCelestialBodies(timeOfDay, width, height)
    -- Sun position (moves across sky during day)
    if timeOfDay > 0.2 and timeOfDay < 0.8 then
        local sunProgress = (timeOfDay - 0.2) / 0.6 -- 0 to 1 across day
        local sunX = width * (0.1 + sunProgress * 0.8)
        local sunY = height * (0.6 - math.sin(sunProgress * math.pi) * 0.4)
        
        -- Sun glow
        love.graphics.setColor(1, 1, 0.8, 0.3)
        love.graphics.circle("fill", sunX, sunY, 60)
        
        -- Sun
        love.graphics.setColor(1, 1, 0.9, 0.9)
        love.graphics.circle("fill", sunX, sunY, 40)
        
        -- Sun rays
        love.graphics.setColor(1, 1, 0.8, 0.2)
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2 + love.timer.getTime() * 0.5
            local rayX = sunX + math.cos(angle) * 80
            local rayY = sunY + math.sin(angle) * 80
            love.graphics.line(sunX + math.cos(angle) * 50, sunY + math.sin(angle) * 50, rayX, rayY)
        end
    end
    
    -- Moon position (visible during night)
    if timeOfDay < 0.2 or timeOfDay > 0.8 then
        local moonProgress
        if timeOfDay > 0.8 then
            moonProgress = (timeOfDay - 0.8) / 0.4 -- 0.8 to 1.0
        else
            moonProgress = (timeOfDay + 0.2) / 0.4 -- 0 to 0.2, normalized
        end
        
        local moonX = width * (0.2 + moonProgress * 0.6)
        local moonY = height * (0.5 - math.sin(moonProgress * math.pi) * 0.3)
        
        -- Moon glow
        love.graphics.setColor(0.8, 0.8, 1, 0.4)
        love.graphics.circle("fill", moonX, moonY, 45)
        
        -- Moon
        love.graphics.setColor(0.9, 0.9, 1, 0.9)
        love.graphics.circle("fill", moonX, moonY, 30)
        
        -- Moon craters
        love.graphics.setColor(0.7, 0.7, 0.9, 0.5)
        love.graphics.circle("fill", moonX - 8, moonY - 5, 4)
        love.graphics.circle("fill", moonX + 5, moonY + 3, 3)
        love.graphics.circle("fill", moonX - 2, moonY + 8, 2)
    end
end

function SkyRenderer:drawStars(timeOfDay, waterY)
    local width = love.graphics.getWidth()
    local starAlpha = 1
    
    -- Fade stars during dawn/dusk
    if timeOfDay > 0.15 and timeOfDay < 0.35 then
        starAlpha = math.max(0, 1 - (timeOfDay - 0.15) / 0.2)
    elseif timeOfDay > 0.65 and timeOfDay < 0.85 then
        starAlpha = math.min(1, (timeOfDay - 0.65) / 0.2)
    end
    
    love.graphics.setColor(1, 1, 1, starAlpha * 0.8)
    for i = 1, 50 do
        local x = (i * 123 + 50) % width
        local y = (i * 67 + 30) % (waterY * 0.8)
        local twinkle = math.sin(love.timer.getTime() * 3 + i) * 0.3 + 0.7
        love.graphics.setColor(1, 1, 1, starAlpha * twinkle)
        love.graphics.circle("fill", x, y, 1)
    end
end

function SkyRenderer:drawClouds(timeOfDay, waterY)
    local width = love.graphics.getWidth()
    local cloudAlpha = timeOfDay > 0.2 and timeOfDay < 0.8 and 0.7 or 0.3
    love.graphics.setColor(1, 1, 1, cloudAlpha)
    
    -- Animated clouds
    local cloudOffset = love.timer.getTime() * 5
    
    -- Cloud formation 1
    local cloud1X = (150 + cloudOffset) % (width + 200) - 100
    love.graphics.circle("fill", cloud1X, waterY * 0.2, 25)
    love.graphics.circle("fill", cloud1X + 20, waterY * 0.2 - 5, 20)
    love.graphics.circle("fill", cloud1X + 40, waterY * 0.2, 15)
    
    -- Cloud formation 2
    local cloud2X = (400 + cloudOffset * 0.7) % (width + 200) - 100
    love.graphics.circle("fill", cloud2X, waterY * 0.15, 20)
    love.graphics.circle("fill", cloud2X + 15, waterY * 0.15 - 3, 18)
    love.graphics.circle("fill", cloud2X + 30, waterY * 0.15 + 2, 12)
    
    -- Cloud formation 3
    local cloud3X = (600 + cloudOffset * 1.3) % (width + 200) - 100
    love.graphics.circle("fill", cloud3X, waterY * 0.25, 15)
    love.graphics.circle("fill", cloud3X + 12, waterY * 0.25, 12)
    love.graphics.circle("fill", cloud3X + 22, waterY * 0.25 + 1, 10)
end

return SkyRenderer
