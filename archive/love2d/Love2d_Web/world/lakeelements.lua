-- LakeElements.lua - Interactive elements in the lake
local LakeElements = {}

local elements = {}
local ripples = {}
local shootingStars = {}
local ufos = {}

-- Types of lake elements
local elementTypes = {
    debris = {
        name = "Floating Debris",
        fishingEffect = 0.8, -- Slightly harder to fish
        rareFishChance = 0.1, -- 10% chance for rare fish
        size = {15, 25},
        color = {0.4, 0.3, 0.2, 0.8}
    },
    lilypad = {
        name = "Lily Pad",
        fishingEffect = 1.2, -- Better fishing
        rareFishChance = 0.3, -- 30% chance for rare fish
        size = {20, 30},
        color = {0.2, 0.6, 0.3, 0.9}
    },
    sunkenlog = {
        name = "Sunken Log",
        fishingEffect = 0.5, -- Risk of snagging
        specialCatchChance = 0.4, -- 40% chance for special catch
        size = {40, 60},
        color = {0.3, 0.2, 0.1, 0.7}
    }
}

function LakeElements:init()
    elements = {}
    ripples = {}
    shootingStars = {}
    ufos = {}
    
    -- Generate random lake elements
    self:generateElements()
    
    -- Initialize mysterious ripples
    self:scheduleNextRipple()
end

function LakeElements:generateElements()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local waterY = height * 0.7
    
    -- Generate debris
    for i = 1, math.random(3, 6) do
        local element = {
            type = "debris",
            x = math.random(50, width - 50),
            y = math.random(waterY + 10, height - 50),
            size = math.random(elementTypes.debris.size[1], elementTypes.debris.size[2]),
            rotation = math.random() * math.pi * 2,
            bobOffset = math.random() * math.pi * 2
        }
        table.insert(elements, element)
    end
    
    -- Generate lily pads
    for i = 1, math.random(2, 4) do
        local element = {
            type = "lilypad",
            x = math.random(100, width - 100),
            y = math.random(waterY + 5, waterY + 40),
            size = math.random(elementTypes.lilypad.size[1], elementTypes.lilypad.size[2]),
            rotation = math.random() * math.pi * 2,
            bobOffset = math.random() * math.pi * 2
        }
        table.insert(elements, element)
    end
    
    -- Generate sunken logs
    for i = 1, math.random(1, 3) do
        local element = {
            type = "sunkenlog",
            x = math.random(80, width - 80),
            y = math.random(waterY + 20, height - 30),
            size = math.random(elementTypes.sunkenlog.size[1], elementTypes.sunkenlog.size[2]),
            rotation = math.random() * math.pi * 2,
            bobOffset = math.random() * math.pi * 2
        }
        table.insert(elements, element)
    end
end

function LakeElements:update(dt)
    -- Update element positions (gentle bobbing)
    for _, element in ipairs(elements) do
        element.bobOffset = element.bobOffset + dt * 0.5
    end
    
    -- Update mysterious ripples
    for i = #ripples, 1, -1 do
        local ripple = ripples[i]
        ripple.radius = ripple.radius + dt * 50
        ripple.alpha = ripple.alpha - dt * 0.8
        
        if ripple.alpha <= 0 then
            table.remove(ripples, i)
        end
    end
    
    -- Check if it's time for next mysterious ripple
    if love.timer.getTime() > self.nextRippleTime then
        self:createMysteriousRipple()
        self:scheduleNextRipple()
    end
    
    -- Update shooting stars
    for i = #shootingStars, 1, -1 do
        local star = shootingStars[i]
        star.x = star.x + star.vx * dt
        star.y = star.y + star.vy * dt
        star.life = star.life - dt
        
        -- Mysterious stop effect
        if star.life < 1.0 and not star.stopped then
            star.stopped = true
            star.vx = 0
            star.vy = 0
            star.stopTime = 3.0 -- Hang in sky for 3 seconds
            print("⭐ A shooting star stops mid-flight...")
        end
        
        if star.stopped then
            star.stopTime = star.stopTime - dt
            if star.stopTime <= 0 then
                table.remove(shootingStars, i)
            end
        elseif star.life <= 0 then
            table.remove(shootingStars, i)
        end
    end
    
    -- Update UFOs
    for i = #ufos, 1, -1 do
        local ufo = ufos[i]
        ufo.x = ufo.x + ufo.vx * dt
        ufo.y = ufo.y + math.sin(love.timer.getTime() * 2 + ufo.wobble) * 10 * dt
        ufo.life = ufo.life - dt
        
        -- Fade out effect
        if ufo.life < 1.0 then
            ufo.alpha = ufo.life
        end
        
        if ufo.life <= 0 then
            table.remove(ufos, i)
        end
    end
    
    -- Occasionally spawn some atmospheric elements (no horror dependency)
    if math.random() < 0.0005 then -- 0.05% chance per frame - reduced for more peaceful atmosphere
        if math.random() < 0.7 then
            self:spawnShootingStar()
        end
    end
end

function LakeElements:scheduleNextRipple()
    -- Next ripple in 10-30 seconds
    self.nextRippleTime = love.timer.getTime() + math.random(10, 30)
end

function LakeElements:createMysteriousRipple()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local waterY = height * 0.7
    
    local ripple = {
        x = math.random(50, width - 50),
        y = math.random(waterY, height - 50),
        radius = 5,
        alpha = 1.0
    }
    
    table.insert(ripples, ripple)
    print("🌊 Mysterious ripples appear in the water...")
end

function LakeElements:spawnShootingStar()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    local star = {
        x = -50,
        y = math.random(20, 100),
        vx = math.random(100, 200),
        vy = math.random(20, 60),
        life = 4.0,
        stopped = false,
        stopTime = 0
    }
    
    table.insert(shootingStars, star)
end

function LakeElements:spawnUFO()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    local ufo = {
        x = width + 50,
        y = math.random(30, 120),
        vx = -math.random(80, 120),
        life = math.random(5, 8),
        alpha = 1.0,
        wobble = math.random() * math.pi * 2
    }
    
    table.insert(ufos, ufo)
    print("🛸 Something unidentifiable appears in the sky...")
end

function LakeElements:draw()
    -- Draw lake elements
    for _, element in ipairs(elements) do
        self:drawElement(element)
    end
    
    -- Draw mysterious ripples
    love.graphics.setLineWidth(2)
    for _, ripple in ipairs(ripples) do
        love.graphics.setColor(1, 1, 1, ripple.alpha * 0.8)
        love.graphics.circle("line", ripple.x, ripple.y, ripple.radius)
        love.graphics.setColor(0.8, 0.8, 1, ripple.alpha * 0.4)
        love.graphics.circle("line", ripple.x, ripple.y, ripple.radius * 0.7)
    end
    love.graphics.setLineWidth(1)
    
    -- Draw shooting stars
    for _, star in ipairs(shootingStars) do
        if star.stopped then
            -- Stopped star - pulsing effect
            local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 5)
            love.graphics.setColor(1, 1, 0.8, pulse)
            love.graphics.circle("fill", star.x, star.y, 4)
            love.graphics.setColor(1, 1, 1, pulse * 0.5)
            love.graphics.circle("line", star.x, star.y, 8)
        else
            -- Moving star with tail
            love.graphics.setColor(1, 1, 0.8, 0.9)
            love.graphics.circle("fill", star.x, star.y, 3)
            
            -- Tail effect
            love.graphics.setColor(1, 1, 0.8, 0.5)
            love.graphics.line(star.x, star.y, star.x - star.vx * 0.1, star.y - star.vy * 0.1)
        end
    end
    
    -- Draw UFOs
    for _, ufo in ipairs(ufos) do
        love.graphics.setColor(0.8, 0.8, 1, ufo.alpha * 0.7)
        love.graphics.ellipse("fill", ufo.x, ufo.y, 20, 8)
        love.graphics.setColor(1, 1, 0.8, ufo.alpha * 0.9)
        love.graphics.ellipse("fill", ufo.x, ufo.y - 3, 8, 4)
        
        -- Blinking lights
        if math.sin(love.timer.getTime() * 10) > 0 then
            love.graphics.setColor(1, 0.2, 0.2, ufo.alpha)
            love.graphics.circle("fill", ufo.x - 12, ufo.y, 2)
            love.graphics.setColor(0.2, 1, 0.2, ufo.alpha)
            love.graphics.circle("fill", ufo.x + 12, ufo.y, 2)
        end
    end
end

function LakeElements:drawElement(element)
    local typeData = elementTypes[element.type]
    local bobOffset = math.sin(element.bobOffset) * 2
    
    love.graphics.push()
    love.graphics.translate(element.x, element.y + bobOffset)
    love.graphics.rotate(element.rotation)
    
    love.graphics.setColor(typeData.color)
    
    if element.type == "debris" then
        -- Draw as rough rectangle
        love.graphics.rectangle("fill", -element.size/2, -element.size/4, element.size, element.size/2)
    elseif element.type == "lilypad" then
        -- Draw as circle with notch
        love.graphics.circle("fill", 0, 0, element.size/2)
        love.graphics.setColor(typeData.color[1], typeData.color[2], typeData.color[3], typeData.color[4] * 0.5)
        love.graphics.polygon("fill", 0, 0, element.size/2, 0, element.size/4, -element.size/4)
    elseif element.type == "sunkenlog" then
        -- Draw as elongated rectangle
        love.graphics.rectangle("fill", -element.size/2, -element.size/6, element.size, element.size/3)
    end
    
    love.graphics.pop()
end

-- Check if fishing line intersects with elements
function LakeElements:checkFishingInteraction(bobberX, bobberY)
    for _, element in ipairs(elements) do
        local distance = math.sqrt((bobberX - element.x)^2 + (bobberY - element.y)^2)
        
        if distance < element.size then
            local typeData = elementTypes[element.type]
            
            return {
                type = element.type,
                fishingEffect = typeData.fishingEffect,
                rareFishChance = typeData.rareFishChance,
                specialCatchChance = typeData.specialCatchChance
            }
        end
    end
    
    return nil
end

-- Get weather-adjusted fishing effects
function LakeElements:getFishingModifiers(bobberX, bobberY)
    local interaction = self:checkFishingInteraction(bobberX, bobberY)
    if interaction then
        return interaction
    end
    
    -- Default - open water
    return {
        type = "open_water",
        fishingEffect = 1.0,
        rareFishChance = 0.0,
        specialCatchChance = 0.0
    }
end

return LakeElements
