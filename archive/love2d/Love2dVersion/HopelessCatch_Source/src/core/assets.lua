-- src/core/assets.lua - Asset Management & Sound Synthesis Engine
local Assets = {
    images = {},
    quads = {},
    fonts = {},
    sounds = {},
    isMuted = false
}

function Assets.init()
    -- Load standard fonts
    Assets.fonts.small = love.graphics.newFont(12)
    Assets.fonts.medium = love.graphics.newFont(16)
    Assets.fonts.large = love.graphics.newFont(24)
    Assets.fonts.title = love.graphics.newFont(42)
    Assets.fonts.huge = love.graphics.newFont(64)
    
    -- Load all existing sprite files from assets/
    Assets.loadImages()
    
    -- Generate procedural horror sound sources (retro vinyl crackle, low water drone, reel clicks, bite splash)
    Assets.generateProceduralSounds()
end

function Assets.loadImages()
    local fishDir = "assets/fish"
    local items = love.filesystem.getDirectoryItems(fishDir)
    for _, file in ipairs(items) do
        if file:match("%.png$") then
            local id = "fish_" .. file:gsub("%.png$", "")
            local path = fishDir .. "/" .. file
            local success, img = pcall(love.graphics.newImage, path)
            if success and img then
                img:setFilter("nearest", "nearest")
                Assets.images[id] = img
            end
        end
    end
    
    local baitDir = "assets/bait"
    local bItems = love.filesystem.getDirectoryItems(baitDir)
    for _, file in ipairs(bItems) do
        if file:match("%.png$") then
            local id = "bait_" .. file:gsub("%.png$", "")
            local path = baitDir .. "/" .. file
            local success, img = pcall(love.graphics.newImage, path)
            if success and img then
                img:setFilter("nearest", "nearest")
                Assets.images[id] = img
            end
        end
    end
    
    if love.filesystem.getInfo("assets/player.png") then
        local img = love.graphics.newImage("assets/player.png")
        img:setFilter("nearest", "nearest")
        Assets.images.player = img
    end

    if love.filesystem.getInfo("assets/player_sheet.png") then
        local img = love.graphics.newImage("assets/player_sheet.png")
        img:setFilter("nearest", "nearest")
        Assets.images.player_sheet = img
        
        local w = img:getWidth() / 4
        local h = img:getHeight() / 2
        Assets.quads.player = {
            idle         = love.graphics.newQuad(0 * w, 0, w, h, img:getDimensions()),
            charge       = love.graphics.newQuad(1 * w, 0, w, h, img:getDimensions()),
            cast         = love.graphics.newQuad(2 * w, 0, w, h, img:getDimensions()),
            reel         = love.graphics.newQuad(3 * w, 0, w, h, img:getDimensions()),
            idle_flip    = love.graphics.newQuad(0 * w, h, w, h, img:getDimensions()),
            charge_flip  = love.graphics.newQuad(1 * w, h, w, h, img:getDimensions()),
            cast_flip    = love.graphics.newQuad(2 * w, h, w, h, img:getDimensions()),
            reel_flip    = love.graphics.newQuad(3 * w, h, w, h, img:getDimensions())
        }
    end

    if love.filesystem.getInfo("assets/pier_wood.png") then
        local img = love.graphics.newImage("assets/pier_wood.png")
        img:setFilter("linear", "linear")
        img:setWrap("repeat", "repeat")
        Assets.images.pier_wood = img
    end

    if love.filesystem.getInfo("assets/fish/fishman_sheet.png") then
        local img = love.graphics.newImage("assets/fish/fishman_sheet.png")
        img:setFilter("nearest", "nearest")
        Assets.images.fish_fishman = img
        
        local w = img:getWidth() / 2
        local h = img:getHeight() / 2
        Assets.quads.fishman = {
            lurk   = love.graphics.newQuad(0, 0, w, h, img:getDimensions()),
            flash  = love.graphics.newQuad(w, 0, w, h, img:getDimensions()),
            strike = love.graphics.newQuad(0, h, w, h, img:getDimensions()),
            roar   = love.graphics.newQuad(w, h, w, h, img:getDimensions())
        }
    end

    if love.filesystem.getInfo("assets/water_retro.png") then
        local img = love.graphics.newImage("assets/water_retro.png")
        img:setFilter("linear", "linear")
        img:setWrap("repeat", "repeat")
        Assets.images.water_retro = img
    end
end

function Assets.getImage(id)
    if not Assets.images[id] then
        if id == "player_sheet" and love.filesystem.getInfo("assets/player_sheet.png") then
            local img = love.graphics.newImage("assets/player_sheet.png")
            img:setFilter("nearest", "nearest")
            Assets.images.player_sheet = img
            local w = img:getWidth() / 4
            local h = img:getHeight() / 2
            Assets.quads.player = {
                idle         = love.graphics.newQuad(0 * w, 0, w, h, img:getDimensions()),
                charge       = love.graphics.newQuad(1 * w, 0, w, h, img:getDimensions()),
                cast         = love.graphics.newQuad(2 * w, 0, w, h, img:getDimensions()),
                reel         = love.graphics.newQuad(3 * w, 0, w, h, img:getDimensions()),
                idle_flip    = love.graphics.newQuad(0 * w, h, w, h, img:getDimensions()),
                charge_flip  = love.graphics.newQuad(1 * w, h, w, h, img:getDimensions()),
                cast_flip    = love.graphics.newQuad(2 * w, h, w, h, img:getDimensions()),
                reel_flip    = love.graphics.newQuad(3 * w, h, w, h, img:getDimensions())
            }
        end
    end
    return Assets.images[id]
end

--- Procedural SFX generation using SoundData (ensures rich audio even without external wav/ogg files)
function Assets.generateProceduralSounds()
    local sampleRate = 22050
    
    -- 1. Reel Click
    local clickLen = math.floor(sampleRate * 0.04)
    local clickData = love.sound.newSoundData(clickLen, sampleRate, 16, 1)
    for i = 0, clickLen - 1 do
        local t = i / sampleRate
        local sample = math.sin(t * 3200 * math.pi * 2) * math.exp(-i / (clickLen * 0.2))
        sample = sample * (math.random() * 0.3 + 0.7)
        clickData:setSample(i, sample * 0.6)
    end
    Assets.sounds.reel_click = love.audio.newSource(clickData, "static")
    
    -- 2. Water Splash
    local splashLen = math.floor(sampleRate * 0.35)
    local splashData = love.sound.newSoundData(splashLen, sampleRate, 16, 1)
    for i = 0, splashLen - 1 do
        local progress = i / splashLen
        local noise = (math.random() * 2 - 1)
        local lowFreq = math.sin(i * 0.05)
        local sample = (noise * 0.7 + lowFreq * 0.3) * (1 - progress)^1.8
        splashData:setSample(i, sample * 0.7)
    end
    Assets.sounds.splash = love.audio.newSource(splashData, "static")
    
    -- 3. Bite Alert / Stinger
    local stingerLen = math.floor(sampleRate * 0.6)
    local stingerData = love.sound.newSoundData(stingerLen, sampleRate, 16, 1)
    for i = 0, stingerLen - 1 do
        local t = i / sampleRate
        local freq = 140 - (t * 80) -- ominous downward pitch
        local sample = (math.sin(t * freq * math.pi * 2) + 0.4 * math.sin(t * (freq * 1.5) * math.pi * 2)) * math.exp(-t * 2.5)
        stingerData:setSample(i, sample * 0.8)
    end
    Assets.sounds.bite_stinger = love.audio.newSource(stingerData, "static")
    
    -- 4. Line Snapped
    local snapLen = math.floor(sampleRate * 0.2)
    local snapData = love.sound.newSoundData(snapLen, sampleRate, 16, 1)
    for i = 0, snapLen - 1 do
        local t = i / sampleRate
        local sample = (math.random() * 2 - 1) * math.exp(-t * 25)
        snapData:setSample(i, sample * 0.9)
    end
    Assets.sounds.line_snap = love.audio.newSource(snapData, "static")
    
    -- 5. Deep Horror Lake Drone (looping)
    local droneLen = math.floor(sampleRate * 3.0)
    local droneData = love.sound.newSoundData(droneLen, sampleRate, 16, 1)
    for i = 0, droneLen - 1 do
        local t = i / sampleRate
        local s1 = math.sin(t * 45 * math.pi * 2)
        local s2 = math.sin(t * 48 * math.pi * 2) -- eerie beat frequency
        local s3 = (math.random() * 2 - 1) * 0.04
        droneData:setSample(i, (s1 * 0.45 + s2 * 0.45 + s3) * 0.35)
    end
    Assets.sounds.ambient_drone = love.audio.newSource(droneData, "static")
    Assets.sounds.ambient_drone:setLooping(true)
    Assets.sounds.ambient_drone:setVolume(0.4)
    
    -- 6. Ambient Rain Patter (looping)
    local rainLen = math.floor(sampleRate * 2.0)
    local rainData = love.sound.newSoundData(rainLen, sampleRate, 16, 1)
    for i = 0, rainLen - 1 do
        local t = i / sampleRate
        local noise = (math.random() * 2 - 1) * 0.18
        local drip = (math.random() < 0.005) and (math.sin(t * 1800 * math.pi * 2) * 0.4) or 0
        rainData:setSample(i, noise + drip)
    end
    Assets.sounds.ambient_rain = love.audio.newSource(rainData, "static")
    Assets.sounds.ambient_rain:setLooping(true)
    Assets.sounds.ambient_rain:setVolume(0.35)
    
    -- 7. Distant Rolling Thunder
    local thunLen = math.floor(sampleRate * 2.2)
    local thunData = love.sound.newSoundData(thunLen, sampleRate, 16, 1)
    for i = 0, thunLen - 1 do
        local t = i / sampleRate
        local rFreq = 50 + math.sin(t * 12) * 20
        local rum = math.sin(t * rFreq * math.pi * 2) * math.exp(-t * 1.5)
        local n = (math.random() * 2 - 1) * 0.15 * math.exp(-t * 2.0)
        thunData:setSample(i, (rum * 0.8 + n) * 0.7)
    end
    Assets.sounds.thunder = love.audio.newSource(thunData, "static")
end

function Assets.play(soundName, pitchVar, vol)
    if Assets.isMuted then return end
    local src = Assets.sounds[soundName]
    if src then
        if pitchVar then
            src:setPitch(1.0 + (math.random() - 0.5) * pitchVar)
        else
            src:setPitch(1.0)
        end
        if vol then src:setVolume(vol) end
        src:stop()
        src:play()
    end
end

function Assets.startAmbient()
    if Assets.sounds.ambient_drone and not Assets.sounds.ambient_drone:isPlaying() then
        Assets.sounds.ambient_drone:play()
    end
end

function Assets.stopAmbient()
    if Assets.sounds.ambient_drone then
        Assets.sounds.ambient_drone:stop()
    end
end

return Assets
