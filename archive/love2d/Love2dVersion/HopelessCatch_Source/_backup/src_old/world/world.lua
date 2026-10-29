-- world.lua - World System Connector - connects all world components
local World = {}

-- Import all world components
local WorldController = require("world.worldcontroller")
local DayNightCycle = require("world.daynightcycle")
local Weather = require("world.weather")
local LakeElements = require("world.lakeelements")
local SkyRenderer = require("world.skyrenderer")
local TerrainRenderer = require("world.terrainrenderer")
local Vegetation = require("world.vegetation")
local Structures = require("world.structures")

function World:init()
    WorldController:init()
    DayNightCycle:init()
    Weather:init()
    LakeElements:init()
end

function World:update(dt)
    -- Only update the world controller here. DayNightCycle and Weather are
    -- updated separately in main.lua to avoid double-updating per frame.
    WorldController:update(dt)
    LakeElements:update(dt)
end

function World:drawBackground()
    WorldController:drawBackground()
    -- DayNightCycle doesn't have drawBackground - only drawTimeIndicator
    -- Weather doesn't have drawBackground - only draw()
end

function World:drawForeground()
    WorldController:drawForeground()
    -- DayNightCycle doesn't have drawForeground - only drawTimeIndicator  
    Weather:draw()
    LakeElements:draw()
end

--- Draw the cabin light glow over the dark environment.
-- This renders AFTER the main world pass and visibility vignette so the
-- lantern cuts through the darkness. Call during the post-lighting render phase.
function World:drawCabinLight()
    local x, y = WorldController:getLanternPosition()
    if not x or not y then return end
    
    -- Render the HorrorEvents cabin light (handles flicker state internally)
    local HorrorEvents = require("world.horrorevents")
    if type(HorrorEvents.drawCabinLight) == "function" then
        HorrorEvents:drawCabinLight(x, y)
    else
        -- Fallback: simple warm glow if HorrorEvents isn't loaded
        love.graphics.setColor(1.0, 0.85, 0.4, 0.25)
        love.graphics.circle("fill", x, y, 25)
        love.graphics.setColor(1.0, 0.9, 0.5, 0.5)
        love.graphics.circle("fill", x, y, 8)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function World:drawWater()
    WorldController:drawWaterLevel()
    -- LakeElements doesn't have drawWater - only draw()
end

function World:drawTimeIndicator()
    DayNightCycle:drawTimeIndicator()
end

-- Day/Night Cycle methods
function World:getCurrentHour()
    return DayNightCycle:getCurrentHour()
end

function World:isNight()
    return DayNightCycle:isNight()
end

function World:getTimeOfDay()
    return DayNightCycle:getTimeOfDay()
end

-- Weather methods  
function World:getWeatherType()
    return Weather:getCurrentWeatherType()
end

function World:isRaining()
    return Weather:isRaining()
end

-- Compatibility methods for other systems
function World:getWaterY()
    return WorldController:getWaterY()
end

function World:getGrassY()
    return WorldController:getGrassY()
end

function World:getHousePosition()
    return WorldController:getHousePosition()
end

function World:getLanternPosition()
    return WorldController:getLanternPosition()
end

function World:isNearHouse(playerX, playerY)
    return WorldController:isNearHouse(playerX, playerY)
end

function World:isOnDock(playerX, playerY)
    return WorldController:isOnDock(playerX, playerY)
end

return World
