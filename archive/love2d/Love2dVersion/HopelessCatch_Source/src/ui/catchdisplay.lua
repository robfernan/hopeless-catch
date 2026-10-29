-- src/ui/catchdisplay.lua - Dramatic Catch Reveal Modal
local Assets = require("src.core.assets")

local CatchDisplay = {}

function CatchDisplay.draw(w, h, fish)
    if not fish then return end
    
    -- Semi-transparent backdrop overlay
    love.graphics.setColor(0.01, 0.01, 0.02, 0.88)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local modalW = 520
    local modalH = 340
    local mx = (w - modalW) * 0.5
    local my = (h - modalH) * 0.5
    
    -- Modal Container
    love.graphics.setColor(0.06, 0.07, 0.10, 0.98)
    love.graphics.rectangle("fill", mx, my, modalW, modalH, 8, 8)
    love.graphics.setColor(0.55, 0.25, 0.18, 1.0)
    love.graphics.rectangle("line", mx, my, modalW, modalH, 8, 8)
    
    -- Catch Title
    love.graphics.setFont(Assets.fonts.large)
    love.graphics.setColor(0.95, 0.85, 0.70, 1.0)
    love.graphics.printf("YOU HAULED FROM THE DEEP", mx, my + 20, modalW, "center")
    
    love.graphics.setFont(Assets.fonts.title)
    love.graphics.setColor(0.95, 0.35, 0.25, 1.0)
    love.graphics.printf(fish.name:upper(), mx, my + 55, modalW, "center")
    
    -- Render Fish / Boss Sprite
    local img = Assets.getImage(fish.asset)
    if img then
        if fish.id == "fishman" and Assets.quads.fishman then
            local q = (math.sin(love.timer.getTime() * 4) > 0) and Assets.quads.fishman.roar or Assets.quads.fishman.strike
            local _, _, qw, qh = q:getViewport()
            local scale = 140 / qh
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, w * 0.5, my + 150, 0, scale, scale, qw * 0.5, qh * 0.5)
        else
            local iw = img:getWidth()
            local ih = img:getHeight()
            local scale = 110 / ih
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, w * 0.5, my + 150, 0, scale, scale, iw * 0.5, ih * 0.5)
        end
    end
    
    -- Fish Lore / Creepy Narrative Note
    love.graphics.setFont(Assets.fonts.medium)
    love.graphics.setColor(0.85, 0.80, 0.75, 0.95)
    love.graphics.printf(fish.desc, mx + 30, my + 215, modalW - 60, "center")
    
    if fish.nightNarrative then
        love.graphics.setFont(Assets.fonts.small)
        love.graphics.setColor(0.85, 0.45, 0.40, 0.95)
        love.graphics.printf(string.format('"%s"', fish.nightNarrative), mx + 30, my + 260, modalW - 60, "center")
    end
    
    -- Dismiss Prompt
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.65, 0.60, 0.55, 0.85)
    love.graphics.printf("PRESS SPACE OR ENTER TO KEEP", mx, my + modalH - 28, modalW, "center")
end

return CatchDisplay
