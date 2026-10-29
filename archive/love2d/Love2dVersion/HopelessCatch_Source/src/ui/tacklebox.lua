-- src/ui/tacklebox.lua - Authentic Segmented Tackle Tray with Mouse & Keyboard Selection
local Assets = require("src.core.assets")
local BaitData = require("src.data.baitdata")

local TackleBox = {}

function TackleBox.draw(w, h)
    love.graphics.setColor(0.01, 0.02, 0.04, 0.90)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local modalW = 680
    local modalH = 460
    local mx = (w - modalW) * 0.5
    local my = (h - modalH) * 0.5
    
    -- Rugged tacklebox outer casing (hardened resin olive green with metal latches)
    love.graphics.setColor(0.16, 0.22, 0.18, 0.98)
    love.graphics.rectangle("fill", mx - 8, my - 8, modalW + 16, modalH + 16, 12, 12)
    love.graphics.setColor(0.28, 0.36, 0.30, 1.0)
    love.graphics.rectangle("line", mx - 8, my - 8, modalW + 16, modalH + 16, 12, 12)
    
    -- Inner compartment tray (classic ribbed translucent tackle compartments)
    love.graphics.setColor(0.10, 0.12, 0.14, 0.96)
    love.graphics.rectangle("fill", mx, my, modalW, modalH, 8, 8)
    
    -- Tray Header
    love.graphics.setFont(Assets.fonts.large)
    love.graphics.setColor(0.95, 0.88, 0.72, 1.0)
    love.graphics.printf("ANGLER'S TACKLE TRAY", mx, my + 16, modalW, "center")
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.65, 0.60, 0.52, 0.9)
    love.graphics.printf("Click on a compartment or use ↑↓ / ENTER to select active lure", mx, my + 44, modalW, "center")
    
    -- Render 5 Compartment Slots
    local startY = my + 68
    local mouseX, mouseY = love.mouse.getPosition()
    
    for i, b in ipairs(BaitData.inventory) do
        local isSel = (i == BaitData.selectedIdx)
        local slotY = startY + (i - 1) * 68
        local slotW = modalW - 40
        local slotX = mx + 20
        local slotH = 58
        
        -- Mouse hover detection
        local isHover = (mouseX >= slotX and mouseX <= slotX + slotW and mouseY >= slotY and mouseY <= slotY + slotH)
        
        -- Compartment recessed box
        if isSel then
            love.graphics.setColor(0.38, 0.18, 0.14, 0.95)
            love.graphics.rectangle("fill", slotX, slotY, slotW, slotH, 6, 6)
            love.graphics.setColor(0.95, 0.45, 0.30, 1.0)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", slotX, slotY, slotW, slotH, 6, 6)
            love.graphics.setLineWidth(1)
        elseif isHover then
            love.graphics.setColor(0.22, 0.25, 0.28, 0.9)
            love.graphics.rectangle("fill", slotX, slotY, slotW, slotH, 6, 6)
            love.graphics.setColor(0.6, 0.65, 0.7, 0.9)
            love.graphics.rectangle("line", slotX, slotY, slotW, slotH, 6, 6)
        else
            love.graphics.setColor(0.14, 0.16, 0.18, 0.8)
            love.graphics.rectangle("fill", slotX, slotY, slotW, slotH, 6, 6)
            love.graphics.setColor(0.25, 0.28, 0.32, 0.7)
            love.graphics.rectangle("line", slotX, slotY, slotW, slotH, 6, 6)
        end
        
        -- Inner compartment divider box with gentle highlight
        love.graphics.setColor(0.18, 0.22, 0.25, 0.95)
        love.graphics.rectangle("fill", slotX + 6, slotY + 6, 64, slotH - 12, 6, 6)
        love.graphics.setColor(0.35, 0.40, 0.45, 0.8)
        love.graphics.rectangle("line", slotX + 6, slotY + 6, 64, slotH - 12, 6, 6)
        
        -- Draw User Bait Sprite (from assets/bait/*.png)
        local iconCx = slotX + 38
        local iconCy = slotY + (slotH * 0.5)
        local img = Assets.getImage(b.asset)
        
        if img then
            -- Draw user sprite cleanly centered in the compartment box at 1.4x scale
            love.graphics.setColor(1, 1, 1, 1)
            local iw, ih = img:getDimensions()
            love.graphics.draw(img, iconCx, iconCy, 0, 1.4, 1.4, iw * 0.5, ih * 0.5)
        elseif b.id == "rotten_meat" then
            -- Putrid rotten purple & sickly green necrotic meat chunk
            love.graphics.setColor(0.48, 0.18, 0.35, 1.0)
            love.graphics.polygon("fill", iconCx - 14, iconCy + 8, iconCx + 14, iconCy + 10, iconCx + 12, iconCy - 8, iconCx - 10, iconCy - 10)
            love.graphics.setColor(0.35, 0.70, 0.30, 0.9) -- Rotten fungal spots
            love.graphics.circle("fill", iconCx - 4, iconCy + 2, 3)
            love.graphics.circle("fill", iconCx + 5, iconCy - 2, 2.5)
        end
        
        -- Bait Name & Quantity Badge
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(isSel and {1, 0.95, 0.85} or {0.85, 0.82, 0.78})
        love.graphics.print(b.name, slotX + 85, slotY + 8)
        
        -- Quantity Tag
        local countColor = (b.count > 0) and {0.35, 0.85, 0.45} or {0.85, 0.3, 0.25}
        love.graphics.setFont(Assets.fonts.small)
        love.graphics.setColor(countColor[1], countColor[2], countColor[3], 1.0)
        love.graphics.print(string.format("QTY: %d", b.count), slotX + 85, slotY + 34)
        
        -- Potency Rating
        love.graphics.setColor(0.9, 0.75, 0.3, 0.9)
        love.graphics.print(string.format("Potency: %.1fx", b.potency), slotX + 165, slotY + 34)
        
        -- Description
        love.graphics.setColor(0.65, 0.62, 0.58, 0.9)
        love.graphics.print(b.desc, slotX + 265, slotY + 20)
        
        -- Active selection badge
        if isSel then
            love.graphics.setColor(0.95, 0.45, 0.30, 1.0)
            love.graphics.print("★ READY", slotX + slotW - 75, slotY + 20)
        end
    end
    
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.65, 0.60, 0.55, 0.85)
    love.graphics.printf("Click compartment to equip  •  B / ESC to close tray", mx, my + modalH - 24, modalW, "center")
end

function TackleBox.updateInput(input, w, h)
    local modalW = 680
    local modalH = 460
    local mx = (w - modalW) * 0.5
    local my = (h - modalH) * 0.5
    local startY = my + 68
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Mouse click selection on compartment
    if input.isMousePressed(1) then
        for i = 1, #BaitData.inventory do
            local slotY = startY + (i - 1) * 68
            local slotW = modalW - 40
            local slotX = mx + 20
            local slotH = 58
            if mouseX >= slotX and mouseX <= slotX + slotW and mouseY >= slotY and mouseY <= slotY + slotH then
                BaitData.selectedIdx = i
                Assets.play("reel_click", 0.1, 0.6)
                break
            end
        end
    end
    
    if input.isPressed("up") then
        BaitData.selectedIdx = math.max(1, BaitData.selectedIdx - 1)
        Assets.play("reel_click", 0.05, 0.4)
    elseif input.isPressed("down") then
        BaitData.selectedIdx = math.min(#BaitData.inventory, BaitData.selectedIdx + 1)
        Assets.play("reel_click", 0.05, 0.4)
    end
end

return TackleBox
