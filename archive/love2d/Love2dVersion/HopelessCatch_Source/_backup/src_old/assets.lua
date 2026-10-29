-- Asset Manager for Hopeless Catch
-- Easy system to load and manage custom art assets

local Assets = {}

-- Asset storage
local images = {}
local sounds = {}
local placeholders = {} -- track which images are just white-box placeholders

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

    -- Ambient audio (looping)
    sound_ambient_lake = "assets/audio/ambient_lake.ogg",

    -- Horror audio stems (low-frequency dread, stingers, effects)
    sound_horror_hum = "assets/audio/horror_low_hum.ogg",       -- low drone during flicker/stinger events
    sound_vinyl_crackle = "assets/audio/vinyl_crackle.ogg",     -- analog noise texture for horror moments
    sound_fishman_stinger = "assets/audio/fishman_stinger.ogg", -- sharp dissonant hit on Fishman reveal
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
            -- Audio loading
            if love.filesystem.getInfo(path) then
                local src = love.audio.newSource(path, "static")
                -- Ambient/looping tracks should loop; one-shots stay non-looping
                if name:find("ambient") then
                    src:setLooping(true)
                end
                sounds[name] = src
            else
                print("○ Audio file not found (will be silent): " .. path)
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
                placeholders[name] = true
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

-- Start the ambient lake/water loop (call once at game startup)
function Assets:startAmbientAudio()
    local src = self:getSound("sound_ambient_lake")
    if src then
        if not src:isPlaying() then
            src:play()
        end
        print("🔊 Ambient lake audio started (looping)")
    else
        print("○ No ambient audio file found - running silent")
    end
end

-- Stop the ambient loop (e.g., when entering cabin or quitting)
function Assets:stopAmbientAudio()
    local src = self:getSound("sound_ambient_lake")
    if src and src:isPlaying() then
        src:stop()
    end
end

--- Duck (lower) the ambient lake volume. Call when a horror event begins.
-- @param level number 0..1 target volume (e.g., 0.3 = 70% reduction)
function Assets:duckAmbientAudio(level)
    local src = self:getSound("sound_ambient_lake")
    if src then
        src:setVolume(math.max(0, math.min(1, level or 0.3)))
    end
end

--- Restore ambient lake volume to full. Call when a horror event ends.
function Assets:restoreAmbientAudio()
    local src = self:getSound("sound_ambient_lake")
    if src then
        src:setVolume(1.0)
    end
end

--- Play a one-shot horror sound (hum, crackle, stinger). Non-fatal if missing.
-- @param name string key in assetPaths (e.g., "sound_horror_hum")
-- @param volume number optional 0..1 override
function Assets:playHorrorSound(name, volume)
    local src = self:getSound(name)
    if src then
        if volume then src:setVolume(volume) end
        src:play()
    else
        print("○ Horror sound not found (silent): " .. name)
    end
end

--- Check if a real (non-placeholder) image is loaded.
function Assets:hasImage(name)
    return images[name] ~= nil and placeholders[name] == nil
end

--- Check if an image exists at all (including placeholders).
function Assets:hasAnyImage(name)
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
