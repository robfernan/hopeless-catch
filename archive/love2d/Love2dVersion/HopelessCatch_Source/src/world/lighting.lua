-- src/world/lighting.lua - Ambient Darkness, Lantern Bloom, and Dread Vignette
local Lighting = {}

function Lighting.draw(w, h, dayNight, playerX, playerY, lanternX, lanternY)
    local amb = dayNight.getAmbientColor()
    
    -- Atmospheric night lighting
    if dayNight.isNight then
        local t = love.timer.getTime()
        local flick = 0.92 + 0.08 * math.sin(t * 8)
        
        -- Smooth dark-blue moonlit tint over the entire scene
        love.graphics.setColor(0.04, 0.06, 0.14, 0.50)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Switch to additive blending for smooth luminous lantern glows
        love.graphics.setBlendMode("add")
        
        -- 1. Pier Lantern Glow (emanates directly from the lantern on the left mooring post)
        local lx = lanternX or (w * 0.22)
        local ly = lanternY or (h * 0.76)
        
        love.graphics.setColor(0.40, 0.28, 0.10, 0.40 * flick)
        love.graphics.circle("fill", lx, ly, 160)
        love.graphics.setColor(0.65, 0.45, 0.18, 0.60 * flick)
        love.graphics.circle("fill", lx, ly, 80)
        love.graphics.setColor(0.95, 0.80, 0.45, 0.85 * flick)
        love.graphics.circle("fill", lx, ly, 28)
        
        -- 2. Fisherman Warm Ambient Aura (highlights character & rod against dark water)
        local px = playerX or (w * 0.5)
        local py = (playerY or (h * 0.78)) - 40
        
        love.graphics.setColor(0.20, 0.16, 0.08, 0.35 * flick)
        love.graphics.circle("fill", px, py, 110)
        love.graphics.setColor(0.45, 0.35, 0.18, 0.50 * flick)
        love.graphics.circle("fill", px, py, 45)
        
        -- Restore default alpha blend mode
        love.graphics.setBlendMode("alpha")
    end
    
    -- Creeping horror vignette around screen edges
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.setLineWidth(24)
    love.graphics.rectangle("line", 0, 0, w, h)
    love.graphics.setLineWidth(1)
end

return Lighting
