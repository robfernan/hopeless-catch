-- world/structures.lua - Buildings, dock, lantern, and man-made objects
local Structures = {}

function Structures:drawStructures()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local waterY = height * 0.7
    local grassY = waterY - 60
    
    -- House positioned on the grass/ground
    local houseX = width - 200
    local houseY = grassY - 60  -- Reduced from 80 to 60 to put house on grass
    
    -- Lantern on the dock/pier area
    local lanternX = width * 0.6
    local lanternY = height - 130
    
    self:drawHouse(houseX, houseY)
    self:drawDock(width, waterY)
    self:drawLantern(lanternX, lanternY)
    self:drawFence(grassY)
end

function Structures:drawHouse(houseX, houseY)
    -- House foundation
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", houseX - 5, houseY + 60, 90, 10)
    
    -- Main house structure
    love.graphics.setColor(0.6, 0.4, 0.2, 1)
    love.graphics.rectangle("fill", houseX, houseY, 80, 60)
    
    -- Roof
    love.graphics.setColor(0.4, 0.2, 0.1, 1)
    love.graphics.polygon("fill",
        houseX - 10, houseY,
        houseX + 40, houseY - 30,
        houseX + 90, houseY)
    
    -- Chimney
    love.graphics.setColor(0.5, 0.3, 0.2, 1)
    love.graphics.rectangle("fill", houseX + 60, houseY - 25, 8, 35)
    
    -- Chimney smoke
    love.graphics.setColor(0.8, 0.8, 0.8, 0.6)
    local smokeOffset = love.timer.getTime() * 2
    for i = 1, 5 do
        local smokeX = houseX + 64 + math.sin(smokeOffset + i) * 3
        local smokeY = houseY - 25 - (i * 8) + math.cos(smokeOffset + i * 0.5) * 2
        love.graphics.circle("fill", smokeX, smokeY, 2 + i * 0.5)
    end
    
    -- Door
    love.graphics.setColor(0.3, 0.2, 0.1, 1)
    love.graphics.rectangle("fill", houseX + 10, houseY + 30, 12, 30)
    
    -- Door handle
    love.graphics.setColor(0.8, 0.7, 0.3, 1)
    love.graphics.circle("fill", houseX + 20, houseY + 45, 1)
    
    -- Windows
    love.graphics.setColor(0.7, 0.8, 1, 0.8)
    love.graphics.rectangle("fill", houseX + 35, houseY + 15, 12, 12)
    love.graphics.rectangle("fill", houseX + 55, houseY + 15, 12, 12)
    
    -- Window frames
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", houseX + 35, houseY + 15, 12, 12)
    love.graphics.rectangle("line", houseX + 55, houseY + 15, 12, 12)
    love.graphics.line(houseX + 41, houseY + 15, houseX + 41, houseY + 27)
    love.graphics.line(houseX + 61, houseY + 15, houseX + 61, houseY + 27)
    love.graphics.setLineWidth(1)
    
    -- Window light (if night)
    local DayNightCycle = require("world.daynightcycle")
    if DayNightCycle:isNightTime() then
        love.graphics.setColor(1, 0.9, 0.6, 0.7)
        love.graphics.rectangle("fill", houseX + 36, houseY + 16, 10, 10)
        love.graphics.rectangle("fill", houseX + 56, houseY + 16, 10, 10)
    end
end

function Structures:drawDock(width, waterY)
    -- Wooden dock extending into water - fixed for 800x600
    local dockX = width * 0.5  -- Start at center
    local dockY = waterY - 25  -- Raised above water level
    local dockWidth = 150      -- Fixed width for 800x600
    local dockHeight = 35      -- Keep height constant
    
    -- Dock platform
    love.graphics.setColor(0.6, 0.4, 0.2, 1)
    love.graphics.rectangle("fill", dockX, dockY, dockWidth, dockHeight)
    
    -- Dock planks
    love.graphics.setColor(0.5, 0.3, 0.15, 1)
    for i = 0, dockWidth, 8 do
        love.graphics.line(dockX + i, dockY, dockX + i, dockY + dockHeight)
    end
    
    -- Dock supports/pillars
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    local pillarPositions = {dockX + 15, dockX + 40, dockX + 65, dockX + 85}
    for _, pillarX in ipairs(pillarPositions) do
        love.graphics.rectangle("fill", pillarX - 2, dockY + 15, 4, dockHeight - 15)
        
        -- Pillar reflection in water
        love.graphics.setColor(0.4, 0.3, 0.2, 0.3)
        love.graphics.rectangle("fill", pillarX - 2, dockY + 15, 4, 20)
    end
    
    -- Dock rope/anchor
    love.graphics.setColor(0.7, 0.6, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(dockX + dockWidth - 10, dockY + 5, dockX + dockWidth - 10, waterY + 30)
    love.graphics.setLineWidth(1)
    
    -- Small anchor
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.circle("fill", dockX + dockWidth - 10, waterY + 30, 3)
end

function Structures:drawLantern(lanternX, lanternY)
    -- Lantern post
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", lanternX - 2, lanternY, 4, 40)
    
    -- Lantern base
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", lanternX - 4, lanternY + 35, 8, 5)
    
    -- Lantern frame
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", lanternX - 6, lanternY - 15, 12, 20)
    
    -- Lantern glass
    love.graphics.setColor(0.9, 0.9, 1, 0.3)
    love.graphics.rectangle("fill", lanternX - 5, lanternY - 14, 10, 18)
    
    -- Lantern light
    local DayNightCycle = require("world.daynightcycle")
    if DayNightCycle:isNightTime() then
        -- Warm light glow
        love.graphics.setColor(1, 0.8, 0.4, 0.8)
        love.graphics.rectangle("fill", lanternX - 5, lanternY - 14, 10, 18)
        
        -- Light glow effect
        love.graphics.setColor(1, 0.8, 0.4, 0.3)
        love.graphics.circle("fill", lanternX, lanternY - 5, 20)
        love.graphics.setColor(1, 0.8, 0.4, 0.1)
        love.graphics.circle("fill", lanternX, lanternY - 5, 35)
    end
    
    -- Lantern top
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.polygon("fill",
        lanternX - 4, lanternY - 15,
        lanternX, lanternY - 22,
        lanternX + 4, lanternY - 15)
end

function Structures:drawFence(grassY)
    local width = love.graphics.getWidth()
    
    -- Wooden fence along the property
    love.graphics.setColor(0.5, 0.4, 0.3, 1)
    
    -- Fence posts
    for x = 50, width - 250, 40 do
        love.graphics.rectangle("fill", x - 1, grassY + 5, 2, 25)
        
        -- Fence rails
        love.graphics.rectangle("fill", x - 1, grassY + 10, 40, 2)
        love.graphics.rectangle("fill", x - 1, grassY + 20, 40, 2)
    end
    
    -- Gate near house
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.rectangle("fill", width - 280, grassY + 5, 20, 25)
    love.graphics.rectangle("fill", width - 250, grassY + 5, 20, 25)
    
    -- Gate hinges
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.circle("fill", width - 280, grassY + 10, 1)
    love.graphics.circle("fill", width - 280, grassY + 25, 1)
end

return Structures
