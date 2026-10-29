-- Asset Manager for Hopeless Catch
-- Easy system to load and manage custom art assets

local Assets = {}

-- Asset storage
local images = {}
local sounds = {}

-- Asset paths (easy to modify when you add your art)
local assetPaths = {
    -- Fish sprites (assets/fish/)
    fish_sunfish = "assets/fish/sunfish.png",
    fish_bass = "assets/fish/bass.png",
    fish_trout = "assets/fish/trout.png",
    fish_catfish = "assets/fish/catfish.png",
    fish_golden_carp = "assets/fish/golden_carp.png",
    fish_pale_crawler = "assets/fish/pale_crawler.png",
    fish_whispering_eel = "assets/fish/whispering_eel.png",
    fish_bleeding_carp = "assets/fish/bleeding_carp.png",
    fishman = "assets/fish/fishman.png",

    -- Bait/Lures (assets/bait/)
    bait_worms = "assets/bait/worms.png",
    bait_minnows = "assets/bait/minnows.png",
    bait_cheese = "assets/bait/cheese.png",
    bait_corn = "assets/bait/corn.png",

    -- Characters & Environment
    player_character = "assets/player.png",
}

-- Fallback colors for when sprites don't exist yet
local fallbackColors = {
    fish_bass = {0.4, 0.6, 0.3},
    fish_trout = {0.7, 0.5, 0.3},
    fish_catfish = {0.3, 0.3, 0.3},
    fish_salmon = {0.8, 0.4, 0.4},
    fish_abomination = {0.6, 0.1, 0.2},
    fish_void_swimmer = {0.1, 0.1, 0.3},
    fish_pale_thing = {0.9, 0.9, 0.9},
    fish_whisper_fish = {0.4, 0.2, 0.5},
    fishman = {0.2, 0.3, 0.2}
}

function Assets:load()
    -- Try to load all assets, use fallbacks if files don't exist
    for name, path in pairs(assetPaths) do
        if name:sub(1, 5) == "sound" then
            -- Audio loading (for later)
            if love.filesystem.getInfo(path) then
                sounds[name] = love.audio.newSource(path, "static")
            end
        else
            -- Image loading
            if love.filesystem.getInfo(path) then
                images[name] = love.graphics.newImage(path)
                print("✓ Loaded custom asset: " .. name)
            else
                -- Create placeholder white rectangle for missing images
                local canvas = love.graphics.newCanvas(64, 64)
                love.graphics.setCanvas(canvas)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("fill", 0, 0, 64, 64)
                love.graphics.setColor(0.8, 0.8, 0.8, 0.5)
                love.graphics.rectangle("line", 0, 0, 64, 64)
                love.graphics.setCanvas()
                images[name] = canvas
                print("○ Using placeholder for: " .. name .. " (add " .. path .. ")")
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    print("Assets loaded! Add your custom art to the assets/ folder to replace placeholders.")
end

function Assets:getImage(name)
    return images[name]
end

function Assets:getSound(name)
    return sounds[name]
end

function Assets:hasImage(name)
    return images[name] ~= nil
end

-- Helper function to draw fish with proper scaling
function Assets:drawFish(fishName, x, y, scale, rotation)
    scale = scale or 1
    rotation = rotation or 0
    
    -- Special case for Fishman
    local imageName = fishName:lower() == "fishman" and "fishman" or "fish_" .. fishName:lower():gsub(" ", "_")
    local image = self:getImage(imageName)
    if image then
        local w, h = image:getDimensions()
        love.graphics.draw(image, x, y, rotation, scale, scale, w/2, h/2)
        return true
    end
    return false
end

-- Helper function to draw bait/lures in tacklebox
function Assets:drawBait(baitName, x, y, scale, selected)
    scale = scale or 1
    
    local image = self:getImage("bait_" .. baitName:lower():gsub(" ", "_"))
    if image then
        if selected then
            love.graphics.setColor(1, 1, 0.7, 1) -- Highlight selected
        end
        love.graphics.draw(image, x, y, 0, scale, scale)
        love.graphics.setColor(1, 1, 1, 1) -- Reset
        return true
    end
    return false
end

-- Helper to create asset directories
function Assets:createDirectories()
    local dirs = {
        "assets/ui",
        "assets/fish",
        "assets/entities", 
        "assets/bait",
        "assets/environment",
        "assets/effects",
        "assets/audio"
    }
    
    for _, dir in ipairs(dirs) do
        if not love.filesystem.getInfo(dir) then
            love.filesystem.createDirectory(dir)
            print("Created directory: " .. dir)
        end
    end
end

return Assets
