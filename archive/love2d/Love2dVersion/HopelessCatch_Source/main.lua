-- main.lua - Hopeless Catch Master Entrypoint
local Assets = require("src.core.assets")
local Input = require("src.core.input")
local StateMachine = require("src.core.statemachine")
local SkyRenderer = require("src.world.skyrenderer")

local SplashState = require("src.states.splashstate")
local MenuState = require("src.states.menustate")
local PlayState = require("src.states.playstate")
local PauseState = require("src.states.pausestate")

-- Lurker live hot-reloader
local lurker = require("lurker")
lurker.interval = 0.5
lurker.quiet = false

local sm

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Initialize Assets & Sound Generators
    Assets.init()
    SkyRenderer.init()
    
    -- Initialize State Machine & Register States
    sm = StateMachine.new()
    sm:register("splash", SplashState.new(sm))
    sm:register("menu", MenuState.new(sm))
    sm:register("play", PlayState.new(sm))
    sm:register("pause", PauseState.new(sm))
    
    -- Start on Splash / Content Warning Screen
    sm:change("splash")
    
    print("🎣 Hopeless Catch - Rotten Tide & Forbidden Waters [Engine Booted]")
end

function love.update(dt)
    lurker.update()
    
    -- Global Instant Restart
    if love.keyboard.isDown("f5") then
        love.event.quit("restart")
        return
    end
    
    sm:update(dt)
    Input.update()
end

function love.draw()
    sm:draw()
end

function love.keypressed(key)
    Input.keypressed(key)
    local cur = sm:current()
    if cur and cur.keypressed then
        cur:keypressed(key)
    end
end

function love.keyreleased(key)
    Input.keyreleased(key)
    local cur = sm:current()
    if cur and cur.keyreleased then
        cur:keyreleased(key)
    end
end

function love.mousepressed(x, y, button)
    Input.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Input.mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    Input.wheelmoved(x, y)
end

function love.quit()
    Assets.stopAmbient()
end
