-- ui/imgui/pausemenu.lua - Pause menu overlay with Dear ImGui
local imgui = require("cimgui")

local PauseMenu = {}
PauseMenu.selectedOption = 1

--- Draw the pause menu overlay. Returns an action string or nil.
-- Actions: "resume", "how_to_play", "settings", "quit_to_menu"
function PauseMenu:draw()
    local w, h = love.graphics.getDimensions()
    
    -- Semi-transparent dark overlay (game world shows through)
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Panel
    local panelW = 300
    local px = (w - panelW) / 2
    local py = h * 0.25
    
    imgui.SetNextWindowPos(px, py)
    imgui.SetNextWindowSize(panelW, 0)
    
    local flags = imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_NoResize 
                + imgui.WindowFlags_NoMove + imgui.WindowFlags_NoCollapse
                + imgui.WindowFlags_NoSavedSettings
    
    if not imgui.Begin("##PauseMenu", nil, flags) then
        return nil
    end
    
    -- Title
    imgui.PushStyleColor(imgui.Col_Text, {0.85, 0.78, 0.65, 1})
    imgui.FontScale(1.4)
    imgui.Text("PAUSED")
    imgui.FontScale(1.0)
    imgui.PopStyleColor()
    
    -- Subtitle
    imgui.PushStyleColor(imgui.Col_Text, {0.5, 0.48, 0.42, 0.8})
    imgui.Text("The water waits...")
    imgui.PopStyleColor()
    
    imgui.Separator()
    imgui.Spacing()
    
    local options = {
        {text = "Resume",      action = "resume"},
        {text = "How to Play",    action = "how_to_play"},
        {text = "Settings",     action = "settings"},
        {text = "Save & Quit",    action = "quit_to_menu"},
    }
    
    for i, opt in ipairs(options) do
        local isSelected = (self.selectedOption == i)
        if isSelected then
            imgui.PushStyleColor(imgui.Col_Text, {1.0, 0.95, 0.85, 1.0})
            imgui.PushStyleColor(imgui.Col_Button, {0.45, 0.18, 0.12, 1.0})
        else
            imgui.PushStyleColor(imgui.Col_Text, {0.90, 0.86, 0.80, 1.0})
            imgui.PushStyleColor(imgui.Col_Button, {0.18, 0.16, 0.15, 0.95})
        end
        
        local clicked = imgui.Button(opt.text .. "##pause" .. i, panelW - 40, 34)
        
        imgui.PopStyleColor(2)
        
        -- Keyboard nav
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
    
    -- Hint
    imgui.Spacing()
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.43, 0.40, 0.7})
    imgui.Text("ESC Resume · ↑↓ Navigate")
    imgui.PopStyleColor()
    
    imgui.End()
    
    if not love.keyboard.isDown("up", "down") then
        self._navLock = nil
    end
    
    return nil
end

--- Handle ESC (resume game).
function PauseMenu:handleEscape()
    return "resume"
end

return PauseMenu