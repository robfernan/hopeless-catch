-- src/world/skyrenderer.lua - Skybox, celestial bodies, and stars
local SkyRenderer = {
    stars = {}
}

function SkyRenderer.init()
    SkyRenderer.stars = {}
    for i = 1, 90 do
        table.insert(SkyRenderer.stars, {
            x = math.random() * 1280,
            y = math.random() * 340,
            size = math.random() * 1.8 + 0.8,
            twinkleSpeed = math.random() * 3 + 1,
            phase = math.random() * math.pi * 2
        })
    end
end

function SkyRenderer.draw(dayNight, w, h)
    local t = dayNight.time
    local amb = dayNight.getAmbientColor()
    local skyHeight = h * 0.65
    
    -- Sky Gradient
    local topCol, botCol
    if not dayNight.isNight then
        -- Bright radiant Sega arcade daytime sky
        local sunPower = math.sin((t - 0.25) / 0.50 * math.pi)
        topCol = { 0.20 + 0.05 * sunPower, 0.54 + 0.06 * sunPower, 0.92 }
        botCol = { 0.74 + 0.12 * sunPower, 0.88 + 0.08 * sunPower, 0.98 }
    elseif t < 0.28 or t > 0.72 then
        -- Dusk / Dawn Fiery Red Haze
        topCol = { amb[1] * 0.6, amb[2] * 0.4, amb[3] * 0.5 }
        botCol = { 0.85, 0.42, 0.25 }
    else
        -- Deep Celestial Midnight
        topCol = { 0.05, 0.07, 0.15 }
        botCol = { 0.14, 0.18, 0.32 }
    end
    
    local mesh = love.graphics.newMesh({
        {0, 0, 0, 0, topCol[1], topCol[2], topCol[3], 1},
        {w, 0, 1, 0, topCol[1], topCol[2], topCol[3], 1},
        {w, skyHeight, 1, 1, botCol[1], botCol[2], botCol[3], 1},
        {0, skyHeight, 0, 1, botCol[1], botCol[2], botCol[3], 1}
    }, "fan", "stream")
    love.graphics.draw(mesh)
    
    -- Stars during night
    if dayNight.isNight then
        local nightAlpha = math.sin((t > 0.78 and (t - 0.78)/0.22 or (0.22 - t)/0.22) * math.pi)
        local curTime = love.timer.getTime()
        for _, s in ipairs(SkyRenderer.stars) do
            local twinkle = 0.5 + 0.5 * math.sin(curTime * s.twinkleSpeed + s.phase)
            love.graphics.setColor(0.95, 0.95, 1.0, nightAlpha * twinkle)
            love.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
        end
    end
    
    -- Celestial Sun / Cursed Blood Moon
    local sunAngle = (t - 0.25) * math.pi * 2
    local cx = w * 0.5 + math.cos(sunAngle) * (w * 0.40)
    local cy = skyHeight * 0.52 - math.sin(sunAngle) * (skyHeight * 0.45)
    
    if dayNight.isNight then
        -- Cursed Blood Moon
        love.graphics.setColor(0.85, 0.22, 0.18, 0.85)
        love.graphics.circle("fill", cx, cy, 26)
        love.graphics.setColor(0.95, 0.45, 0.35, 0.3)
        love.graphics.circle("fill", cx, cy, 40)
    else
        -- Radiant Golden Arcade Sun & Sunburst
        love.graphics.setColor(1.0, 0.96, 0.80, 0.95)
        love.graphics.circle("fill", cx, cy, 30)
        love.graphics.setColor(1.0, 0.92, 0.65, 0.40)
        love.graphics.circle("fill", cx, cy, 48)
        love.graphics.setColor(1.0, 0.85, 0.50, 0.20)
        love.graphics.circle("fill", cx, cy, 75)
    end
end

return SkyRenderer
