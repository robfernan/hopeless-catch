-- Hopeless Catch - A Psychological Fishing Horror Game
-- Professional Love2D + OpenGL + Dear ImGui implementation

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    local lldebugger = require("lldebugger")
    lldebugger.start()
    local run = love.run
    function love.run(...)
        local f = lldebugger.call(run, false, ...)
        return function(...)
            return lldebugger.call(f, false, ...)
        end
    end
end

-- Ensure cimgui.dll in the game source directory is discoverable by package.cpath
local sourceDir = love.filesystem.getSource()
if sourceDir then
    local ext = jit.os == "Windows" and "dll" or jit.os == "Linux" and "so" or "dylib"
    package.cpath = package.cpath .. ";" .. sourceDir .. "/?." .. ext .. ";" .. sourceDir .. "/cimgui/?." .. ext
end

local GameState = require("gamestate")
local DayNightCycle = require("world.daynightcycle")
local FishingSystem = require("fishing.fishing")
local Journal = require("ui.journal")
local Player = require("player")
local World = require("world.world")
local Weather = require("world.weather")
local LakeElements = require("world.lakeelements")
local Assets = require("assets")

-- ImGui UI system
local GUI = require("ui.imgui.init")
local MainMenu = require("ui.imgui.mainmenu")
local HUD = require("ui.imgui.hud")
local TackleBoxUI = require("ui.imgui.tacklebox")
local JournalUI = require("ui.imgui.journal")
local CatchDisplayUI = require("ui.imgui/catchdisplay")
local PauseMenu = require("ui.imgui/pausemenu")

-- Screen shake system
local screenShake = { timer = 0, intensity = 0, x = 0, y = 0 }

-- Lurker live hot-reloading library
local lurker = require("lurker")
lurker.interval = 0.5
lurker.preswap = function(f)
    -- Don't hot-reload main.lua, conf.lua, or cimgui internals
    if f:find("main%.lua") or f:find("conf%.lua") or f:find("cimgui") then
        return true -- abort swap for these
    end
end

-- Polyfill for love.keyboard.justPressed(...) across all UI and input modules
local _prevKeysDown = {}
local _justPressedKeys = {}

function love.keyboard.justPressed(...)
    local keys = {...}
    for _, k in ipairs(keys) do
        if _justPressedKeys[k] then
            return true
        end
    end
    return false
end

-- Cabin mechanic state
local inCabin = false
local cabinFade = 0
local cabinSleepTimer = 0

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Hopeless Catch")
    
    local GAME_WIDTH, GAME_HEIGHT = 800, 600
    love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
        resizable = false,
        minwidth = GAME_WIDTH,
        minheight = GAME_HEIGHT,
        fullscreen = false,
        fullscreentype = "desktop"
    })
    
    -- Load settings
    local Settings = require("menu.settings")
    Settings:load()
    
    -- Initialize all game systems
    GameState:init()
    DayNightCycle:init()
    FishingSystem:init()
    World:init()
    
    local grassY = World:getGrassY()
    Player:init(GAME_WIDTH / 2, grassY - 16)
    
    Journal:init()
    
    -- Load save data
    local SaveSystem = require("savesystem")
    SaveSystem:load()
    
    -- Horror events
    local HorrorEvents = require("world.horrorevents")
    HorrorEvents:init()
    
    Weather:init()
    LakeElements:init()
    
    -- Assets
    Assets:createDirectories()
    Assets:load()
    Assets:startAmbientAudio()
    
    -- Initialize ImGui (must be after love.window.setMode)
    GUI:init()
    
    -- Start in menu state
    GameState:setState("menu")
    
    print("🎣 Hopeless Catch loaded! [ImGui + OpenGL]")
end

function love.quit()
    GUI:shutdown()
    Assets:stopAmbientAudio()
end

-- ============================================================
-- MENU ACTIONS
-- ============================================================
local function handleMenuAction(action)
    if action == "start_game" then
        GameState:setState("playing")
    elseif action == "quit" or action == "quit_game" then
        love.event.quit()
    elseif action == "resume" or action == "resume_game" then
        GameState:setState("playing")
    elseif action == "quit_to_menu" then
        GameState:setState("menu")
    elseif action == "settings" then
        -- Settings handled inline in menu for now
    elseif action == "credits" then
        -- Credits shown as a simple overlay (could expand)
    elseif action == "how_to_play" or action == "show_controls" then
        -- How to play shown as overlay
    end
end

-- ============================================================
-- UPDATE
-- ============================================================
function love.update(dt)
    -- Lurker automatic file watching & live code hotswap
    lurker.update()

    -- Global F5 full restart fallback
    if love.keyboard.isDown("f5") then
        print("🔄 Live Restarting Hopeless Catch...")
        love.event.quit("restart")
        return
    end

    -- Update justPressed state
    for k in pairs(_justPressedKeys) do
        _justPressedKeys[k] = nil
    end

    -- ImGui input update (process mouse/keyboard for UI)
    GUI:update(dt)
    
    -- Cabin fade logic
    if inCabin then
        cabinFade = math.min(1, cabinFade + dt * 1.5)
        cabinSleepTimer = cabinSleepTimer + dt
        if cabinSleepTimer > 3 then
            DayNightCycle:advanceToNextDay()
            DayNightCycle:setTime(0.3)
            inCabin = false
            cabinFade = 1
            cabinSleepTimer = 0
        end
    else
        cabinFade = math.max(0, cabinFade - dt * 1.5)
    end
    
    -- Screen shake
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
        if screenShake.timer <= 0 then
            screenShake.x, screenShake.y = 0, 0
        else
            screenShake.x = (math.random() - 0.5) * screenShake.intensity
            screenShake.y = (math.random() - 0.5) * screenShake.intensity
        end
    end
    
    GameState:update(dt)
    
    local state = GameState:getState()
    
    if state == "menu" then
        MainMenu:update(dt)
        DayNightCycle:update(dt * 0.25)
        Weather:update(dt)
        LakeElements:update(dt)
        
    elseif state == "playing" then
        -- Update UI systems
        CatchDisplayUI:update(dt)
        
        -- Game world updates (only when not in overlay UIs)
        local uiBlocking = TackleBoxUI:isOpen_() or JournalUI:isOpen_() or CatchDisplayUI:isShowing()
        
        if not uiBlocking then
            DayNightCycle:update(dt)
            Player:update(dt)
            FishingSystem:update(dt)
            Weather:update(dt)
            
            local HorrorEvents = require("world.horrorevents")
            HorrorEvents:update(dt, DayNightCycle)
            HorrorEvents:checkFishmanEncounter(DayNightCycle)
        end
        
        LakeElements:update(dt)
        
        -- Welcome message on first second of play
        if GameState:getStateTimer() < 1 and GameState:getStateTimer() > 0 then
            -- (one-time, handled by state timer)
        end
    end
end

-- ============================================================
-- DRAW
-- ============================================================
function love.draw()
    local state = GameState:getState()
    
    if state == "menu" then
        -- Draw living game world background behind the menu
        love.graphics.push()
        World:drawBackground()
        LakeElements:draw()
        DayNightCycle:beginLighting()
        World:drawWater()
        World:drawForeground()
        DayNightCycle:endLighting()
        Weather:draw()
        love.graphics.pop()
        
        -- Dark atmospheric vignette over the world so menu text pop and look cinematic
        local w, h = love.graphics.getDimensions()
        love.graphics.setColor(0.02, 0.03, 0.06, 0.55)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Subtle gradient darkness at the top for title readability
        love.graphics.setColor(0, 0, 0, 0.35)
        love.graphics.rectangle("fill", 0, 0, w, h * 0.45)
    elseif state == "playing" then
        -- Apply screen shake to world rendering
        love.graphics.push()
        love.graphics.translate(screenShake.x, screenShake.y)
        
        -- World background (sky, terrain, vegetation)
        World:drawBackground()
        
        -- Lake elements behind player
        LakeElements:draw()
        
        -- Day/night lighting pass
        DayNightCycle:beginLighting()
        
        -- Water + foreground structures + player + fishing
        World:drawWater()
        World:drawForeground()
        Player:draw()
        FishingSystem:draw()
        
        DayNightCycle:endLighting()
        
        -- Weather effects (rain, fog, lightning)
        Weather:draw()
        
        -- Horror event overlays
        local HorrorEvents = require("world.horrorevents")
        HorrorEvents:drawSkyAnomaly()
        HorrorEvents:drawAnomaly()
        HorrorEvents:drawFishmanEncounter()
        
        love.graphics.pop()
        
        -- Cabin fade overlay
        if cabinFade > 0 then
            love.graphics.setColor(0, 0, 0, cabinFade)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            if inCabin then
                local font = love.graphics.newFont(18)
                love.graphics.setFont(font)
                love.graphics.setColor(0.9, 0.85, 0.75, cabinFade)
                love.graphics.printf("Resting in the cabin...\nTime passes peacefully...", 
                    0, love.graphics.getHeight()/2 - 30, love.graphics.getWidth(), "center")
            end
        end
        
    elseif state == "paused" then
        -- Draw frozen game world as background
        love.graphics.push()
        World:drawBackground()
        LakeElements:draw()
        DayNightCycle:beginLighting()
        World:drawWater()
        World:drawForeground()
        Player:draw()
        FishingSystem:draw()
        DayNightCycle:endLighting()
        Weather:draw()
        love.graphics.pop()
    end
    
    -- ============================================================
    -- IMGUI LAYER (rendered on top of everything)
    -- ============================================================
    
    if state == "menu" then
        local action = MainMenu:draw()
        if action then
            handleMenuAction(action)
        end
        
    elseif state == "playing" then
        -- HUD (always visible during play, unless overlay is open)
        local anyOverlayOpen = TackleBoxUI:isOpen_() or JournalUI:isOpen_() or CatchDisplayUI:isShowing()
        
        if not anyOverlayOpen then
            HUD:draw()
        end
        
        -- Tackle box overlay
        if TackleBoxUI:isOpen_() then
            local baitInventory = FishingSystem:getBaitInventory()
            local selectedBait = TackleBoxUI:draw(baitInventory)
            if selectedBait then
                FishingSystem:selectBait(1) -- select the chosen one (index handled by tacklebox)
            end
        end
        
        -- Journal overlay
        if JournalUI:isOpen_() then
            local day = DayNightCycle:getCurrentDay() or 1
            -- Get entries from the legacy journal module
            local allEntries = {}
            local secrets = {}
            -- (Journal data is in the ui.journal module)
            JournalUI:draw(day, allEntries, secrets)
        end
        
        -- Catch display (topmost overlay)
        if CatchDisplayUI:isShowing() then
            CatchDisplayUI:draw()
        end
        
    elseif state == "paused" then
        local action = PauseMenu:draw()
        if action then
            handleMenuAction(action)
        end
    end
    
    -- Render all ImGui draw lists (must be last)
    GUI:render()
    
    -- Transitions
    GameState:drawTransitions()
end

-- ============================================================
-- INPUT
-- ============================================================
function love.keypressed(key)
    _justPressedKeys[key] = true
    local imgui = require("cimgui")
    imgui.love.KeyPressed(key)
    local state = GameState:getState()
    
    -- Cabin rest key
    if key == "h" and state == "playing" and not inCabin then
        inCabin = true
        cabinFade = 0
        cabinSleepTimer = 0
        return
    end

    -- F5 Quick Hot-Reload (live iteration)
    if key == "f5" then
        print("🔄 Live Reloading Hopeless Catch...")
        love.event.quit("restart")
        return
    end
    
    -- ESC handling (global)
    if key == "escape" then
        if state == "playing" then
            GameState:setState("paused")
        elseif state == "paused" then
            GameState:setState("playing")
        elseif state == "menu" then
            love.event.quit()
        end
        return
    end
    
    -- Menu navigation (ImGui handles most of this, but we need keyboard fallback)
    if state == "menu" or state == "paused" then
        -- ImGui buttons handle clicks; keyboard nav is handled in the draw functions
        -- via love.keyboard.justPressed checks. Nothing extra needed here.
        return
    end
    
    -- Gameplay keys (only when no overlay UI is active)
    if state == "playing" then
        local CatchDisplay = CatchDisplayUI
        
        -- Dismiss catch display with any key
        if CatchDisplay:isShowing() and CatchDisplay.phase == "showing" then
            CatchDisplay.phase = "disappearing"
            CatchDisplay.timer = 0
            return
        end
        
        -- Journal (TAB)
        if key == "tab" then
            JournalUI:toggle()
            return
        end
        
        -- Tackle box (B)
        if key == "b" then
            TackleBoxUI:toggle()
            return
        end
        
        -- If an overlay is open, let it handle input
        if TackleBoxUI:isOpen_() or JournalUI:isOpen_() then
            return
        end
        
        -- Fishing controls (SPACE)
        if key == "space" then
            local fState = FishingSystem:getState()
            local isBiting = FishingSystem:isBiting()
            
            if fState == "bobbing" and isBiting then
                FishingSystem:attemptHookSet()
            elseif fState == "reeling" then
                FishingSystem:manualReel()
            else
                FishingSystem:toggleCasting()
            end
        elseif key == "return" or key == "enter" then
            if FishingSystem:getState() == "bobbing" then
                FishingSystem:attemptHookSet()
            end
        
        -- Debug keys
        elseif key == "f1" then DayNightCycle:setTimeScale(0.5)
        elseif key == "f2" then DayNightCycle:setTimeScale(1.0)
        elseif key == "f3" then DayNightCycle:setTimeScale(3.0)
        elseif key == "f4" then DayNightCycle:setTimeScale(10.0)
        elseif key == "n"  then DayNightCycle:setTime(0.9)
        elseif key == "m"  then DayNightCycle:setTime(0.3)
        elseif key == "t"  then
            if FishingSystem:getState() == "bobbing" then
                FishingSystem:forceBite()
            end
        elseif key == "q"  then addScreenShake(0.3, 10)
        end
    end
end

function love.keyreleased(key)
    local imgui = require("cimgui")
    imgui.love.KeyReleased(key)
end

function love.mousemoved(x, y, dx, dy, istouch)
    local imgui = require("cimgui")
    imgui.love.MouseMoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
    local imgui = require("cimgui")
    imgui.love.MousePressed(button)
end

function love.mousereleased(x, y, button, istouch, presses)
    local imgui = require("cimgui")
    imgui.love.MouseReleased(button)
end

function love.wheelmoved(x, y)
    local imgui = require("cimgui")
    imgui.love.WheelMoved(x, y)
end

function love.textinput(text)
    local imgui = require("cimgui")
    imgui.love.TextInput(text)
end

-- ============================================================
-- GLOBAL HELPERS
-- ============================================================
function addScreenShake(duration, intensity)
    screenShake.timer = duration
    screenShake.intensity = intensity
end
_G.addScreenShake = addScreenShake
