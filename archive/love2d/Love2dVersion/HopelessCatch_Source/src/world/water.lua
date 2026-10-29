local Assets = require("src.core.assets")

local Water = {
    timer = 0
}

function Water.update(dt)
    Water.timer = Water.timer + dt
end

function Water.draw(w, h, dayNight)
    local waterY = h * 0.44
    local amb = dayNight.getAmbientColor()
    local t = Water.timer
    local img = Assets.getImage("water_retro")
    
    local tideRot = math.min(1.0, (dayNight.rottenTideLevel - 1.0) * 0.5)
    
    -- Mode-7 Style 2.5D Perspective Strip Projection (Sega Model 2 / Arcade depth)
    local totalSlices = 50
    local sliceH = (h - waterY) / totalSlices
    
    for i = 0, totalSlices - 1 do
        local y = waterY + i * sliceH
        local depthFrac = i / totalSlices -- 0 = far horizon, 1 = close to camera
        
        -- Perspective scaling (nearer slices stretch wider and move faster)
        local z = 1.0 / (0.12 + depthFrac * 0.88)
        local waveDistort = math.sin(t * 1.5 + depthFrac * 10) * (3 * depthFrac)
        
        -- Depth color fade: dark abyss at horizon, richer detailed water near shore
        local depthDarken = 0.45 + 0.55 * depthFrac
        local r, g, b
        if not dayNight.isNight then
            -- Vibrant sparkling daytime lake water
            r = (0.08 + 0.08 * depthFrac) * (1 - tideRot * 0.4) + (0.25 * tideRot)
            g = (0.32 + 0.16 * depthFrac) * (1 - tideRot * 0.4) + (0.10 * tideRot)
            b = (0.58 + 0.22 * depthFrac) * (1 - tideRot * 0.4) + (0.08 * tideRot)
        else
            -- Nighttime deep water
            r = (amb[1] * 0.25 * (1 - tideRot) + 0.20 * tideRot) * depthDarken
            g = (amb[2] * 0.35 * (1 - tideRot) + 0.10 * tideRot) * depthDarken
            b = (amb[3] * 0.55 * (1 - tideRot) + 0.08 * tideRot) * depthDarken
        end
        
        if img then
            local uOffset = (t * 0.04) + waveDistort * 0.01
            local vOffset = (depthFrac * 2.5) - (t * 0.06)
            local uScale = 1.8 * z
            
            local quad = love.graphics.newQuad(
                uOffset * img:getWidth(),
                vOffset * img:getHeight(),
                w, 
                sliceH * 2.0, 
                img:getDimensions()
            )
            
            love.graphics.setColor(r * 1.5, g * 1.5, b * 1.5, 0.98)
            love.graphics.draw(img, quad, 0, y)
        else
            love.graphics.setColor(r, g, b, 0.95)
            love.graphics.rectangle("fill", 0, y, w, sliceH + 1)
        end
        
        -- 2.5D Retro Specular Arcade Crests
        if (i % 4 == 0) and depthFrac > 0.15 then
            local foamAlpha = (0.25 + 0.2 * math.sin(t * 2.5 + i)) * depthFrac
            love.graphics.setColor(1, 1, 1, foamAlpha * (1 - tideRot * 0.5))
            local crestY = y + math.sin(t * 2.0 + depthFrac * 15) * 2
            love.graphics.rectangle("fill", (t * 25 * z) % w, crestY, 35 * z, 1.5)
            love.graphics.rectangle("fill", ((t * -18 * z) + w * 0.5) % w, crestY, 25 * z, 1.5)
        end
    end
    
    -- Forbidden Waters Warning Buoy line (far left, floating with 2.5D perspective)
    local buoyX = w * 0.14
    local buoyBob = math.sin(t * 2.2) * 4
    love.graphics.setColor(0.75, 0.2, 0.15, 1.0)
    love.graphics.circle("fill", buoyX, waterY + 18 + buoyBob, 8)
    love.graphics.setColor(0.95, 0.95, 0.95, 0.9)
    love.graphics.rectangle("fill", buoyX - 1, waterY + 8 + buoyBob, 2, 10)
    love.graphics.setColor(1, 0.2, 0.2, 0.4 + 0.3 * math.sin(t * 4))
    love.graphics.circle("fill", buoyX, waterY + 6 + buoyBob, 4)
end

return Water
