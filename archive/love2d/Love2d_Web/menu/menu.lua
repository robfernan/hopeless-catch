-- menu/menu.lua - Centralized Menu System Controller
local Menu = {}

-- Import all menu modules
local MenuData = require("menu.menudata")
local MenuRenderer = require("menu.menurenderer")
local MenuInput = require("menu.menuinput")
local MenuController = require("menu.menucontroller")
local Settings = require("menu.settings")

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
    selectedResolution = Settings:getCurrentResolutionIndex()
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
            if menuAction == "toggle_peaceful" then
                Settings:togglePeacefulMode()
            else
                return self:handleMenuAction(menuAction)
            end
        elseif result.action == "escape" then
            return self:handleEscape()
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
