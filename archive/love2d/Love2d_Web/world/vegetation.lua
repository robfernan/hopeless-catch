-- world/vegetation.lua - Trees, bushes, and plant life
local Vegetation = {}

function Vegetation:drawVegetation(isNight)
    local width = love.graphics.getWidth()
    local waterY = love.graphics.getHeight() * 0.7
    local grassY = waterY - 60
    
    -- Forest background trees
    self:drawForestBackground(grassY, isNight)
    
    -- Main trees along the shoreline
    self:drawShorelineTrees(width, grassY, isNight)
    
    -- Bushes and shrubs
    self:drawBushes(grassY, isNight)
    
    -- Small plants and flowers
    self:drawSmallPlants(grassY)
end

function Vegetation:drawForestBackground(grassY, isNight)
    -- Distant forest silhouette
    local treeAlpha = isNight and 0.6 or 0.8
    love.graphics.setColor(0.1, 0.2, 0.1, treeAlpha)
    
    -- Background tree line
    for x = -50, love.graphics.getWidth() + 50, 15 do
        local treeHeight = 40 + math.sin(x * 0.1) * 15
        love.graphics.polygon("fill",
            x, grassY,
            x + 5, grassY - treeHeight,
            x + 10, grassY)
    end
end

function Vegetation:drawShorelineTrees(width, grassY, isNight)
    local trees = {
        {x = -20, type = "pine"},
        {x = 40, type = "birch"},
        {x = 100, type = "oak"},
        {x = 160, type = "dead"},
        {x = 220, type = "pine"},
        {x = 280, type = "oak"},
        {x = 340, type = "birch"},
        {x = 400, type = "pine"},
        {x = 460, type = "dead"},
        {x = 520, type = "oak"},
        {x = 580, type = "birch"},
        {x = 640, type = "pine"},
        {x = 700, type = "oak"},
        {x = 760, type = "birch"},
        {x = 820, type = "pine"}
    }
    
    for _, tree in ipairs(trees) do
        if tree.x > -80 and tree.x < width + 80 then
            -- Reset graphics state before each tree
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
            
            -- Draw tree based on its type
            if tree.type == "pine" then
                self:drawPineTree(tree.x, grassY, isNight)
            elseif tree.type == "birch" then
                self:drawBirchTree(tree.x, grassY, isNight)
            elseif tree.type == "dead" then
                self:drawDeadTree(tree.x, grassY, isNight)
            else -- oak
                self:drawOakTree(tree.x, grassY, isNight)
            end
        end
    end
    
    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function Vegetation:drawPineTree(x, grassY, isNight)
    local treeHeight = 80
    local alpha = isNight and 0.8 or 1
    
    -- Trunk
    love.graphics.setColor(0.4, 0.2, 0.1, alpha)
    love.graphics.rectangle("fill", x - 3, grassY - 20, 6, 20)
    
    -- Pine layers (bottom to top)
    love.graphics.setColor(0.1, 0.3, 0.1, alpha)
    
    -- Bottom layer
    love.graphics.polygon("fill",
        x, grassY - 25,
        x - 15, grassY - 10,
        x + 15, grassY - 10)
    
    -- Middle layer
    love.graphics.polygon("fill",
        x, grassY - 45,
        x - 12, grassY - 30,
        x + 12, grassY - 30)
    
    -- Top layer
    love.graphics.polygon("fill",
        x, grassY - 60,
        x - 8, grassY - 45,
        x + 8, grassY - 45)
end

function Vegetation:drawBirchTree(x, grassY, isNight)
    local alpha = isNight and 0.8 or 1
    
    -- Trunk (white with black stripes)
    love.graphics.setColor(0.9, 0.9, 0.9, alpha)
    love.graphics.rectangle("fill", x - 2, grassY - 50, 4, 50)
    
    -- Black stripes
    love.graphics.setColor(0.1, 0.1, 0.1, alpha)
    love.graphics.rectangle("fill", x - 2, grassY - 45, 4, 2)
    love.graphics.rectangle("fill", x - 2, grassY - 35, 4, 1)
    love.graphics.rectangle("fill", x - 2, grassY - 25, 4, 2)
    love.graphics.rectangle("fill", x - 2, grassY - 15, 4, 1)
    
    -- Leaves
    love.graphics.setColor(0.2, 0.6, 0.2, alpha)
    love.graphics.circle("fill", x - 8, grassY - 55, 12)
    love.graphics.circle("fill", x + 6, grassY - 60, 10)
    love.graphics.circle("fill", x - 2, grassY - 65, 8)
end

function Vegetation:drawOakTree(x, grassY, isNight)
    local alpha = isNight and 0.8 or 1
    
    -- Trunk
    love.graphics.setColor(0.4, 0.3, 0.2, alpha)
    love.graphics.rectangle("fill", x - 4, grassY - 40, 8, 40)
    
    -- Large leafy crown
    love.graphics.setColor(0.2, 0.5, 0.1, alpha)
    love.graphics.circle("fill", x - 10, grassY - 50, 15)
    love.graphics.circle("fill", x + 8, grassY - 55, 12)
    love.graphics.circle("fill", x - 5, grassY - 65, 14)
    love.graphics.circle("fill", x + 5, grassY - 45, 10)
end

function Vegetation:drawDeadTree(x, grassY, isNight)
    local alpha = isNight and 0.7 or 0.9
    
    -- Dead trunk
    love.graphics.setColor(0.3, 0.2, 0.15, alpha)
    love.graphics.rectangle("fill", x - 3, grassY - 45, 6, 45)
    
    -- Bare branches
    love.graphics.setColor(0.2, 0.15, 0.1, alpha)
    love.graphics.setLineWidth(2)
    
    -- Main branches
    love.graphics.line(x, grassY - 35, x - 12, grassY - 50)
    love.graphics.line(x, grassY - 30, x + 10, grassY - 45)
    love.graphics.line(x, grassY - 25, x - 8, grassY - 40)
    
    -- Smaller branches
    love.graphics.setLineWidth(1)
    love.graphics.line(x - 12, grassY - 50, x - 15, grassY - 55)
    love.graphics.line(x - 12, grassY - 50, x - 10, grassY - 55)
    love.graphics.line(x + 10, grassY - 45, x + 13, grassY - 50)
    love.graphics.line(x + 10, grassY - 45, x + 8, grassY - 50)
    
    love.graphics.setLineWidth(1)
end

function Vegetation:drawBushes(grassY, isNight)
    local alpha = isNight and 0.7 or 1
    love.graphics.setColor(0.15, 0.4, 0.1, alpha)
    
    local bushes = {
        {x = 25, show = true},
        {x = 75, show = false},
        {x = 125, show = true},
        {x = 175, show = true},
        {x = 225, show = false},
        {x = 275, show = true},
        {x = 325, show = true},
        {x = 375, show = false},
        {x = 425, show = true},
        {x = 475, show = true},
        {x = 525, show = false},
        {x = 575, show = true},
        {x = 625, show = true},
        {x = 675, show = false},
        {x = 725, show = true}
    }
    
    for _, bush in ipairs(bushes) do
        if bush.show then
            -- Small round bush
            love.graphics.circle("fill", bush.x, grassY + 10, 8)
            love.graphics.circle("fill", bush.x + 5, grassY + 8, 6)
            love.graphics.circle("fill", bush.x - 3, grassY + 12, 5)
        end
    end
end

function Vegetation:drawSmallPlants(grassY)
    love.graphics.setColor(0.3, 0.6, 0.2, 0.8)
    
    -- Small plants and flowers scattered around
    local plants = {
        {x = 60, type = "flower"},
        {x = 140, type = "grass"},
        {x = 180, type = "flower"},
        {x = 260, type = "grass"},
        {x = 320, type = "flower"},
        {x = 380, type = "grass"},
        {x = 440, type = "flower"},
        {x = 500, type = "grass"},
        {x = 560, type = "flower"},
        {x = 640, type = "grass"},
        {x = 700, type = "flower"}
    }
    
    for _, plant in ipairs(plants) do
        if plant.type == "flower" then
            -- Small flower
            love.graphics.setColor(0.8, 0.3, 0.4, 0.8)
            love.graphics.circle("fill", plant.x, grassY + 15, 2)
            love.graphics.setColor(0.2, 0.5, 0.1, 0.8)
            love.graphics.line(plant.x, grassY + 15, plant.x, grassY + 25)
        else
            -- Tall grass
            love.graphics.setColor(0.3, 0.6, 0.2, 0.8)
            love.graphics.line(plant.x, grassY + 20, plant.x - 1, grassY + 10)
            love.graphics.line(plant.x + 2, grassY + 22, plant.x + 1, grassY + 12)
        end
    end
end

return Vegetation
