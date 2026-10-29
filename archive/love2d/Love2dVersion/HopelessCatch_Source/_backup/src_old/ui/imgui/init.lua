-- ui/imgui/init.lua - ImGui lifecycle manager for Hopeless Catch
-- Handles initialization, per-frame update, and rendering.

local imgui = require("cimgui")
local Theme = require("ui.imgui.theme")

local GUI = {}
GUI.initialized = false
GUI.enabled = true  -- master toggle: when false, ImGui is skipped entirely

--- Initialize ImGui context + horror theme. Call once in love.load().
function GUI:init()
    if self.initialized then return end
    
    imgui.love.Init()
    
    -- Apply the horror theme
    Theme:apply()
    
    -- Configure IO for our game
    local io = imgui.GetIO()
    local bit = require("bit")
    io.ConfigFlags = bit.bor(imgui.ConfigFlags_NavEnableKeyboard, imgui.ConfigFlags_NavEnableGamepad)
    
    self.initialized = true
    print("✓ ImGui initialized with Hopeless Catch theme")
end

--- Per-frame update. Call in love.update(dt) BEFORE game logic if you want
-- ImGui to capture input first, or AFTER if game keys should take priority.
function GUI:update(dt)
    if not self.initialized then return end
    imgui.love.Update(dt)
    imgui.NewFrame()
end

--- Render all ImGui draw lists. Call at the END of love.draw().
function GUI:render()
    if not self.initialized or not self.enabled then return end
    imgui.Render()
    imgui.love.RenderDrawLists()
end

--- Check if ImGui wants to capture mouse input (so game can skip its own).
function GUI:wantsMouse()
    if not self.initialized then return false end
    return imgui.love.GetWantCaptureMouse()
end

--- Check if ImGui wants keyboard focus.
function GUI:wantsKeyboard()
    if not self.initialized then return false end
    return imgui.love.GetWantCaptureKeyboard()
end

--- Begin a named window. Returns true if the window is open/visible.
-- @param title string window title (use "##Hidden" for no visible title)
-- @param opts table optional {flags=..., pos={x,y}, size={w,h}}
function GUI:beginWindow(title, opts)
    opts = opts or {}
    local flags = opts.flags or 0
    
    if opts.pos and opts.size then
        return imgui.Begin(title, nil, flags, opts.pos[1], opts.pos[2], opts.size[1], opts.size[2])
    elseif opts.pos then
        return imgui.Begin(title, nil, flags, opts.pos[1], opts.pos[2])
    else
        return imgui.Begin(title, nil, flags)
    end
end

--- End the current window. Call after GUI:beginWindow().
function GUI:endWindow()
    imgui.End()
end

--- Convenience: draw a full-screen overlay (no title bar, no border).
-- @param id string unique identifier for this overlay
function GUI:beginOverlay(id)
    local w, h = love.graphics.getDimensions()
    local bit = require("bit")
    local flags = bit.bor(
        imgui.WindowFlags_NoTitleBar,
        imgui.WindowFlags_NoResize,
        imgui.WindowFlags_NoMove,
        imgui.WindowFlags_NoCollapse,
        imgui.WindowFlags_NoSavedSettings,
        imgui.WindowFlags_AlwaysAutoResize
    )
    
    return imgui.Begin("##" .. id, nil, flags, 0, 0, w, h)
end

--- End an overlay window.
function GUI:endOverlay()
    imgui.End()
end

--- Shutdown ImGui (call in love.quit()).
function GUI:shutdown()
    if not self.initialized then return end
    imgui.love.Shutdown()
    self.initialized = false
end

return GUI
