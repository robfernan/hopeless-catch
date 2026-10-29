-- src/world/terrain.lua - Shoreline, Dilapidated Cabin, and Wooden Pier
local Terrain = {}

-- Distant Background Layer (Rendered BEHIND water and sky horizon)
function Terrain.drawBackground(w, h, dayNight)
    local amb = dayNight.getAmbientColor()
    local horizonY = h * 0.44
    
    -- Distant Mountain Ridges across the far lake (Sitting behind water surface)
    love.graphics.setColor(amb[1] * 0.35, amb[2] * 0.42, amb[3] * 0.55, 0.90)
    local mountainPoly = {
        0, horizonY,
        w * 0.18, horizonY - 80,
        w * 0.40, horizonY - 45,
        w * 0.65, horizonY - 110,
        w * 0.88, horizonY - 55,
        w, horizonY - 75,
        w, horizonY,
        0, horizonY
    }
    love.graphics.polygon("fill", mountainPoly)
    
    -- Distant Forested shoreline along the horizon
    love.graphics.setColor(amb[1] * 0.25, amb[2] * 0.32, amb[3] * 0.28, 1.0)
    love.graphics.rectangle("fill", 0, horizonY - 8, w, 8)
    for x = 10, w, 28 do
        local th = 16 + (x % 5) * 4
        love.graphics.polygon("fill", x - 8, horizonY, x + 8, horizonY, x, horizonY - th)
    end
end

-- Foreground Pier Layer (Rendered OVER the water surface in front of player)
function Terrain.draw(w, h, dayNight)
    local amb = dayNight.getAmbientColor()
    
    -- Compact Foreground Pier (Fisherman stands at the front edge, open lake water directly in front)
    local dockEdgeY = h * 0.78
    local dockNearY = h + 20
    local dockFarW = w * 0.60
    local dockNearW = w * 0.82
    
    local fx1 = (w - dockFarW) * 0.5
    local fx2 = (w + dockFarW) * 0.5
    local px1 = (w - dockNearW) * 0.5
    local px2 = (w + dockNearW) * 0.5
    
    -- Heavy support pilings plunging down into the water beneath the front edge
    love.graphics.setColor(0.10, 0.07, 0.05, 1.0)
    local pilingSpacing = (fx2 - fx1) / 5
    for p = 0, 5 do
        local pilX = fx1 + p * pilingSpacing - 8
        love.graphics.rectangle("fill", pilX, dockEdgeY, 16, 45)
        -- Water contact shadow & dark waterline scum
        love.graphics.setColor(0.04, 0.08, 0.12, 0.8)
        love.graphics.rectangle("fill", pilX - 2, dockEdgeY + 28, 20, 6)
        love.graphics.setColor(0.10, 0.07, 0.05, 1.0)
    end
    
    -- Wooden deck surface
    love.graphics.setColor(0.32, 0.23, 0.16, 1.0)
    love.graphics.polygon("fill", px1, dockNearY, px2, dockNearY, fx2, dockEdgeY, fx1, dockEdgeY)
    
    -- Perspective deck planks running horizontally
    love.graphics.setColor(0.18, 0.12, 0.08, 0.9)
    love.graphics.setLineWidth(2)
    local numPlanks = 6
    for i = 1, numPlanks do
        local frac = (i / numPlanks)^1.3
        local y = dockEdgeY + (dockNearY - dockEdgeY) * frac
        local leftX = fx1 + (px1 - fx1) * frac
        local rightX = fx2 + (px2 - fx2) * frac
        love.graphics.line(leftX, y, rightX, y)
        
        -- Nail heads on planks
        love.graphics.setColor(0.12, 0.08, 0.05, 1.0)
        for n = 1, 4 do
            local nx = leftX + (rightX - leftX) * (n / 5)
            love.graphics.circle("fill", nx, y - 4, 1.5)
        end
        love.graphics.setColor(0.18, 0.12, 0.08, 0.9)
    end
    love.graphics.setLineWidth(1)
    
    -- Front edge heavy bumper beam (prevents boats bumping, borders the water)
    love.graphics.setColor(0.24, 0.17, 0.11, 1.0)
    love.graphics.rectangle("fill", fx1 - 4, dockEdgeY - 4, dockFarW + 8, 12)
    love.graphics.setColor(0.14, 0.09, 0.05, 1.0)
    love.graphics.rectangle("line", fx1 - 4, dockEdgeY - 4, dockFarW + 8, 12)
    
    -- Left and Right Corner Mooring Posts (Bollards)
    local postW, postH = 18, 48
    love.graphics.setColor(0.18, 0.12, 0.08, 1.0)
    love.graphics.rectangle("fill", fx1 - 10, dockEdgeY - 32, postW, postH)
    love.graphics.rectangle("fill", fx2 - 8, dockEdgeY - 32, postW, postH)
    -- Post caps
    love.graphics.setColor(0.25, 0.18, 0.12, 1.0)
    love.graphics.circle("fill", fx1 - 1, dockEdgeY - 32, 9)
    love.graphics.circle("fill", fx2 + 1, dockEdgeY - 32, 9)
    -- Mooring rope coils on right post
    love.graphics.setColor(0.55, 0.48, 0.35, 1.0)
    love.graphics.rectangle("fill", fx2 - 10, dockEdgeY - 14, postW + 4, 6)
    
    -- Hanging Lantern on Left Mooring Post
    local lx = fx1 - 18
    local ly = dockEdgeY - 26
    love.graphics.setColor(0.15, 0.15, 0.15, 1.0)
    -- Bracket arm
    love.graphics.line(fx1 - 1, dockEdgeY - 26, lx + 6, ly)
    love.graphics.rectangle("fill", lx, ly, 12, 22)
    love.graphics.circle("fill", lx + 6, ly, 6)
    -- Glowing lantern core
    local lFlick = 0.85 + 0.15 * math.sin(love.timer.getTime() * 8)
    love.graphics.setColor(1.0, 0.8, 0.35, 0.95 * lFlick)
    love.graphics.circle("fill", lx + 6, ly + 10, 6)
    
    -- Tackle bucket on right side of dock
    local bx = fx2 - 60
    local by = dockEdgeY + 12
    love.graphics.setColor(0.2, 0.25, 0.28, 1.0)
    love.graphics.polygon("fill", bx, by + 18, bx + 18, by + 18, bx + 16, by, bx + 2, by)
    love.graphics.setColor(0.7, 0.6, 0.3, 0.8)
    love.graphics.circle("fill", bx + 9, by + 2, 7) -- bait inside bucket
end

function Terrain.getDockBounds(w, h)
    local horizonY = h * 0.44
    local dockEdgeY = h * 0.78
    local dockFarW = w * 0.60
    local fx1 = (w - dockFarW) * 0.5
    local fx2 = (w + dockFarW) * 0.5
    
    local minX = fx1 + 45
    local maxX = fx2 - 45
    local standY = dockEdgeY + 6 -- Fisherman's boots touch the front bumper planks
    local lanternX = fx1 - 12
    local lanternY = dockEdgeY - 16
    
    return minX, maxX, standY, horizonY, dockEdgeY, lanternX, lanternY
end

return Terrain
