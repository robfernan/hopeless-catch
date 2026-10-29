-- ui/imgui/mainmenu.lua - Main menu rendered with Dear ImGui
local imgui = require("cimgui")
local GUI = require("ui.imgui.init")

local MainMenu = {}
MainMenu.selectedOption = 1
MainMenu.animationTimer = 0

function MainMenu:init()
    self.selectedOption = 1
    self.animationTimer = 0
end

function MainMenu:update(dt)
    self.animationTimer = self.animationTimer + dt
end

--- Draw the main menu. Returns an action string or nil.
-- Actions: "start_game", "how_to_play", "settings", "credits", "quit"
function MainMenu:draw()
    local w, h = love.graphics.getDimensions()
    
    -- Subtle animated water ripple at bottom (Love2D layer)
    local t = self.animationTimer
    love.graphics.setColor(0.05, 0.08, 0.15, 0.4)
    for i = 1, 3 do
        local yOff = h - 60 + i * 15 + math.sin(t * 0.8 + i * 2) * 5
        love.graphics.line(0, yOff, w, yOff)
    end
    
    -- Title (Love2D layer for large text with glow)
    local titleFont = love.graphics.newFont(48)
    local subFont = love.graphics.newFont(16)
    
    -- Title glow effect
    local glowAlpha = 0.3 + 0.15 * math.sin(t * 1.2)
    love.graphics.setColor(0.6, 0.1, 0.1, glowAlpha)
    love.graphics.setFont(titleFont)
    local titleText = "HOPELESS CATCH"
    local tw = titleFont:getWidth(titleText)
    love.graphics.print(titleText, w/2 - tw/2 + 2, h * 0.14 + 2)
    
    -- Main title
    love.graphics.setColor(0.85, 0.75, 0.65, 1)
    love.graphics.print(titleText, w/2 - tw/2, h * 0.14)
    
    -- Subtitle
    love.graphics.setFont(subFont)
    local subText = "A Psychological Fishing Horror"
    local sw = subFont:getWidth(subText)
    love.graphics.setColor(0.5, 0.48, 0.42, 0.9)
    love.graphics.print(subText, w/2 - sw/2, h * 0.14 + 55)
    
    -- Separator line under title
    love.graphics.setColor(0.4, 0.2, 0.15, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.line(w * 0.3, h * 0.14 + 80, w * 0.7, h * 0.14 + 80)
    
    -- === ImGui menu panel ===
    local panelW = 340
    local panelX = (w - panelW) / 2
    local panelY = h * 0.36
    
    imgui.SetNextWindowPos(panelX, panelY, imgui.Cond_Always)
    imgui.SetNextWindowSize(panelW, 0, imgui.Cond_Always)
    
    local flags = imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize 
                + imgui.WindowFlags_NoMove + imgui.WindowFlags_NoCollapse
                + imgui.WindowFlags_NoSavedSettings
    
    if not imgui.Begin("##MainMenu", nil, flags) then
        return nil
    end
    
    local options = {
        {text = "Start Game",       action = "start_game"},
        {text = "How to Play",      action = "how_to_play"},
        {text = "Settings",         action = "settings"},
        {text = "Credits",          action = "credits"},
        {text = "Quit",             action = "quit"},
    }
    
    imgui.Spacing()
    imgui.Dummy(0, 10)
    
    for i, opt in ipairs(options) do
        local isSelected = (self.selectedOption == i)
        
        if isSelected then
            imgui.PushStyleColor(imgui.Col_Text, {1.0, 0.95, 0.85, 1.0})
            imgui.PushStyleColor(imgui.Col_Button, {0.45, 0.18, 0.12, 1.0})
        else
            imgui.PushStyleColor(imgui.Col_Text, {0.90, 0.86, 0.80, 1.0})
            imgui.PushStyleColor(imgui.Col_Button, {0.18, 0.16, 0.15, 0.95})
        end
        
        local clicked = imgui.Button(opt.text .. "##" .. i, panelW - 40, 38)
        
        imgui.PopStyleColor(2)
        
        -- Keyboard navigation
        if love.keyboard.isDown("up") and not self._navLock then
            self.selectedOption = math.max(1, i - 1)
            self._navLock = true
        elseif love.keyboard.isDown("down") and not self._navLock then
            self.selectedOption = math.min(#options, i + 1)
            self._navLock = true
        end
        
        if clicked or (love.keyboard.justPressed("return", "space") and self.selectedOption == i) then
            imgui.End()
            return opt.action
        end
    end
    
    -- Navigation hint
    imgui.Dummy(0, 15)
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.42, 0.38, 0.8})
    local font = love.graphics.getFont()
    imgui.Text("↑↓ Navigate   ·   ENTER Select   ·   ESC Quit")
    imgui.PopStyleColor()
    
    -- Version in corner
    imgui.Separator()
    imgui.PushStyleColor(imgui.Col_Text, {0.35, 0.33, 0.30, 0.7})
    imgui.Text("v1.0  ·  LÖVE 11.5  ·  OpenGL")
    imgui.PopStyleColor()
    
    imgui.End()
    
    -- Reset nav lock on next frame
    if not love.keyboard.isDown("up", "down") then
        self._navLock = nil
    end
    
    return nil
end

--- Handle ESC key. Returns action or nil.
function MainMenu:handleEscape()
    return "quit"
end

return MainMenu
