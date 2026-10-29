-- ui/imgui/tacklebox.lua - Tackle box UI with Dear ImGui
local imgui = require("cimgui")

local TackleBox = {}
TackleBox.isOpen = false
TackleBox.selectedSlot = 1

function TackleBox:toggle()
    self.isOpen = not self.isOpen
    if self.isOpen then
        self.selectedSlot = 1
    end
end

function TackleBox:isOpen_()
    return self.isOpen
end

--- Draw the tackle box overlay. Returns true if a bait was selected this frame.
-- @param baitInventory table array of bait items from FishingSystem
function TackleBox:draw(baitInventory)
    if not self.isOpen then return false end
    
    local w, h = love.graphics.getDimensions()
    
    -- Dim background (Love2D layer)
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Panel dimensions
    local panelW = 480
    local slotSize = 90
    local slotsPerRow = 4
    local rows = math.ceil(#baitInventory / slotsPerRow)
    local panelH = 60 + rows * (slotSize + 30) + 50
    
    local px = (w - panelW) / 2
    local py = (h - panelH) / 2
    
    imgui.SetNextWindowPos(px, py)
    imgui.SetNextWindowSize(panelW, panelH)
    
    local flags = imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize 
                + imgui.WindowFlags_NoMove + imgui.WindowFlags_NoCollapse
                + imgui.WindowFlags_NoSavedSettings
    
    if not imgui.Begin("##TackleBox", nil, flags) then
        return false
    end
    
    -- Title
    local titleFont = love.graphics.newFont(24)
    imgui.PushStyleColor(imgui.Col_Text, {0.85, 0.78, 0.65, 1})
    imgui.Text("TACKLE BOX")
    imgui.PopStyleColor()
    
    -- Subtitle
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.42, 0.38, 0.8})
    imgui.Text("Select a bait to cast with")
    imgui.PopStyleColor()
    
    imgui.Separator()
    imgui.Spacing()
    
    -- Bait grid
    local selected = false
    for i, bait in ipairs(baitInventory) do
        if type(bait) ~= "table" then break end
        
        local col = (i - 1) % slotsPerRow
        local row = math.floor((i - 1) / slotsPerRow)
        
        -- Position each slot manually using BeginChild or just use a grid layout
        imgui.SetCursorPosX(20 + col * (slotSize + 15))
        imgui.SetCursorPosY(70 + row * (slotSize + 30))
        
        local isSelected = (self.selectedSlot == i)
        
        -- Selection highlight background
        if isSelected then
            imgui.PushStyleColor(imgui.Col_ChildBg, {0.35, 0.28, 0.15, 0.9})
            imgui.PushStyleColor(imgui.Col_Border, {0.7, 0.55, 0.3, 1})
        else
            imgui.PushStyleColor(imgui.Col_ChildBg, {0.12, 0.11, 0.10, 0.9})
            imgui.PushStyleColor(imgui.Col_Border, {0.25, 0.22, 0.18, 0.6})
        end
        
        -- Draw the slot as a child window (gives us border + bg)
        local clicked = false
        if imgui.BeginChild("##slot" .. i, slotSize, slotSize, true) then
            -- Bait icon area (centered)
            local Assets = require("assets")
            local baitName = bait.name or ""
            local imgKey = "bait_" .. baitName:lower():gsub("%s", "_")
            local img = Assets:getImage(imgKey)
            
            if img and Assets:hasAnyImage(imgKey) then
                -- Draw the image centered in the slot
                local iw, ih = img:getWidth(), img:getHeight()
                local scale = math.min((slotSize - 20) / iw, (slotSize - 35) / ih)
                scale = math.min(scale, 1.5) -- cap scale
                
                local drawW = iw * scale
                local drawH = ih * scale
                local dx = (slotSize - drawW) / 2
                local dy = (slotSize - 30 - drawH) / 2 + 5
                
                love.graphics.push()
                -- ImGui child window offset: we need to account for the cursor position
                -- For simplicity, use imgui.Image with a texture ref
                local texRef = imgui.love.TextureRef(img)
                imgui.Image(texRef, drawW, drawH)
            else
                -- Placeholder icon (simple shape)
                imgui.Dummy(slotSize / 2 - 15, slotSize / 2 - 20)
                imgui.PushStyleColor(imgui.Col_Text, {0.4, 0.38, 0.35, 0.6})
                imgui.Text("🪱")
                imgui.PopStyleColor()
            end
            
            -- Bait name below icon
            imgui.Dummy(0, 4)
            local nameFont = love.graphics.newFont(12)
            imgui.PushStyleColor(imgui.Col_Text, isSelected and {0.95, 0.88, 0.7, 1} or {0.65, 0.62, 0.55, 1})
            
            -- Truncate name if too long
            local displayName = baitName
            while #displayName > 12 do
                displayName = displayName:sub(1, -3) .. "…"
            end
            imgui.Text(displayName)
            imgui.PopStyleColor()
            
            -- Click detection
            if imgui.IsItemHovered() and love.mouse.isDown(1) then
                self.selectedSlot = i
                clicked = true
            end
        end
        imgui.EndChild()
        
        imgui.PopStyleColor(2)
    end
    
    -- Controls hint at bottom
    imgui.Spacing()
    imgui.Separator()
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.43, 0.40, 0.8})
    imgui.Text("←→ Navigate · SPACE Select · B/ESC Close")
    imgui.PopStyleColor()
    
    -- Keyboard navigation
    if love.keyboard.justPressed("left") then
        self.selectedSlot = math.max(1, self.selectedSlot - 1)
    elseif love.keyboard.justPressed("right") then
        self.selectedSlot = math.min(#baitInventory, self.selectedSlot + 1)
    end
    
    -- Close with ESC or B
    if love.keyboard.justPressed("escape", "b") then
        self.isOpen = false
        imgui.End()
        return false
    end
    
    -- Select with SPACE
    local selectedBait = nil
    if love.keyboard.justPressed("space") and baitInventory[self.selectedSlot] then
        selectedBait = baitInventory[self.selectedSlot]
        self.isOpen = false
    end
    
    imgui.End()
    
    return selectedBait
end

return TackleBox