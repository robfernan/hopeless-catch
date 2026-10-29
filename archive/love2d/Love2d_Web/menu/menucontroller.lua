-- menu/menucontroller.lua - Menu navigation controller
local MenuController = {}

function MenuController:init()
    -- Initialize controller
end

function MenuController:navigateUp(selectedOption, menu)
    local newOption = selectedOption - 1
    if newOption < 1 then
        newOption = #menu.options
    end
    return newOption
end

function MenuController:navigateDown(selectedOption, menu)
    local newOption = selectedOption + 1
    if newOption > #menu.options then
        newOption = 1
    end
    return newOption
end

function MenuController:selectOption(selectedOption, menu)
    if menu and menu.options[selectedOption] then
        return menu.options[selectedOption].action
    end
    return nil
end

return MenuController
