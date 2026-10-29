-- src/states/pausestate.lua - Dark Frosted Pause Menu
local Assets = require("src.core.assets")

local PauseState = {
    selected = 1,
    options = {
        { text = "RESUME FISHING", action = "resume" },
        { text = "FIELD JOURNAL", action = "journal" },
        { text = "RETURN TO TITLE", action = "menu" }
    },
    sm = nil
}

function PauseState.new(stateMachine)
    local self = setmetatable({}, { __index = PauseState })
    self.sm = stateMachine
    return self
end

function PauseState:enter()
    self.selected = 1
end

function PauseState:keypressed(key)
    if key == "up" or key == "w" then
        self.selected = math.max(1, self.selected - 1)
        Assets.play("reel_click", 0.05, 0.4)
    elseif key == "down" or key == "s" then
        self.selected = math.min(#self.options, self.selected + 1)
        Assets.play("reel_click", 0.05, 0.4)
    elseif key == "escape" then
        self.sm:pop()
    elseif key == "space" or key == "return" then
        local act = self.options[self.selected].action
        if act == "resume" then
            self.sm:pop()
        elseif act == "journal" then
            self.sm:pop({ openJournal = true })
        elseif act == "menu" then
            self.sm:change("menu")
        end
    end
end

function PauseState:draw()
    local w, h = love.graphics.getDimensions()
    
    -- Frosted Dark Gameplay Overlay
    love.graphics.setColor(0.01, 0.02, 0.04, 0.82)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local panelW = 340
    local panelH = 220
    local px = (w - panelW) * 0.5
    local py = (h - panelH) * 0.5
    
    love.graphics.setColor(0.05, 0.06, 0.09, 0.95)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 8, 8)
    love.graphics.setColor(0.35, 0.25, 0.20, 0.9)
    love.graphics.rectangle("line", px, py, panelW, panelH, 8, 8)
    
    -- Pause Header
    love.graphics.setFont(Assets.fonts.large)
    love.graphics.setColor(0.92, 0.85, 0.78, 1.0)
    love.graphics.printf("PAUSED", px, py + 18, panelW, "center")
    
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.65, 0.45, 0.40, 0.9)
    love.graphics.printf("The Rotten Tide halts for no one", px, py + 48, panelW, "center")
    
    for i, opt in ipairs(self.options) do
        local isSel = (i == self.selected)
        local oy = py + 75 + (i - 1) * 44
        
        if isSel then
            love.graphics.setColor(0.45, 0.18, 0.14, 0.95)
            love.graphics.rectangle("fill", px + 20, oy, panelW - 40, 36, 6, 6)
            love.graphics.setColor(0.95, 0.45, 0.35, 1.0)
            love.graphics.rectangle("line", px + 20, oy, panelW - 40, 36, 6, 6)
        end
        
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(isSel and {1, 0.95, 0.88, 1} or {0.78, 0.74, 0.70, 0.85})
        love.graphics.printf(opt.text, px, oy + 7, panelW, "center")
    end
end

return PauseState
