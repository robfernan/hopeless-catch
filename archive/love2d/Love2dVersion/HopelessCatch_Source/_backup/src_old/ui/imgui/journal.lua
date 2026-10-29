-- ui/imgui/journal.lua - Journal UI with Dear ImGui
local imgui = require("cimgui")

local JournalUI = {}
JournalUI.isOpen = false
JournalUI.currentDay = 1
JournalUI.scrollOffset = 0

function JournalUI:toggle()
    self.isOpen = not self.isOpen
end

function JournalUI:isOpen_()
    return self.isOpen
end

--- Draw the journal overlay. Returns true if it was closed this frame.
-- @param day number current day to show
-- @param entries table array of entry tables {name, time, data}
-- @param secrets table array of secret entries for this day
function JournalUI:draw(day, entries, secrets)
    if not self.isOpen then return false end
    
    local w, h = love.graphics.getDimensions()
    
    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Panel size
    local panelW = math.min(560, w * 0.8)
    local panelH = math.min(420, h * 0.75)
    local px = (w - panelW) / 2
    local py = (h - panelH) / 2
    
    imgui.SetNextWindowPos(px, py)
    imgui.SetNextWindowSize(panelW, panelH)
    
    local flags = imgui.WindowFlags_NoResize + imgui.WindowFlags_NoMove 
                + imgui.WindowFlags_NoSavedSettings
    
    if not imgui.Begin("Journal##HopelessCatch", nil, flags) then
        return false
    end
    
    -- Title with horror styling
    imgui.PushStyleColor(imgui.Col_Text, {0.85, 0.75, 0.6, 1})
    local titleFont = love.graphics.newFont(26)
    imgui.Text("FIELD JOURNAL")
    imgui.PopStyleColor()
    
    -- Day selector
    imgui.Spacing()
    imgui.PushID("daynav")
    
    local leftClicked = false
    if imgui.ArrowButton("##prevDay", imgui.Dir_Left, 28, 28) then
        self.currentDay = math.max(1, day - 1)
        leftClicked = true
    end
    
    imgui.SameLine()
    imgui.PushStyleColor(imgui.Col_Text, {0.7, 0.65, 0.55, 1})
    imgui.Text("Day %d", self.currentDay)
    imgui.PopStyleColor()
    
    imgui.SameLine()
    if imgui.ArrowButton("##nextDay", imgui.Dir_Right, 28, 28) then
        self.currentDay = day + 1
    end
    
    imgui.PopID()
    
    imgui.Separator()
    imgui.Spacing()
    
    -- Scrollable entry list
    local listHeight = panelH - 140
    if imgui.BeginChild("##entryList", 0, listHeight) then
        
        if not entries or #entries == 0 then
            imgui.PushStyleColor(imgui.Col_Text, {0.5, 0.35, 0.3, 0.9})
            imgui.Text("No fish caught on this day.")
            imgui.PopStyleColor()
            
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col_Text, {0.4, 0.38, 0.35, 0.7})
            imgui.Text("The lake keeps its secrets...")
            imgui.PopStyleColor()
        else
            for i, entry in ipairs(entries) do
                local isSecret = entry.data and entry.data.secret == true
                
                if isSecret then
                    -- Secret entries: dark purple-red styling with ✦ marker
                    imgui.PushStyleColor(imgui.Col_Text, {0.65, 0.3, 0.45, 1})
                    
                    local text = "✦   " .. (entry.name or "?")
                    if entry.data.source == "fish_catch" and entry.data.fish then
                        text = text .. "   (" .. entry.data.fish .. ")"
                    end
                    imgui.Text(text)
                    imgui.PopStyleColor()
                    
                else
                    -- Normal catch entries
                    imgui.PushStyleColor(imgui.Col_Text, {0.75, 0.72, 0.65, 1})
                    
                    local timeStr = entry.time and ("   @ " .. entry.time) or ""
                    imgui.Text("•   %s%s", entry.name or "?", timeStr)
                    imgui.PopStyleColor()
                end
                
                -- Subtle separator between entries (not after last)
                if i < #entries then
                    imgui.PushStyleColor(imgui.Col_Separator, {0.25, 0.22, 0.18, 0.4})
                    imgui.Separator()
                    imgui.PopStyleColor()
                end
            end
        end
        
        -- Show secrets section header if any exist
        if secrets and #secrets > 0 then
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col_Text, {0.55, 0.3, 0.4, 0.8})
            imgui.Text("— Whispers —")
            imgui.PopStyleColor()
        end
        
    end
    imgui.EndChild()
    
    -- Bottom controls hint
    imgui.Spacing()
    imgui.Separator()
    imgui.PushStyleColor(imgui.Col_Text, {0.45, 0.43, 0.40, 0.8})
    imgui.Text("←→ Change Day · TAB/ESC Close")
    imgui.PopStyleColor()
    
    -- Keyboard handling
    local closed = false
    if love.keyboard.justPressed("tab", "escape") then
        self.isOpen = false
        closed = true
    elseif love.keyboard.justPressed("left") then
        self.currentDay = math.max(1, self.currentDay - 1)
    elseif love.keyboard.justPressed("right") then
        self.currentDay = self.currentDay + 1
    end
    
    imgui.End()
    
    return closed
end

return JournalUI