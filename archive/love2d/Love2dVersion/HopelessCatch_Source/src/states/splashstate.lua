-- src/states/splashstate.lua - Horror Content Warning & Jam Splash Screen
local Assets = require("src.core.assets")

local SplashState = {
    timer = 0,
    duration = 4.0,
    sm = nil
}

function SplashState.new(stateMachine)
    local self = setmetatable({}, { __index = SplashState })
    self.sm = stateMachine
    return self
end

function SplashState:enter()
    self.timer = 0
    Assets.play("bite_stinger", 0.0, 0.4)
end

function SplashState:update(dt)
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.sm:change("menu")
    end
end

function SplashState:keypressed(key)
    if key == "space" or key == "return" or key == "escape" then
        self.sm:change("menu")
    end
end

function SplashState:draw()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0.02, 0.02, 0.04, 1.0)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    local alpha = 1.0
    if self.timer < 0.8 then
        alpha = self.timer / 0.8
    elseif self.timer > self.duration - 0.8 then
        alpha = (self.duration - self.timer) / 0.8
    end
    
    -- Content Warning
    love.graphics.setFont(Assets.fonts.large)
    love.graphics.setColor(0.85, 0.25, 0.20, alpha)
    love.graphics.printf("CONTENT WARNING", 0, h * 0.30, w, "center")
    
    love.graphics.setFont(Assets.fonts.medium)
    love.graphics.setColor(0.85, 0.80, 0.75, alpha * 0.9)
    love.graphics.printf(
        "Hopeless Catch contains themes of isolation, psychological dread,\n" ..
        "body horror, and dark water depths.\n\n" ..
        "Created for the Horror Fishing Game Jam\n" ..
        "Themes: Rotten Tide & Forbidden Waters",
        0, h * 0.40, w, "center"
    )
    
    love.graphics.setFont(Assets.fonts.small)
    love.graphics.setColor(0.5, 0.48, 0.45, alpha * 0.7)
    love.graphics.printf("Press SPACE to skip", 0, h * 0.82, w, "center")
end

return SplashState
