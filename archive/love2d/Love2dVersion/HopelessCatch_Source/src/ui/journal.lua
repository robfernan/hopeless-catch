-- src/ui/journal.lua - Weathered Field Notebook with Sketches & Cryptic Observations
local Assets = require("src.core.assets")

local Journal = {
    entries = {},
    selectedDay = 1
}

function Journal.addCatch(day, fish)
    table.insert(Journal.entries, {
        day = day,
        name = fish.name,
        asset = fish.asset,
        desc = fish.desc,
        narrative = fish.nightNarrative,
        time = os.date("%H:%M")
    })
end

function Journal.draw(w, h, currentDay)
    love.graphics.setColor(0.01, 0.02, 0.04, 0.92)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local bookW = 740
    local bookH = 490
    local bx = (w - bookW) * 0.5
    local by = (h - bookH) * 0.5
    
    -- Weathered dark leather book cover
    love.graphics.setColor(0.22, 0.16, 0.12, 1.0)
    love.graphics.rectangle("fill", bx - 10, by - 8, bookW + 20, bookH + 16, 12, 12)
    love.graphics.setColor(0.12, 0.08, 0.05, 1.0)
    love.graphics.rectangle("line", bx - 10, by - 8, bookW + 20, bookH + 16, 12, 12)
    
    -- Parchment paper pages (Left & Right page fold)
    local pageW = (bookW - 14) * 0.5
    local pageH = bookH - 12
    local pageY = by + 6
    
    -- Left Page
    love.graphics.setColor(0.92, 0.88, 0.78, 1.0)
    love.graphics.rectangle("fill", bx + 6, pageY, pageW, pageH, 6, 6)
    -- Right Page
    love.graphics.setColor(0.90, 0.86, 0.76, 1.0)
    love.graphics.rectangle("fill", bx + 8 + pageW, pageY, pageW, pageH, 6, 6)
    
    -- Center book binding shadow
    love.graphics.setColor(0.18, 0.12, 0.08, 0.35)
    love.graphics.rectangle("fill", bx + pageW - 4, pageY, 16, pageH)
    
    -- Left Page: Journal Heading & Lake Lore
    love.graphics.setFont(Assets.fonts.large)
    love.graphics.setColor(0.20, 0.15, 0.12, 1.0)
    love.graphics.printf("FIELD JOURNAL", bx + 16, pageY + 20, pageW - 20, "center")
    
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.55, 0.22, 0.18, 1.0)
    love.graphics.printf("LAKE ACHERON  •  ROTTEN TIDE LOG", bx + 16, pageY + 48, pageW - 20, "center")
    
    love.graphics.setColor(0.35, 0.28, 0.22, 0.95)
    local introNotes = 
        "\"The water speaks when the sun sinks behind the pines.\n\n" ..
        "Every catch dredges up rot that was never meant for the light.\n\n" ..
        "Beware the trench beyond the red buoy. Do not fish there past midnight.\""
    love.graphics.printf(introNotes, bx + 24, pageY + 80, pageW - 36, "left")
    
    -- Summary Stats on Left Page
    love.graphics.setColor(0.25, 0.20, 0.16, 1.0)
    love.graphics.print(string.format("Current Day: %d", currentDay), bx + 28, pageY + 215)
    love.graphics.print(string.format("Recorded Hauls: %d", #Journal.entries), bx + 28, pageY + 240)
    
    -- Right Page: Recent Catch Records with Ink Sketches
    love.graphics.setFont(Assets.fonts.medium)
    love.graphics.setColor(0.22, 0.16, 0.12, 1.0)
    love.graphics.printf("RECENT SPECIMENS", bx + 10 + pageW, pageY + 20, pageW - 20, "center")
    
    local rx = bx + 24 + pageW
    local startY = pageY + 60
    
    if #Journal.entries == 0 then
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(0.50, 0.44, 0.38, 0.9)
        love.graphics.printf("The pages remain blank.\nCast your line to record findings.", rx, pageY + 160, pageW - 40, "center")
    else
        for i = math.max(1, #Journal.entries - 3), #Journal.entries do
            local e = Journal.entries[i]
            local rowY = startY + (i - math.max(1, #Journal.entries - 3)) * 88
            
            -- Ink sketch frame
            love.graphics.setColor(0.82, 0.76, 0.65, 0.9)
            love.graphics.rectangle("fill", rx, rowY, 56, 56, 4, 4)
            love.graphics.setColor(0.35, 0.28, 0.22, 0.6)
            love.graphics.rectangle("line", rx, rowY, 56, 56, 4, 4)
            
            -- Fish Sprite Ink Sketch
            local img = Assets.getImage(e.asset)
            if img then
                local iw = img:getWidth()
                local ih = img:getHeight()
                local scale = 44 / math.max(iw, ih)
                love.graphics.setColor(0.2, 0.18, 0.15, 0.9)
                love.graphics.draw(img, rx + 6, rowY + 6, 0, scale, scale)
            end
            
            -- Title & Observation
            love.graphics.setFont(Assets.fonts.medium)
            love.graphics.setColor(0.25, 0.18, 0.14, 1.0)
            love.graphics.print(string.format("Day %d — %s", e.day, e.name), rx + 66, rowY + 4)
            
            love.graphics.setFont(Assets.fonts.small)
            if e.narrative then
                love.graphics.setColor(0.70, 0.20, 0.15, 1.0)
                love.graphics.printf(string.format('"%s"', e.narrative), rx + 66, rowY + 28, pageW - 100, "left")
            else
                love.graphics.setColor(0.38, 0.32, 0.26, 0.95)
                love.graphics.printf(e.desc, rx + 66, rowY + 28, pageW - 100, "left")
            end
        end
    end
    
    -- Bookmark prompt
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.4, 0.35, 0.28, 0.9)
    love.graphics.printf("TAB / ESC — Close Field Log", bx, by + bookH - 22, bookW, "center")
end

return Journal
