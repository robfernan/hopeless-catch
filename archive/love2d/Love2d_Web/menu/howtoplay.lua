-- menu/howtoplay.lua - How to Play menu content
local HowToPlay = {}

HowToPlay.content = {
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
    }
}

function HowToPlay:getContent()
    return self.content
end

return HowToPlay
