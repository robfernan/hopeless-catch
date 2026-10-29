-- Player.lua - Player character with movement
local Player = {}

local x, y = 0, 0
local speed = 150
local width, height = 16, 32

function Player:init(startX, startY)
    x = startX or 400
    y = startY or 300
    
    -- If no start position given, place on grass level
    if not startX or not startY then
        local World = require("world.world")
        if World.getGrassY then
            local grassY = World:getGrassY()
            x = 400  -- Center of screen
            y = grassY - height/2  -- On grass surface
        end
    end
end

function Player:update(dt)
    local dx, dy = 0, 0
    
    -- Movement input
    if love.keyboard.isDown("w", "up") then
        dy = dy - 1
    end
    if love.keyboard.isDown("s", "down") then
        dy = dy + 1
    end
    if love.keyboard.isDown("a", "left") then
        dx = dx - 1
    end
    if love.keyboard.isDown("d", "right") then
        dx = dx + 1
    end
    
    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.707
        dy = dy * 0.707
    end
    
    -- Calculate new position
    local newX = x + dx * speed * dt
    local newY = y + dy * speed * dt
    
    -- Get water level from world
    local World = require("world.world")
    local waterY = World:getWaterY()
    local grassY = World:getGrassY()
    
    -- Check if player would be on wooden dock area
    local screenWidth = love.graphics.getWidth()
    local dockStartX = screenWidth * 0.5   -- Dock starts at center
    local dockEndX = screenWidth * 0.5 + 150  -- Dock width of 150px
    local dockY = waterY - 25  -- Dock above water level
    local dockBottom = dockY + 35  -- Dock height of 35px
    local isOnDockArea = newX >= dockStartX and newX <= dockEndX
    
    -- Simple collision system:
    -- 1. Can walk on grass level
    -- 2. Can walk on dock platform (if in dock area)
    -- 3. Cannot walk in water (below grass/dock level)
    -- 4. Cannot walk in the sky (above grass/dock level)
    
    if isOnDockArea then
        -- On dock area - can walk on dock platform
        if newY > dockY - height/2 then
            newY = dockY - height/2  -- Stay on top of dock
        end
        if newY < dockY - height/2 - 10 then
            newY = dockY - height/2 - 10  -- Don't float too high above dock
        end
    else
        -- Not on dock area - must stay on grass level
        local groundLevel = grassY - height/2
        if newY > groundLevel then
            newY = groundLevel  -- Don't go below grass (into water)
        end
        if newY < groundLevel - 10 then
            newY = groundLevel - 10  -- Don't float too high above grass
        end
    end
    
    -- Apply constrained movement
    x = newX
    y = newY
    
    -- Keep player on screen horizontally
    x = math.max(width/2, math.min(love.graphics.getWidth() - width/2, x))
    y = math.max(height/2, math.min(love.graphics.getHeight() - height/2, y))
end

function Player:draw()
    local Assets = require("assets")
    -- Draw player sprite
    love.graphics.setColor(1, 1, 1, 1)
    local sprite = Assets:getImage("player_character")
    if sprite then
        love.graphics.draw(sprite, x - width/2, y - height/2)
    else
        -- Fallback rectangle if sprite fails to load
        love.graphics.setColor(0.2, 0.6, 0.8, 1)
        love.graphics.rectangle("fill", x - width/2, y - height/2, width, height)
    end
    
    -- Fishing rod is now drawn by the fishing system
end

function Player:getX()
    return x
end

function Player:getY()
    return y
end

function Player:getPosition()
    return x, y
end

function Player:getDimensions()
    return width, height
end

function Player:setPosition(newX, newY)
    x = newX
    y = newY
end

return Player
