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
    WorldController:update(dt)
    DayNightCycle:update(dt)
    Weather:update(dt)
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
