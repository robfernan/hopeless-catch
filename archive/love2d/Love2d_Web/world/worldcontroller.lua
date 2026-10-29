-- world/worldcontroller.lua - Main world rendering coordinator
local WorldController = {}

-- Import world rendering modules
local SkyRenderer = require("world.skyrenderer")
local TerrainRenderer = require("world.terrainrenderer")
local Vegetation = require("world.vegetation")
local Structures = require("world.structures")

-- World positioning
local waterY = 0
local houseX, houseY = 0, 0
local lanternX, lanternY = 0, 0
local grassY = 0

function WorldController:init()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    waterY = height * 0.7  -- Water level
    grassY = waterY - 60   -- Grass level above water
    
    -- House positioned on the grass/ground, not in sky
    houseX = width - 200
    houseY = grassY - 80   -- House sits ON the grass
    
    -- Lantern on the dock/pier area
    lanternX = width * 0.6
    lanternY = height - 130 -- On the dock
    
    print("World Controller initialized - Modular rendering system ready!")
end

function WorldController:update(dt)
    -- World updates (water animation, etc.)
    -- Can add animated elements here if needed
end

function WorldController:drawBackground()
    local DayNightCycle = require("world.daynightcycle")
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local timeOfDay = DayNightCycle:getTimeOfDay()
    
    -- Draw sky gradient based on time
    SkyRenderer:drawSky(timeOfDay)
    
    -- Draw celestial bodies with realistic movement
    SkyRenderer:drawCelestialBodies(timeOfDay, width, height)
    
    -- Draw stars (only visible at night)
    if timeOfDay < 0.2 or timeOfDay > 0.8 then
        SkyRenderer:drawStars(timeOfDay, waterY)
    end
    
    -- Draw clouds
    SkyRenderer:drawClouds(timeOfDay, waterY)
    
    -- Distant mountains/hills
    TerrainRenderer:drawDistantTerrain()
    
    -- Trees and vegetation
    Vegetation:drawVegetation(DayNightCycle:isNightTime())
end

function WorldController:drawForeground()
    -- Draw ground and terrain
    TerrainRenderer:drawGround()
    
    -- Draw path
    TerrainRenderer:drawPath()
    
    -- Draw structures (house, dock, lantern)
    Structures:drawStructures()
end

function WorldController:drawWaterLevel()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Water surface
    love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
    love.graphics.rectangle("fill", 0, waterY, width, height - waterY)
    
    -- Water surface animation
    love.graphics.setColor(0.3, 0.5, 0.7, 0.6)
    local waveOffset = love.timer.getTime() * 2
    for x = 0, width, 10 do
        local waveHeight = math.sin((x + waveOffset) * 0.1) * 2
        love.graphics.rectangle("fill", x, waterY + waveHeight, 8, 5)
    end
    
    -- Water reflections
    love.graphics.setColor(1, 1, 1, 0.1)
    for x = 0, width, 20 do
        local ripple = math.sin((x + waveOffset * 1.5) * 0.15) * 3
        love.graphics.rectangle("fill", x, waterY + 10 + ripple, 15, 2)
    end
end

-- Getters for positioning (for other systems that need world coordinates)
function WorldController:getWaterY()
    return waterY
end

function WorldController:getGrassY()
    return grassY
end

function WorldController:getHousePosition()
    return houseX, houseY
end

function WorldController:getLanternPosition()
    return lanternX, lanternY
end

function WorldController:isNearHouse(playerX, playerY)
    local distance = math.sqrt((playerX - houseX)^2 + (playerY - (houseY + 30))^2)
    return distance < 50
end

function WorldController:isOnDock(playerX, playerY)
    local width = love.graphics.getWidth()
    local dockX = width * 0.55
    local dockWidth = 100
    
    return playerX >= dockX and playerX <= dockX + dockWidth and 
           playerY >= waterY - 20 and playerY <= waterY + 10
end

return WorldController
