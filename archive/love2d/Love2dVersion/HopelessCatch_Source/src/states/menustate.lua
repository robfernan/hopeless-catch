-- src/states/menustate.lua - Atmospheric Living Title Menu
local Assets = require("src.core.assets")
local SkyRenderer = require("src.world.skyrenderer")
local Terrain = require("src.world.terrain")
local Water = require("src.world.water")
local DayNight = require("src.systems.daynight")

local MenuState = {
    selected = 1,
    options = {
        { text = "BEGIN FISHING", action = "play" },
        { text = "FIELD JOURNAL", action = "journal" },
        { text = "QUIT TO DESKTOP", action = "quit" }
    },
    animTimer = 0,
    sm = nil
}

function MenuState.new(stateMachine)
    local self = setmetatable({}, { __index = MenuState })
    self.sm = stateMachine
    return self
end

function MenuState:enter()
    self.selected = 1
    self.animTimer = 0
    DayNight.time = 0.88 -- Nightfall mood for title
    DayNight.isNight = true
    Assets.startAmbient()
end

function MenuState:update(dt)
    self.animTimer = self.animTimer + dt
    Water.update(dt)
    DayNight.update(dt * 0.1)
end

function MenuState:keypressed(key)
    if key == "up" or key == "w" then
        self.selected = math.max(1, self.selected - 1)
        Assets.play("reel_click", 0.05, 0.4)
    elseif key == "down" or key == "s" then
        self.selected = math.min(#self.options, self.selected + 1)
        Assets.play("reel_click", 0.05, 0.4)
    elseif key == "space" or key == "return" then
        local act = self.options[self.selected].action
        if act == "play" then
            self.sm:change("play")
        elseif act == "journal" then
            self.sm:change("play", { openJournal = true })
        elseif act == "quit" then
            love.event.quit()
        end
    end
end

function MenuState:draw()
    local w, h = love.graphics.getDimensions()
    
    -- 1. Living World Backdrop
    SkyRenderer.draw(DayNight, w, h)
    Terrain.draw(w, h, DayNight)
    Water.draw(w, h, DayNight)
    
    -- 2. Atmospheric Dark Vignette
    love.graphics.setColor(0.01, 0.02, 0.04, 0.55)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- 3. Game Title with Blood Glow
    local t = self.animTimer
    local glow = 0.3 + 0.15 * math.sin(t * 1.5)
    love.graphics.setFont(Assets.fonts.huge)
    love.graphics.setColor(0.7, 0.15, 0.12, glow)
    love.graphics.printf("HOPELESS CATCH", 3, h * 0.14 + 3, w, "center")
    
    love.graphics.setColor(0.92, 0.85, 0.78, 1.0)
    love.graphics.printf("HOPELESS CATCH", 0, h * 0.14, w, "center")
    
    -- Subtitle
    love.graphics.setFont(Assets.fonts.medium)
    love.graphics.setColor(0.75, 0.45, 0.40, 0.95)
    love.graphics.printf("Rotten Tide & Forbidden Waters", 0, h * 0.14 + 75, w, "center")
    
    -- 4. Interactive Menu Options Panel
    local panelW = 340
    local panelH = 180
    local px = (w - panelW) * 0.5
    local py = h * 0.45
    
    love.graphics.setColor(0.05, 0.06, 0.09, 0.85)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 8, 8)
    love.graphics.setColor(0.35, 0.25, 0.20, 0.9)
    love.graphics.rectangle("line", px, py, panelW, panelH, 8, 8)
    
    for i, opt in ipairs(self.options) do
        local isSel = (i == self.selected)
        local oy = py + 20 + (i - 1) * 48
        
        if isSel then
            love.graphics.setColor(0.45, 0.18, 0.14, 0.95)
            love.graphics.rectangle("fill", px + 15, oy, panelW - 30, 38, 6, 6)
            love.graphics.setColor(0.95, 0.45, 0.35, 1.0)
            love.graphics.rectangle("line", px + 15, oy, panelW - 30, 38, 6, 6)
        end
        
        love.graphics.setFont(Assets.fonts.medium)
        love.graphics.setColor(isSel and {1, 0.95, 0.88, 1} or {0.78, 0.74, 0.70, 0.85})
        love.graphics.printf(opt.text, px, oy + 8, panelW, "center")
    end
    
    -- Version & Jam credit
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.5, 0.48, 0.45, 0.7)
    love.graphics.printf("↑↓ Navigate  •  SPACE / ENTER Select", 0, h - 35, w, "center")
end

return MenuState
