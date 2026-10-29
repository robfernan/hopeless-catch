-- Hopeless Catch - A Psychological Fishing Horror Game
-- Enhanced Day/Night Metroidvania Fishing Game for Fishing Horror Jam

local GameState = require("gamestate")
local Menu = require("menu.menu")
local DayNightCycle = require("world.daynightcycle")
local FishingSystem = require("fishing.fishing")
-- local HorrorEvents = require("horrorevents")
local Journal = require("ui.journal")
local Player = require("player")
local World = require("world.world")
-- local AudioManager = require("audiomanager")
local Weather = require("world.weather")
local LakeElements = require("world.lakeelements")
local Assets = require("assets")
local VisualTacklebox = require("ui.visualtacklebox")
local CatchDisplay = require("ui.catchdisplay")
-- local FishmanEncounter = require("fishmanencounter")
-- local AtmosphericEffects = require("atmosphericeffects")

-- Screen shake system for visual juice
local screenShake = {
    timer = 0,
    intensity = 0,
    x = 0,
    y = 0
}


-- Cabin mechanic state
local inCabin = false
local cabinFade = 0
local cabinSleepTimer = 0
local cabinUsedTonight = false

-- local fishmanEncountered = false

function love.load()
    -- Initialize game systems
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Hopeless Catch")
    
    -- Game dimensions - fixed resolution for optimal gameplay
    GAME_WIDTH = 800
    GAME_HEIGHT = 600
    love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
        resizable = false, 
        minwidth = GAME_WIDTH, 
        minheight = GAME_HEIGHT,
        fullscreen = false,
        fullscreentype = "desktop"
    })
    
    -- Load settings first
    local Settings = require("menu.settings")
    Settings:load()
    
    -- Initialize all systems
    GameState:init()
    Menu:init()
    DayNightCycle:init()
    FishingSystem:init()
    World:init()  -- Initialize world first to get proper coordinates
    
    -- Get proper ground level for player spawn
    local World = require("world.world")
    local grassY = World:getGrassY()
    local playerHeight = 32
    Player:init(GAME_WIDTH/2, grassY - playerHeight/2)  -- Spawn on grass level
    
    -- AudioManager:init()
    Journal:init()
    -- HorrorEvents:init()
    Weather:init()
    LakeElements:init()
    
    -- Initialize new visual systems
    Assets:createDirectories() -- Create asset folders for user's art
    Assets:load()
    VisualTacklebox:init()
    CatchDisplay:init()
    -- FishmanEncounter:init()
    -- AtmosphericEffects:init()
    
    -- Start in menu
    GameState:setState("menu")
    
    print("🎣 Hopeless Catch loaded! Add your custom art to the assets/ folder.")
    print("📁 Asset directories created - drop your images in to replace placeholders!")
end

-- Handle menu actions from the centralized menu system
function handleMenuAction(action)
    if action == "start_game" then
        GameState:setState("playing")
    elseif action == "quit_game" then
        love.event.quit()
    elseif action == "resume_game" then
        GameState:setState("playing")
    elseif action == "quit_to_menu" then
        GameState:setState("menu")
        Menu:showMainMenu()
    elseif action == "go_back" then
        local currentState = GameState:getState()
        if currentState == "menu" then
            love.event.quit()
        else
            GameState:setState("menu")
            Menu:showMainMenu()
        end
    end
end

function love.update(dt)
    -- Cabin fade logic
    if inCabin then
        if cabinFade < 1 then
            cabinFade = math.min(1, cabinFade + dt * 1.5)
        end
        cabinSleepTimer = cabinSleepTimer + dt
        if cabinSleepTimer > 3 then -- Sleep for 3 seconds
            -- Advance to next day and morning
            local DayNightCycle = require("world.daynightcycle")
            DayNightCycle:advanceToNextDay() -- Advance to next day
            DayNightCycle:setTime(0.3) -- Set to peaceful morning
            print("🌅 You slept through the night. It's a new day (Day " .. DayNightCycle:getCurrentDay() .. ")")
            
            inCabin = false
            cabinFade = 1
            cabinSleepTimer = 0
            cabinUsedTonight = false -- Reset for new day
        end
    else
        if cabinFade > 0 then
            cabinFade = math.max(0, cabinFade - dt * 1.5)
        end
    end
    -- Update screen shake
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
        if screenShake.timer <= 0 then
            screenShake.x, screenShake.y = 0, 0
        else
            screenShake.x = (math.random() - 0.5) * screenShake.intensity
            screenShake.y = (math.random() - 0.5) * screenShake.intensity
        end
    end
    

    
    -- Always update game state and menu system
    GameState:update(dt)
    
    local currentState = GameState:getState()
    
    if currentState == "menu" or currentState == "paused" or currentState == "settings" or currentState == "credits" then
        Menu:update(dt)
        
    elseif currentState == "playing" then
        -- Update visual systems first
        VisualTacklebox:update(dt)
        CatchDisplay:update(dt)
    -- FishmanEncounter:update(dt)
    -- AtmosphericEffects:update(dt, FishingSystem:getHorrorLevel(), DayNightCycle:getCurrentPhase())
        
    -- Fishman encounter removed
        
        -- Check for atmospheric interactions
        local playerX, playerY = Player:getPosition()
    -- local discoveredElement = AtmosphericEffects:checkInteraction(playerX, playerY)
    -- ...existing code...
        
        -- Only update game systems when actually playing
        DayNightCycle:update(dt)
        -- Prevent player movement while tacklebox is open
        if not VisualTacklebox:isOpen() then
            Player:update(dt)
        end
        FishingSystem:update(dt)
        World:update(dt)
    -- AudioManager:update(dt)
    -- HorrorEvents:update(dt)
        Weather:update(dt)
        LakeElements:update(dt)
        
        -- Auto-save periodically or trigger events
        if GameState:getStateTimer() == 1 then -- 1 second after starting
            DayNightCycle:setTime(0.3) -- Start in peaceful morning
            print("🌅 Welcome to Hopeless Catch. The water looks peaceful... for now.")
        end
    end
end

function love.draw()
    local currentState = GameState:getState()
    
    if currentState == "menu" or currentState == "paused" or currentState == "settings" or currentState == "credits" then
        -- Draw menu
        Menu:draw()
        
    elseif currentState == "playing" then
        -- Apply screen shake
        love.graphics.push()
        love.graphics.translate(screenShake.x, screenShake.y)
        

        
        -- Draw game world
        World:drawBackground()
        
        -- Draw lake elements (behind player)
        LakeElements:draw()
        
    -- Apply day/night lighting
    DayNightCycle:beginLighting()
        
        -- Draw game objects
        World:drawWater()
        World:drawForeground()
        Player:draw()
        FishingSystem:draw()
    -- Show catch splash window if active (drawn last for overlay)
        
        -- End lighting effects
        DayNightCycle:endLighting()
        
        -- Draw weather effects on top of everything
        Weather:draw()

    -- Draw atmospheric effects
    -- AtmosphericEffects:draw(DayNightCycle:getCurrentPhase())
    -- Removed extra pop to fix stack depth error
        
        -- Reset transformation for UI (end screen shake)
        love.graphics.pop()
        
        -- Centralized UI drawing
        local UI = require("ui.ui")
        UI.showSurvivalStats = not VisualTacklebox:isOpen()
        UI.showFishingState = not VisualTacklebox:isOpen()
        UI.showControls = true
        UI.showWeather = true
        UI.showTackleBox = VisualTacklebox:isOpen()
        UI.showJournal = false
        
        -- Draw day/night cycle indicator first (behind everything)
        local Journal = require("ui.journal")
        local DayNightCycle = require("world.daynightcycle")
        if not Journal:isOpen() then
            DayNightCycle:drawTimeIndicator()
        end
        
        -- Draw main UI (this includes journal at the end)
        UI:drawAll()

        -- Draw catch display last so it appears in front of everything
        local CatchDisplay = require("ui.catchdisplay")
        CatchDisplay:draw()

        -- Cabin fade overlay
        if cabinFade > 0 then
            love.graphics.setColor(0, 0, 0, cabinFade)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            if inCabin then
                love.graphics.setColor(1, 1, 1, cabinFade)
                love.graphics.printf("🏚️ Resting in the cabin...\n💤 Time passes peacefully...", 0, love.graphics.getHeight()/2 - 40, love.graphics.getWidth(), "center")
            else
                -- Waking up message
                local DayNightCycle = require("world.daynightcycle")
                love.graphics.setColor(1, 1, 1, cabinFade)
                love.graphics.printf("🌅 You wake refreshed!\nDay " .. DayNightCycle:getCurrentDay() .. " begins...", 0, love.graphics.getHeight()/2 - 40, love.graphics.getWidth(), "center")
            end
        end

        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw transitions last
    GameState:drawTransitions()
end

function love.keypressed(key)
    -- Cabin mechanic: Press H to rest and advance to next day
    if key == "h" and not inCabin then
        local DayNightCycle = require("world.daynightcycle")
        print("🏚️ Entering cabin to rest...")
        inCabin = true
        cabinFade = 0
        cabinSleepTimer = 0
        -- Reset daily cabin usage for new day
        cabinUsedTonight = false
    end
    local currentState = GameState:getState()
    -- Global keys
    if key == "escape" then
        if currentState == "playing" then
            GameState:setState("paused")
            Menu:showPauseMenu()
        elseif currentState == "paused" then
            GameState:setState("playing")
        elseif currentState == "settings" or currentState == "credits" or currentState == "menu" then
            local action = Menu:handleEscape()
            if action then
                handleMenuAction(action)
            end
        end
        return
    end
    
    -- Menu navigation
    if currentState == "menu" or currentState == "paused" or currentState == "settings" or currentState == "credits" then
        local action = Menu:keypressed(key)
        if action then
            handleMenuAction(action)
        end
        return
    end
    
    -- Gameplay keys
    if currentState == "playing" then
        -- Catch display handling (dismiss with any key)
        if CatchDisplay:isShowing() then
            CatchDisplay:dismiss()
            return
        end
        
    -- Fishman encounter removed
        
        -- Journal navigation (when journal is open)
        if Journal:isOpen() then
            Journal:keypressed(key)
            return -- Don't process other keys when journal is open
        end
        
        -- Visual Tacklebox navigation (when tacklebox is open)
        if VisualTacklebox:isOpen() then
            if key == "escape" or key == "b" then
                VisualTacklebox:toggle()
            elseif key == "up" then
                VisualTacklebox:navigateUp()
            elseif key == "down" then
                VisualTacklebox:navigateDown(#FishingSystem:getBaitInventory())
            elseif key == "left" then
                VisualTacklebox:navigateLeft()
            elseif key == "right" then
                VisualTacklebox:navigateRight(#FishingSystem:getBaitInventory())
            elseif key == "space" then
                local baitInventory = FishingSystem:getBaitInventory()
                local selectedSlot = VisualTacklebox:getSelectedSlot()
                if baitInventory[selectedSlot] then
                    FishingSystem:selectBait(selectedSlot)
                end
            end
            return -- Don't process other keys when tacklebox is open
        end
        
        if key == "space" then
            local currentState = FishingSystem:getState()
            local isBiting = FishingSystem:isBiting()
            print("DEBUG: Space key pressed")
            print("DEBUG: Current state =", currentState)
            print("DEBUG: Is biting =", isBiting)
            
            if currentState == "bobbing" and isBiting then
                -- If there's a bite, use space to hook the fish
                print("DEBUG: Space pressed during bite, attempting hook set")
                local success = FishingSystem:attemptHookSet()
                print("DEBUG: Hook set result =", success)
                if not success then
                    print("DEBUG: Hook set failed, NOT falling back to casting")
                    -- Don't fall through to casting when hook set fails during bite
                    return
                end
            elseif currentState == "reeling" then
                -- If reeling, use space to reel in fish
                print("DEBUG: Space pressed during reeling")
                FishingSystem:manualReel()
            elseif currentState == "struggling" then
                -- During struggling phase, space makes fish fight harder (like real fishing)
                print("DEBUG: Don't be impatient! Fish will fight harder if you pull during struggling!")
                -- Don't call any functions - let the struggling system handle it in its update loop
            else
                -- Otherwise, use space for casting
                print("DEBUG: Using space for casting/toggling")
                FishingSystem:toggleCasting()
            end
        elseif key == "return" or key == "enter" then
            -- Keep ENTER as backup for hook setting
            local currentState = FishingSystem:getState()
            if currentState == "bobbing" then
                print("DEBUG: Enter pressed, attempting hook set")
                FishingSystem:attemptHookSet()
            end
        elseif key == "b" then
            VisualTacklebox:toggle()
        elseif key == "tab" then
            Journal:toggle()
        elseif key == "t" then
            -- TEST KEY: Force a bite for debugging
            local currentState = FishingSystem:getState()
            if currentState == "bobbing" then
                print("DEBUG: TEST - Forcing a bite")
                FishingSystem:forceBite() -- We'll need to implement this
            end
        
        -- Bait selection (1-8 keys) - only works when tacklebox is open
        elseif key == "1" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(1)
        elseif key == "2" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(2)
        elseif key == "3" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(3)
        elseif key == "4" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(4)
        elseif key == "5" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(5)
        elseif key == "6" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(6)
        elseif key == "7" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(7)
        elseif key == "8" and VisualTacklebox:isOpen() then
            FishingSystem:selectBait(8)
        
        -- Debug keys (remove for final version)
        elseif key == "f1" then
            DayNightCycle:setTimeScale(0.5) -- Slow time
        elseif key == "f2" then
            DayNightCycle:setTimeScale(1.0) -- Normal time
        elseif key == "f3" then
            DayNightCycle:setTimeScale(3.0) -- Fast time
        elseif key == "f4" then
            DayNightCycle:setTimeScale(10.0) -- Very fast time
        elseif key == "n" then
            DayNightCycle:setTime(0.9) -- Force night
        elseif key == "m" then
            DayNightCycle:setTime(0.3) -- Force morning
        elseif key == "q" then -- Test screen shake
            addScreenShake(0.3, 10) -- Test shake
        end
    end
end

function love.mousepressed(x, y, button)
    local currentState = GameState:getState()
    if currentState == "menu" or currentState == "paused" or currentState == "settings" or currentState == "credits" then
        -- If credits, handle Back button at bottom
        if currentState == "credits" then
            local width, height = love.graphics.getWidth(), love.graphics.getHeight()
            local buttonY = height * 0.85
            local buttonX = width/2 - 150
            local buttonWidth = 300
            local buttonHeight = 40
            if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY - 5 and y <= buttonY - 5 + buttonHeight then
                handleMenuAction("go_back")
                return
            end
        else
            -- For other menus, check if mouse is over any option
            local width, height = love.graphics.getWidth(), love.graphics.getHeight()
            local startY = height * 0.45
            local optionHeight = 50
            for i, option in ipairs(menuOptions) do
                local y = startY + (i - 1) * optionHeight + (option.animOffset or 0)
                local buttonX = width/2 - 150
                local buttonWidth = 300
                local buttonHeight = 40
                if x >= buttonX and x <= buttonX + buttonWidth and y >= y - 5 and y <= y - 5 + buttonHeight then
                    selectedOption = i
                    handleMenuAction(option.action)
                    return
                end
            end
        end
    end
end

-- Screen shake function for other systems to use
function addScreenShake(duration, intensity)
    screenShake.timer = duration
    screenShake.intensity = intensity
end

-- Export screen shake function globally
_G.addScreenShake = addScreenShake



function love.keyreleased(key)
    -- Handle key releases
end

-- Ensure menuOptions is always a table
if not menuOptions then menuOptions = {} end
