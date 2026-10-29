-- menu/menu.lua - Centralized Menu System Controller
local Menu = {}

-- Import all menu modules
local MenuData = require("menu.menudata")
local MenuRenderer = require("menu.menurenderer")
local MenuInput = require("menu.menuinput")
local MenuController = require("menu.menucontroller")
local Settings = require("menu.settings")
local HowToPlay = require("menu.howtoplay")

-- Current menu state
local currentMenu = "main"
local selectedOption = 1
local animationTimer = 0
local titleGlowTimer = 0

-- State variables
local showResolutionDropdown = false
local selectedResolution = 1

function Menu:init()
    -- Initialize all subsystems
    MenuData:init()
    MenuRenderer:init()
    MenuInput:init()
    MenuController:init()
    Settings:load()
    
    -- Set initial state
    currentMenu = "main"
    selectedOption = 1
    animationTimer = 0
    titleGlowTimer = 0
    showResolutionDropdown = false
    
    -- Load current resolution setting
    local currentWidth, currentHeight = love.graphics.getDimensions()
    for i, res in ipairs(Settings.resolutions) do
        if res.width == currentWidth and res.height == currentHeight then
            selectedResolution = i
            break
        end
    end
end

function Menu:update(dt)
    animationTimer = animationTimer + dt
    titleGlowTimer = titleGlowTimer + dt * 2
    MenuRenderer:update(dt)
end

function Menu:draw()
    MenuRenderer:drawMenu(
        currentMenu, 
        MenuData:getMenus(), 
        selectedOption, 
        animationTimer, 
        titleGlowTimer, 
        showResolutionDropdown, 
        selectedResolution
    )
end

function Menu:keypressed(key)
    local result = MenuInput:handleInput(
        key, 
        currentMenu, 
        selectedOption, 
        showResolutionDropdown, 
        selectedResolution,
        MenuData:getMenus()
    )
    
    if result then
        if result.action == "navigate_up" then
            selectedOption = MenuController:navigateUp(selectedOption, MenuData:getMenu(currentMenu))
        elseif result.action == "navigate_down" then
            selectedOption = MenuController:navigateDown(selectedOption, MenuData:getMenu(currentMenu))
        elseif result.action == "select" then
            local menuAction = MenuController:selectOption(selectedOption, MenuData:getMenu(currentMenu))
            return self:handleMenuAction(menuAction)
        elseif result.action == "escape" then
            return self:handleEscape()
        elseif result.action == "resolution_change" then
            selectedResolution = result.value
        elseif result.action == "resolution_apply" then
            local res = Settings.resolutions[selectedResolution]
            Settings:setResolution(res.width, res.height)
            love.window.setMode(res.width, res.height, {fullscreen = Settings:getFullscreen()})
            showResolutionDropdown = false
        elseif result.action == "resolution_close" then
            showResolutionDropdown = false
        elseif result.action == "toggle_dropdown" then
            showResolutionDropdown = true
        end
    end
    
    return nil
end

function Menu:handleMenuAction(action)
    if action == "open_settings" then
        currentMenu = "settings"
        selectedOption = 1
    elseif action == "open_credits" then
        currentMenu = "credits"
        selectedOption = 1
    elseif action == "show_controls" then
        currentMenu = "how_to_play"
        selectedOption = 1
    elseif action == "back_to_menu" then
        local GameState = require("gamestate")
        if GameState:getState() == "menu" then
            currentMenu = "main"
        else
            currentMenu = "pause"
        end
        selectedOption = 1
    else
        return action -- Pass through to game (start_game, quit_game, etc.)
    end
    return nil
end

function Menu:handleEscape()
    if currentMenu == "main" then
        return "quit_game"
    elseif currentMenu == "pause" then
        return "resume_game"
    elseif currentMenu == "settings" or currentMenu == "credits" or currentMenu == "how_to_play" then
        return self:handleMenuAction("back_to_menu")
    end
    return nil
end

function Menu:showPauseMenu()
    currentMenu = "pause"
    selectedOption = 1
end

function Menu:showMainMenu()
    currentMenu = "main"
    selectedOption = 1
end

return Menu
            {text = "Music Volume: ", action = "adjust_music", type = "slider"},
            {text = "Auto-Save: ", action = "toggle_autosave", type = "toggle"},
            {text = "Back", action = "back_to_menu"}
        }
    },
    
    credits = {
        title = "Credits",
        subtitle = "Made with Love2D",
        text = {
            "Hopeless Catch",
            "",
            "A Psychological Fishing Horror Game",
            "Created for the Fishing Horror Jam",
            "",
            "Game Design & Programming:",
            "- Enhanced fishing mechanics",
            "- Day/night cycle system", 
            "- Weather effects",
            "- Modular architecture",
            "",
            "Art & Assets:",
            "- Custom placeholder graphics",
            "- User-replaceable asset system",
            "",
            "Built with Love2D",
            "Lua game development framework",
            "",
            "Special Thanks:",
            "- Love2D community",
            "- Fishing Horror Jam organizers",
            "",
            "Press ESC to return"
        },
        options = {
            {text = "Back", action = "back_to_menu"}
        }
    },
    
    how_to_play = {
        title = "How to Play",
        subtitle = "Quick Start Guide",
        text = {
            "Welcome to Hopeless Catch!",
            "",
            "Basic Controls:",
            "WASD / Arrow Keys - Move around the lake",
            "SPACE - Cast your line / Reel in fish", 
            "B - Open Tacklebox (select bait)",
            "TAB - Open Journal (track catches)",
            "ESC - Pause game / Back to menu",
            "H - Enter Cabin (available at night)",
            "",
            "Fishing Tips:",
            "- Different bait attracts different fish",
            "- Fish are more active at certain times",
            "- Weather affects fishing success",
            "- Explore different areas of the lake",
            "",
            "The day/night cycle changes the atmosphere",
            "and types of fish you can catch.",
            "",
            "Good luck, and enjoy your fishing adventure!"
        },
        options = {
            {text = "Back", action = "back_to_menu"}
        }
    }
}

function MenuSystem:init()
    selectedOption = 1
    currentMenu = "main"
    animationTimer = 0
    titleGlowTimer = 0
    showResolutionDropdown = false
    
    -- Load current resolution setting
    local currentWidth, currentHeight = love.graphics.getDimensions()
    
    -- Find matching resolution in list
    for i, res in ipairs(MenuSettings.resolutions) do
        if res.width == currentWidth and res.height == currentHeight then
            selectedResolution = i
            break
        end
    end
    
    self:updateMenuOptions()
end

function MenuSystem:update(dt)
    animationTimer = animationTimer + dt
    titleGlowTimer = titleGlowTimer + dt * 2
end

function MenuSystem:updateMenuOptions()
    local menu = menus[currentMenu]
    if menu then
        menuOptions = menu.options
        print("Menu options updated for:", currentMenu, "Options count:", #menuOptions)
        for i, option in ipairs(menuOptions) do
            print(i, option.text)
        end
    else
        print("No menu found for:", currentMenu)
    end
end

function MenuSystem:navigateUp()
    print("Navigate UP - Before: selectedOption =", selectedOption, "menuOptions count =", #menuOptions)
    selectedOption = selectedOption - 1
    if selectedOption < 1 then
        selectedOption = #menuOptions
    end
    print("Navigate UP - After: selectedOption =", selectedOption)
end

function MenuSystem:navigateDown()
    print("Navigate DOWN - Before: selectedOption =", selectedOption, "menuOptions count =", #menuOptions)
    selectedOption = selectedOption + 1
    if selectedOption > #menuOptions then
        selectedOption = 1
    end
    print("Navigate DOWN - After: selectedOption =", selectedOption)
end

function MenuSystem:selectOption()
    if selectedOption > 0 and selectedOption <= #menuOptions then
        local option = menuOptions[selectedOption]
        return option.action
    end
    return nil
end

function MenuSystem:draw()
    -- Use MenuSettings for complex rendering
    MenuSettings:drawMenu(currentMenu, menus, selectedOption, animationTimer, titleGlowTimer, showResolutionDropdown, selectedResolution)
end

function MenuSystem:keypressed(key)
    if currentMenu == "settings" and showResolutionDropdown then
        -- Handle resolution dropdown
        if key == "up" then
            selectedResolution = math.max(1, selectedResolution - 1)
        elseif key == "down" then
            selectedResolution = math.min(#MenuSettings.resolutions, selectedResolution + 1)
        elseif key == "return" or key == "space" then
            local res = MenuSettings.resolutions[selectedResolution]
            MenuSettings:setResolution(res.width, res.height)
            love.window.setMode(res.width, res.height, {fullscreen = MenuSettings:getFullscreen()})
            showResolutionDropdown = false
        elseif key == "escape" then
            showResolutionDropdown = false
        end
        return nil
    end
    
    -- Normal menu navigation
    if key == "up" then
        self:navigateUp()
    elseif key == "down" then
        self:navigateDown()
    elseif key == "return" or key == "space" then
        local action = self:selectOption()
        return self:handleAction(action)
    elseif key == "escape" then
        return self:handleEscape()
    elseif key == "left" or key == "right" then
        return self:handleHorizontalNavigation(key)
    end
    
    return nil
end

function MenuSystem:handleAction(action)
    if action == "open_settings" then
        currentMenu = "settings"
        selectedOption = 1
        self:updateMenuOptions()
    elseif action == "open_credits" then
        currentMenu = "credits"  
        selectedOption = 1
        self:updateMenuOptions()
    elseif action == "show_controls" then
        currentMenu = "how_to_play"
        selectedOption = 1
        self:updateMenuOptions()
    elseif action == "go_back" then
        return self:handleAction("back_to_menu")
    elseif action == "back_to_menu" then
        local GameState = require("gamestate")
        if GameState:getState() == "menu" then
            currentMenu = "main"
        else
            currentMenu = "pause"
        end
        selectedOption = 1
        self:updateMenuOptions()
    elseif action == "toggle_resolution" then
        showResolutionDropdown = true
    else
        return action
    end
    return nil
end

function MenuSystem:handleEscape()
    if currentMenu == "main" then
        return "quit_game"
    elseif currentMenu == "pause" then
        return "resume_game"
    elseif currentMenu == "settings" or currentMenu == "credits" or currentMenu == "how_to_play" then
        return self:handleAction("back_to_menu")
    end
    return nil
end

function MenuSystem:handleHorizontalNavigation(key)
    if currentMenu ~= "settings" then return nil end
    
    local option = menuOptions[selectedOption]
    if not option then return nil end
    
    if option.action == "toggle_fullscreen" then
        MenuSettings:setFullscreen(not MenuSettings:getFullscreen())
        love.window.setFullscreen(MenuSettings:getFullscreen())
    elseif option.action == "toggle_autosave" then
        MenuSettings:setAutoSave(not MenuSettings:getAutoSave())
    elseif option.action == "adjust_volume" then
        local currentVolume = MenuSettings:getSoundVolume()
        local newVolume = key == "right" and math.min(100, currentVolume + 5) or math.max(0, currentVolume - 5)
        MenuSettings:setSoundVolume(newVolume)
    elseif option.action == "adjust_music" then
        local currentVolume = MenuSettings:getMusicVolume()
        local newVolume = key == "right" and math.min(100, currentVolume + 5) or math.max(0, currentVolume - 5)
        MenuSettings:setMusicVolume(newVolume)
    elseif option.action == "toggle_resolution" then
        showResolutionDropdown = true
    end
    
    return nil
end

function MenuSystem:showPauseMenu()
    currentMenu = "pause"
    selectedOption = 1
    self:updateMenuOptions()
end

function MenuSystem:showMainMenu()
    currentMenu = "main"
    selectedOption = 1
    self:updateMenuOptions()
end

function MenuSystem:loadMenu(menuName)
    if menuName == "pause" then
        self:showPauseMenu()
    else
        currentMenu = menuName
        selectedOption = 1
        self:updateMenuOptions()
    end
end

return MenuSystem
