-- world/terrainrenderer.lua - Ground, mountains, terrain elements
local TerrainRenderer = {}

function TerrainRenderer:drawDistantTerrain()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local waterY = height * 0.7
    
    -- Distant mountains
    love.graphics.setColor(0.6, 0.7, 0.9, 0.7)
    
    -- Mountain range 1 (furthest)
    love.graphics.polygon("fill", 
        0, waterY,
        width * 0.2, waterY - 80,
        width * 0.4, waterY - 60,
        width * 0.6, waterY - 100,
        width * 0.8, waterY - 40,
        width, waterY - 60,
        width, waterY)
    
    -- Mountain range 2 (closer)
    love.graphics.setColor(0.5, 0.6, 0.8, 0.8)
    love.graphics.polygon("fill",
        0, waterY,
        width * 0.15, waterY - 50,
        width * 0.35, waterY - 80,
        width * 0.55, waterY - 35,
        width * 0.75, waterY - 65,
        width * 0.9, waterY - 25,
        width, waterY)
    
    -- Foothills
    love.graphics.setColor(0.4, 0.5, 0.6, 0.9)
    love.graphics.polygon("fill",
        0, waterY,
        width * 0.3, waterY - 30,
        width * 0.7, waterY - 45,
        width, waterY - 20,
        width, waterY)
end

function TerrainRenderer:drawGround()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local waterY = height * 0.7
    local grassY = waterY - 60
    
    -- Ground/soil layer - only draw above water level
    love.graphics.setColor(0.4, 0.3, 0.2, 1)
    love.graphics.rectangle("fill", 0, grassY, width, waterY - grassY)
    
    -- Grass layer - shorter so it doesn't block background
    love.graphics.setColor(0.2, 0.5, 0.1, 1)
    love.graphics.rectangle("fill", 0, grassY, width, 40)  -- Reduced from 60 to 40
    
    -- Grass texture details
    love.graphics.setColor(0.3, 0.6, 0.2, 0.8)
    for x = 0, width, 8 do
        local grassHeight = math.sin(x * 0.1) * 3 + 5
        love.graphics.rectangle("fill", x, grassY, 4, grassHeight)
    end
    
    -- Small rocks and details
    love.graphics.setColor(0.5, 0.5, 0.4, 1)
    local rocks = {
        {x = 45, y = grassY + 20, size = 3},
        {x = 120, y = grassY + 15, size = 2},
        {x = 200, y = grassY + 25, size = 4},
        {x = 350, y = grassY + 18, size = 2},
        {x = 480, y = grassY + 22, size = 3},
        {x = 620, y = grassY + 16, size = 2},
        {x = 720, y = grassY + 24, size = 3}
    }
    
    for _, rock in ipairs(rocks) do
        love.graphics.circle("fill", rock.x, rock.y, rock.size)
    end
end

function TerrainRenderer:drawPath()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local grassY = height * 0.7 - 60
    
    -- Dirt path
    love.graphics.setColor(0.6, 0.5, 0.3, 0.8)
    
    -- Path from house to dock
    local pathPoints = {}
    for x = width - 200, width * 0.6, -10 do
        local pathY = grassY + 30 + math.sin(x * 0.02) * 5
        table.insert(pathPoints, x)
        table.insert(pathPoints, pathY)
        table.insert(pathPoints, x)
        table.insert(pathPoints, pathY + 15)
    end
    
    if #pathPoints >= 8 then
        -- Create path polygon
        local pathMesh = {}
        for i = 1, #pathPoints, 4 do
            if i + 3 <= #pathPoints then
                table.insert(pathMesh, pathPoints[i])
                table.insert(pathMesh, pathPoints[i + 1])
                table.insert(pathMesh, pathPoints[i + 2])
                table.insert(pathMesh, pathPoints[i + 3])
            end
        end
        
        if #pathMesh >= 8 then
            love.graphics.polygon("fill", pathMesh)
        end
    end
end

return TerrainRenderer
