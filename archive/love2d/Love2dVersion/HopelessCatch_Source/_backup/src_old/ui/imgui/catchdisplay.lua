-- ui/imgui/catchdisplay.lua - Catch reveal UI with Dear ImGui
local imgui = require("cimgui")

local CatchDisplayUI = {}
CatchDisplayUI.active = false
CatchDisplayUI.fish = nil
CatchDisplayUI.timer = 0
CatchDisplayUI.phase = "hidden" -- hidden, appearing, showing, disappearing
CatchDisplayUI.scale = 0

local APPEAR_TIME = 0.8
local DISAPPEAR_TIME = 0.5

--- Trigger the catch display. Call when a fish is caught.
function CatchDisplayUI:show(fish)
    if type(fish) ~= "table" then return end
    
    self.fish = {
        name = fish.name or "Unknown Fish",
        description = fish.description,
        weight = fish.weight or (math.random(50, 500) / 100),
        rarity = fish.rarity or "common",
        difficulty = fish.difficulty or 1,
    }
    
    self.active = true
    self.timer = 0
    self.phase = "appearing"
    self.scale = 0
    
    -- Screen shake for dramatic effect
    if _G.addScreenShake then
        local intensity = (fish.difficulty or 1) * 2
        _G.addScreenShake(0.3, math.min(intensity, 10))
    end
end

function CatchDisplayUI:update(dt)
    if not self.active then return end
    
    self.timer = self.timer + dt
    
    if self.phase == "appearing" then
        local progress = self.timer / APPEAR_TIME
        if progress >= 1 then
            self.phase = "showing"
            self.scale = 1
        else
            -- Elastic ease-out
            local t = progress
            self.scale = 1 - math.exp(-6 * t) * math.cos(8 * t)
        end
    elseif self.phase == "disappearing" then
        local progress = self.timer / DISAPPEAR_TIME
        if progress >= 1 then
            self.active = false
            self.phase = "hidden"
            self.scale = 0
        else
            self.scale = 1 - progress * progress
        end
    end
end

--- Draw the catch display. Returns true if dismissed this frame.
function CatchDisplayUI:draw()
    if not self.active or self.phase == "hidden" then return false end
    
    local w, h = love.graphics.getDimensions()
    
    -- Background dim (heavier for horror fish)
    local isHorror = self:_isHorrorFish()
    local bgAlpha = isHorror and 0.85 or 0.7
    love.graphics.setColor(0.01, 0.01, 0.03, bgAlpha * self.scale)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Horror fish: subtle red vignette pulse
    if isHorror and self.phase == "showing" then
        local pulse = 0.15 + 0.1 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(0.4, 0.05, 0.05, pulse * self.scale)
        -- Edge strips for vignette
        local stripW = w * 0.15
        love.graphics.rectangle("fill", 0, 0, stripW, h)
        love.graphics.rectangle("fill", w - stripW, 0, stripW, h)
    end
    
    -- Panel
    local panelW = math.min(480, w * 0.75)
    local panelH = 320
    local px = (w - panelW) / 2
    local py = (h - panelH) / 2 - 20
    
    imgui.SetNextWindowPos(px, py)
    imgui.SetNextWindowSize(panelW, panelH)
    
    local flags = imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize 
                + imgui.WindowFlags_NoMove + imgui.WindowFlags_NoCollapse
                + imgui.WindowFlags_NoSavedSettings
    
    if not imgui.Begin("##CatchDisplay", nil, flags) then
        return false
    end
    
    -- Apply scale via alpha (ImGui doesn't easily do per-window scaling)
    local alpha = math.max(0.1, self.scale)
    
    -- Fish name (large, centered feel)
    imgui.Dummy(0, 20)
    imgui.PushStyleColor(imgui.Col_Text, isHorror and {0.9, 0.45, 0.4, alpha} or {0.85, 0.8, 0.7, alpha})
    
    local name = self.fish.name
    -- Use larger text for the name
    imgui.FontScale(1.6)
    imgui.Text(name)
    imgui.FontScale(1.0)
    imgui.PopStyleColor()
    
    -- Rarity badge
    if self.fish.rarity then
        local rarityColors = {
            common   = {0.5, 0.5, 0.45, alpha},
            uncommon = {0.4, 0.65, 0.4, alpha},
            rare     = {0.7, 0.5, 0.2, alpha},
        }
        local rc = rarityColors[self.fish.rarity] or {0.6, 0.6, 0.6, alpha}
        imgui.PushStyleColor(imgui.Col_Text, rc)
        imgui.Text("★ %s", self.fish.rarity:upper())
        imgui.PopStyleColor()
    end
    
    -- Fish sprite (centered)
    local Assets = require("assets")
    local fishKey = "fish_" .. name:lower():gsub("%s", "_")
    if name == "Fishman" then fishKey = "fishman" end
    local img = Assets:getImage(fishKey)
    
    if img and Assets:hasAnyImage(fishKey) then
        local iw, ih = img:getWidth(), img:getHeight()
        local maxW, maxH = 160, 120
        local scale = math.min(maxW / iw, maxH / ih, 2.5) * self.scale
        
        if scale > 0.1 then
            local texRef = imgui.love.TextureRef(img)
            -- Center the image
            local offsetX = (panelW - iw * scale) / 2
            imgui.SetCursorPosX(offsetX)
            imgui.Dummy(0, 10)
            imgui.Image(texRef, iw * scale, ih * scale)
        end
    else
        -- Placeholder: draw a simple fish silhouette with Love2D
        local cx = w / 2
        local cy = h / 2 - 30
        love.graphics.setColor(
            isHorror and 0.6 or 0.5, 
            isHorror and 0.2 or 0.55, 
            isHorror and 0.2 or 0.6, 
            self.scale * 0.8
        )
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(math.sin(love.timer.getTime()) * 0.05 * self.scale)
        love.graphics.scale(self.scale)
        -- Fish body
        love.graphics.ellipse("fill", 0, 0, 40, 18)
        -- Tail
        love.graphics.polygon("fill", 35, 0, 55, -12, 55, 12)
        -- Eye
        love.graphics.setColor(1, 1, 1, self.scale * 0.9)
        love.graphics.circle("fill", -18, -4, 4)
        love.graphics.setColor(0, 0, 0, self.scale * 0.9)
        love.graphics.circle("fill", -16, -4, 2)
        love.graphics.pop()
    end
    
    -- Stats row
    imgui.Dummy(0, 15)
    imgui.Separator()
    imgui.Spacing()
    
    local statColor = isHorror and {0.7, 0.55, 0.5, alpha} or {0.6, 0.62, 0.58, alpha}
    imgui.PushStyleColor(imgui.Col_Text, statColor)
    
    -- Weight
    local weightStr = string.format("%.1f lbs", self.fish.weight or 0)
    imgui.Text("Weight: %s", weightStr)
    
    -- Difficulty as dots
    local diff = math.min(5, self.fish.difficulty or 1)
    local diffStr = ""
    for i = 1, 5 do
        diffStr = diffStr .. (i <= diff and "●" or "○")
    end
    imgui.Text("Difficulty: %s", diffStr)
    
    -- Description (if available)
    if self.fish.description then
        imgui.Spacing()
        imgui.PushStyleColor(imgui.Col_Text, {0.5, 0.48, 0.44, alpha * 0.9})
        
        -- Word-wrap the description
        local desc = self.fish.description
        local maxChars = 50
        if #desc > maxChars then
            -- Find a good break point
            local spacePos = desc:find("%s", maxChars - 10, true) or maxChars
            imgui.Text(desc:sub(1, spacePos))
            imgui.Text(desc:sub(spacePos + 1))
        else
            imgui.Text(desc)
        end
        imgui.PopStyleColor()
    end
    
    -- Horror fish special text
    if isHorror then
        imgui.Spacing()
        local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 5)
        imgui.PushStyleColor(imgui.Col_Text, {0.75, 0.25 * pulse, 0.2 * pulse, alpha})
        imgui.Text("Something is wrong with this creature...")
        imgui.PopStyleColor()
    end
    
    -- Dismiss hint
    if self.phase == "showing" then
        imgui.Dummy(0, 15)
        imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.43, 0.40, alpha * 0.7})
        imgui.Text("Press any key to continue...")
        imgui.PopStyleColor()
    end
    
    -- Dismiss on any key press during "showing" phase
    local dismissed = false
    if self.phase == "showing" then
        for k in pairs(love.keyboard.isDown()) do
            if k ~= "lctrl" and k ~= "rctrl" and k ~= "lshift" and k ~= "rshift" 
               and k ~= "lalt" and k ~= "ralt" and k ~= "lgui" and k ~= "rgui" then
                self.phase = "disappearing"
                self.timer = 0
                dismissed = true
                break
            end
        end
    end
    
    imgui.End()
    
    return dismissed
end

function CatchDisplayUI:isShowing()
    return self.active and self.phase ~= "hidden"
end

function CatchDisplayUI:_isHorrorFish()
    if not self.fish then return false end
    local horrorNames = {
        ["Pale Crawler"] = true,
        ["Bleeding Carp"] = true,
        ["Whispering Eel"] = true,
        ["Fishman"] = true,
    }
    return horrorNames[self.fish.name] == true
end

return CatchDisplayUI