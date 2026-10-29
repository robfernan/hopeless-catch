-- Visual Tacklebox System
-- Beautiful tacklebox interface that showcases bait/lures with custom art

local VisualTacklebox = {}
local Assets = require("assets")

-- Tacklebox state
local isOpen = false
local selectedSlot = 1
local animationTimer = 0
local tackleboxAlpha = 0

-- Layout configuration
local layout = {
    slotsPerRow = 4,
    slotSize = 80,
    slotSpacing = 10,
    padding = 20,
    headerHeight = 60
}

function VisualTacklebox:init()
    -- Any initialization needed
end

function VisualTacklebox:toggle()
    isOpen = not isOpen
    animationTimer = 0
    if isOpen then
        selectedSlot = 1
        print("Visual tacklebox opened - Use arrow keys to navigate, SPACE to select")
    end
end

function VisualTacklebox:isOpen()
    return isOpen
end

function VisualTacklebox:update(dt)
    -- Smooth opening/closing animation
    if isOpen then
        tackleboxAlpha = math.min(1, tackleboxAlpha + dt * 4)
    else
        tackleboxAlpha = math.max(0, tackleboxAlpha - dt * 4)
    end
    
    animationTimer = animationTimer + dt
end

function VisualTacklebox:navigateUp()
    if selectedSlot > layout.slotsPerRow then
        selectedSlot = selectedSlot - layout.slotsPerRow
    end
end

function VisualTacklebox:navigateDown(totalBaits)
    if selectedSlot + layout.slotsPerRow <= totalBaits then
        selectedSlot = selectedSlot + layout.slotsPerRow
    end
end

function VisualTacklebox:navigateLeft()
    if selectedSlot > 1 then
        selectedSlot = selectedSlot - 1
    end
end

function VisualTacklebox:navigateRight(totalBaits)
    if selectedSlot < totalBaits then
        selectedSlot = selectedSlot + 1
    end
end

function VisualTacklebox:getSelectedSlot()
    return selectedSlot
end

function VisualTacklebox:draw(baitInventory)
    if tackleboxAlpha <= 0 then return end
    -- Minimal, presentable tackle box with 4 baits and their images
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local boxWidth, boxHeight = 420, 200
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2
    -- Draw tackle box background
    -- Draw tackle box background only (no fallback/extra grey boxes)
    love.graphics.setColor(1, 1, 1, tackleboxAlpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 16, 16)
    love.graphics.setColor(0.6, 0.6, 0.6, tackleboxAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 16, 16)

    -- Title inside the box
    love.graphics.setColor(0.2, 0.1, 0.05, tackleboxAlpha)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf("Tackle Box", boxX, boxY + 10, boxWidth, "center")
    love.graphics.setFont(love.graphics.newFont(14))

    -- Slot layout
    local slotSize = 80
    local slotSpacing = 20
    local slotsPerRow = 4
    local slotY = boxY + (boxHeight - slotSize) / 2
    for i = 1, slotsPerRow do
        local slotX = boxX + slotSpacing + (i - 1) * (slotSize + slotSpacing)
        local bait = baitInventory[i]
        -- Highlight selected slot
        if i == selectedSlot then
            love.graphics.setColor(0.95, 0.9, 0.6, tackleboxAlpha)
            love.graphics.rectangle("fill", slotX - 3, slotY - 3, slotSize + 6, slotSize + 6, 12, 12)
        end
        love.graphics.setColor(1, 1, 1, tackleboxAlpha)
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 10, 10)
        love.graphics.setColor(0.6, 0.6, 0.6, tackleboxAlpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 10, 10)
        if bait then
            -- Draw bait image (or placeholder) to fill the slot box, perfectly centered
            local img = Assets:getImage("bait_" .. bait.name:lower())
            if img then
                local imgW, imgH = img:getWidth(), img:getHeight()
                local scale = math.min(slotSize / imgW, slotSize / imgH)
                local drawX = slotX + (slotSize - imgW * scale) / 2
                local drawY = slotY + (slotSize - imgH * scale) / 2
                love.graphics.setColor(1, 1, 1, tackleboxAlpha)
                love.graphics.draw(img, drawX, drawY, 0, scale, scale)
            end
            love.graphics.setColor(0.2, 0.1, 0.05, tackleboxAlpha)
            love.graphics.printf(bait.name, slotX, slotY + slotSize + 6, slotSize, "center")
            -- No bait count displayed; bait is unlimited
        end
    end

    -- Controls text centered below bait names
    local controlsY = boxY + boxHeight - 32
    love.graphics.setColor(0.2, 0.1, 0.05, tackleboxAlpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Arrows: Move | SPACE: Select | B: Close/Open Tacklebox", boxX, controlsY, boxWidth, "center")
end

return VisualTacklebox
