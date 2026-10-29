-- menu/menurenderer.lua - Menu Rendering System
local MenuRenderer = {}

local Settings = require("menu.settings")

function MenuRenderer:init()
    -- Initialize any rendering resources
end

function MenuRenderer:update(dt)
    -- Update any animations
end

function MenuRenderer:drawMenu(currentMenu, menus, selectedOption, animationTimer, titleGlowTimer, showResolutionDropdown, selectedResolution)
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw dark background overlay (matching your desired aesthetic)
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Get current menu data
    local menu = menus[currentMenu]
    if not menu then return end
    
    -- Draw title
    self:drawTitle(menu.title, menu.subtitle, width, height, titleGlowTimer)
    
    -- Draw menu content based on type
    if currentMenu == "credits" then
        self:drawCredits(menu, width, height, selectedOption)
    elseif currentMenu == "how_to_play" then
        self:drawHowToPlay(menu, width, height, selectedOption)
    elseif currentMenu == "settings" then
        self:drawSettings(menu, width, height, selectedOption, showResolutionDropdown, selectedResolution)
    else
        self:drawStandardMenu(menu, width, height, selectedOption, animationTimer, currentMenu)
    end
end

function MenuRenderer:drawTitle(title, subtitle, width, height, titleGlowTimer)
    -- Title without glow effect
    local titleY = height * 0.25
    
    -- Main title (red like your image)
    love.graphics.setColor(0.9, 0.3, 0.3, 1)
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, width/2 - titleWidth/2, titleY)
    
    -- Subtitle
    if subtitle then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        local subtitleWidth = font:getWidth(subtitle)
        love.graphics.print(subtitle, width/2 - subtitleWidth/2, titleY + 35)
    end
end

function MenuRenderer:drawStandardMenu(menu, width, height, selectedOption, animationTimer, currentMenu)
    local startY = height * 0.45
    local optionHeight = 50
    
    -- Draw menu options
    for i, option in ipairs(menu.options) do
        local y = startY + (i - 1) * optionHeight
        local isSelected = (selectedOption == i)
        
        -- Selection highlight (brown/orange like your image)
        if isSelected then
            love.graphics.setColor(0.6, 0.3, 0.2, 0.8 + math.sin(animationTimer * 4) * 0.15)
            love.graphics.rectangle("fill", width * 0.25, y - 12, width * 0.5, optionHeight - 16, 4)
            
            -- Selection indicators (brackets like your image)
            love.graphics.setColor(0.9, 0.6, 0.3, 1)
            love.graphics.print("▶", width * 0.22, y - 5)
            love.graphics.print("◀", width * 0.78 - 15, y - 5)
        end
        
        -- Option text
        local textColor = isSelected and {1, 0.9, 0.8, 1} or {0.8, 0.8, 0.8, 1}
        love.graphics.setColor(textColor)
        
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(option.text)
        love.graphics.print(option.text, width/2 - textWidth/2, y)
    end
    
    -- Draw navigation hint at bottom
end

function MenuRenderer:drawSettings(menu, width, height, selectedOption, showResolutionDropdown, selectedResolution)
    local startY = height * 0.4
    local optionHeight = 45
    
    for i, option in ipairs(menu.options) do
        local y = startY + (i - 1) * optionHeight
        local isSelected = (selectedOption == i)
        
        -- Selection highlight
        if isSelected then
            love.graphics.setColor(0.6, 0.3, 0.2, 0.7)
            love.graphics.rectangle("fill", width * 0.2, y - 8, width * 0.6, optionHeight - 12, 4)
        end
        
        -- Option text color
        local textColor = isSelected and {1, 0.9, 0.8, 1} or {0.8, 0.8, 0.8, 1}
        love.graphics.setColor(textColor)
        
        local font = love.graphics.getFont()
        local baseText = option.text
        local fullText = baseText
        
        -- Add current values for different option types
        if option.type == "toggle" and option.action == "toggle_peaceful" then
            fullText = baseText .. (Settings:isPeacefulMode() and "On" or "Off")
        end
        
        local textWidth = font:getWidth(fullText)
        love.graphics.print(fullText, width/2 - textWidth/2, y)
    end
end

function MenuRenderer:drawResolutionDropdown(width, y, selectedResolution)
    local Settings = require("menu.settings")
    
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", width * 0.3, y, width * 0.4, #Settings.resolutions * 25, 3)
    
    love.graphics.setColor(0.6, 0.3, 0.2, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", width * 0.3, y, width * 0.4, #Settings.resolutions * 25, 3)
    
    for i, res in ipairs(Settings.resolutions) do
        local optionY = y + (i - 1) * 25
        local isSelected = (selectedResolution == i)
        
        if isSelected then
            love.graphics.setColor(0.6, 0.3, 0.2, 0.8)
            love.graphics.rectangle("fill", width * 0.3, optionY, width * 0.4, 25)
        end
        
        love.graphics.setColor(isSelected and {1, 0.9, 0.8, 1} or {0.8, 0.8, 0.8, 1})
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(res.name)
        love.graphics.print(res.name, width/2 - textWidth/2, optionY + 3)
    end
end

function MenuRenderer:drawCredits(menu, width, height, selectedOption)
    self:drawTextMenu(menu, width, height, selectedOption)
end

function MenuRenderer:drawHowToPlay(menu, width, height, selectedOption)
    self:drawTextMenu(menu, width, height, selectedOption)
end

function MenuRenderer:drawTextMenu(menu, width, height, selectedOption)
    local startY = height * 0.15
    local lineHeight = 40  -- Increased from 30 to 40 for better spacing
    
    -- Draw text content
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    local font = love.graphics.getFont()
    
    for i, line in ipairs(menu.text or {}) do
        local y = startY + (i - 1) * lineHeight
        if y < height - 80 then
            local textWidth = font:getWidth(line)
            love.graphics.print(line, width/2 - textWidth/2, y)
        end
    end
    
    -- Back button
    local backY = height - 70
    local isSelected = (selectedOption == 1)
    
    if isSelected then
        love.graphics.setColor(0.6, 0.3, 0.2, 0.8)
        love.graphics.rectangle("fill", width * 0.4, backY - 8, width * 0.2, 35, 4)
        
        -- Selection indicators
        love.graphics.setColor(0.9, 0.6, 0.3, 1)
        love.graphics.print("▶", width * 0.37, backY - 2)
        love.graphics.print("◀", width * 0.63 - 10, backY - 2)
    end
    
    love.graphics.setColor(isSelected and {1, 0.9, 0.8, 1} or {0.8, 0.8, 0.8, 1})
    local backText = "Back"
    local textWidth = font:getWidth(backText)
    love.graphics.print(backText, width/2 - textWidth/2, backY)
end

function MenuRenderer:drawNavigationHint(width, height)
    local hintY = height - 40
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    local font = love.graphics.getFont()
    local hint = "Use ↑↓ arrows to navigate, ENTER to select, ESC to go back"
    local hintWidth = font:getWidth(hint)
    love.graphics.print(hint, width/2 - hintWidth/2, hintY)
end

return MenuRenderer
