-- menu/menudata.lua - Menu definitions and data structures
local MenuData = {}

MenuData.menus = {
    main = {
        title = "Hopeless Catch",
        subtitle = "A Psychological Fishing Horror",
        options = {
            {text = "Start Game", action = "start_game"},
            {text = "How to Play", action = "show_controls"},
            {text = "Settings", action = "open_settings"},
            {text = "Credits", action = "open_credits"},
            {text = "Quit", action = "quit_game"}
        },
        controls = {
            "Controls:",
            "WASD/Arrows: Move",
            "SPACE: Cast/Reel",
            "B: Tacklebox",
            "TAB: Journal",
            "ESC: Pause/Back",
            "H: Cabin (at night)",
            "Mouse: Menu navigation"
        }
    },
    
    pause = {
        title = "Game Paused",
        subtitle = "The water waits...",
        options = {
            {text = "Resume", action = "resume_game"},
            {text = "How to Play", action = "show_controls"},
            {text = "Settings", action = "open_settings"},
            {text = "Save & Quit", action = "quit_to_menu"}
        },
        controls = {
            "Controls:",
            "WASD/Arrows: Move",
            "SPACE: Cast/Reel",
            "B: Tacklebox",
            "TAB: Journal",
            "ESC: Resume",
            "H: Cabin (at night)"
        }
    },
    
    settings = {
        title = "Settings",
        subtitle = "Customize your experience",
        options = {
            {text = "Peaceful Mode: ", action = "toggle_peaceful", type = "toggle"},
            {text = "Back", action = "back_to_menu"}
        }
    },
    
    credits = {
        title = "Credits",
        text = {
            "",
            "",
            "",
            "Game Development & Design",
            "Programming in Love2D & Art in Aseprite",
            "Created by MungDaal321 with help of Copilot",
            "Thanks for playing!"
        },
        options = {
            {text = "Back", action = "back_to_menu"}
        }
    },
    
    how_to_play = {
        title = "How to Play",
        subtitle = "Quick Start Guide",
        text = {
            "",
            "",
            "",
            "Controls:",
            "WASD / Arrow Keys - Move",
            "SPACE - Cast line / Reel fish", 
            "Need to Press B to Open Tacklebox",
            "ESC - Pause / Menu",
            "Before you cast you need bait, To cast, simply press SPACE twice—once"
        },
        options = {
            {text = "Back", action = "back_to_menu"}
        }
    }
}

-- Resolution options (now references Settings module)
MenuData.resolutions = {} -- Will be loaded from Settings module

-- Default settings values
MenuData.defaultSettings = {
    resolution = 1,
    fullscreen = false,
    soundVolume = 80,
    musicVolume = 70,
    autoSave = true
}

function MenuData:init()
    -- Initialize menu data
    local Settings = require("menu.settings")
    -- Copy resolutions from Settings module
    self.resolutions = Settings.resolutions
end

function MenuData:getMenus()
    return self.menus
end

function MenuData:getMenu(menuName)
    return self.menus[menuName]
end

return MenuData
