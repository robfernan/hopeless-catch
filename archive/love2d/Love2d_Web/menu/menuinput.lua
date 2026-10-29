-- menu/menuinput.lua - Menu input handling and navigation
local MenuInput = {}

function MenuInput:init()
    -- Initialize input system
end

function MenuInput:handleInput(key, currentMenu, selectedOption, showResolutionDropdown, selectedResolution, menus)
    return self:handleMenuNavigation(key, currentMenu, selectedOption, menus)
end

function MenuInput:handleMenuNavigation(key, currentMenu, selectedOption, menus)
    if key == "up" then
        return {action = "navigate_up"}
    elseif key == "down" then
        return {action = "navigate_down"}
    elseif key == "return" or key == "space" then
        return {action = "select"}
    elseif key == "escape" then
        return {action = "escape"}
    elseif key == "left" or key == "right" then
        return self:handleHorizontalNavigation(key, currentMenu, selectedOption, menus)
    end
    
    return nil
end

function MenuInput:handleHorizontalNavigation(key, currentMenu, selectedOption, menus)
    if currentMenu ~= "settings" then return nil end
    
    local menu = menus[currentMenu]
    if not menu or not menu.options[selectedOption] then return nil end
    
    local option = menu.options[selectedOption]
    local Settings = require("menu.settings")
    
    if option.action == "toggle_peaceful" then
        Settings:togglePeacefulMode()
    end
    
    return nil
end

return MenuInput
