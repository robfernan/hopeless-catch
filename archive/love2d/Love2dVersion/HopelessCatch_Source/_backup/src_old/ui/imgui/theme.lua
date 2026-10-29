-- ui/imgui/theme.lua - Horror-themed ImGui style for Hopeless Catch
local imgui = require("cimgui")
local ffi = require("ffi")

local Theme = {}

--- Helper to create an ImVec4 cdata securely in LuaJIT FFI
local function col(r, g, b, a)
    return ffi.new("ImVec4", r, g, b, a)
end

--- Apply the "Hopeless Catch" dark horror theme to ImGui.
function Theme:apply()
    local s = imgui.GetStyle()
    local c = s.Colors
    
    local function setColor(idx, color)
        if idx ~= nil then
            c[idx] = color
        end
    end

    -- Window
    setColor(imgui.ImGuiCol_WindowBg,             col(0.07, 0.07, 0.10, 0.82))
    setColor(imgui.ImGuiCol_ChildBg,              col(0.08, 0.08, 0.11, 0.80))
    setColor(imgui.ImGuiCol_PopupBg,              col(0.09, 0.09, 0.12, 0.94))
    
    -- Borders
    setColor(imgui.ImGuiCol_Border,               col(0.35, 0.28, 0.22, 0.8))
    setColor(imgui.ImGuiCol_BorderShadow,         col(0, 0, 0, 0))
    
    -- Text
    setColor(imgui.ImGuiCol_Text,                 col(0.95, 0.92, 0.88, 1.0))   -- bright warm white
    setColor(imgui.ImGuiCol_TextDisabled,         col(0.55, 0.52, 0.48, 1.0))
    
    -- Frame Backgrounds
    setColor(imgui.ImGuiCol_FrameBg,              col(0.18, 0.15, 0.14, 0.9))
    setColor(imgui.ImGuiCol_FrameBgHovered,       col(0.35, 0.22, 0.18, 0.9))
    setColor(imgui.ImGuiCol_FrameBgActive,        col(0.45, 0.25, 0.18, 1.0))
    
    -- Buttons - clear dark iron background with glowing blood-orange hover/active
    setColor(imgui.ImGuiCol_Button,               col(0.20, 0.17, 0.16, 0.95))
    setColor(imgui.ImGuiCol_ButtonHovered,        col(0.55, 0.22, 0.15, 1.0))
    setColor(imgui.ImGuiCol_ButtonActive,         col(0.70, 0.28, 0.18, 1.0))
    
    -- Headers (selected items)
    setColor(imgui.ImGuiCol_Header,               col(0.45, 0.20, 0.14, 0.85))
    setColor(imgui.ImGuiCol_HeaderHovered,        col(0.60, 0.25, 0.16, 1.0))
    setColor(imgui.ImGuiCol_HeaderActive,         col(0.75, 0.30, 0.18, 1.0))
    
    -- Tabs (Dear ImGui 1.92+ uses Tab, TabHovered, TabSelected, TabDimmed, TabDimmedSelected)
    setColor(imgui.ImGuiCol_Tab,                  col(0.15, 0.13, 0.11, 0.8))
    setColor(imgui.ImGuiCol_TabHovered,           col(0.40, 0.16, 0.12, 0.9))
    setColor(imgui.ImGuiCol_TabSelected or imgui.ImGuiCol_TabActive, col(0.50, 0.20, 0.13, 1.0))
    setColor(imgui.ImGuiCol_TabDimmed,            col(0.10, 0.09, 0.08, 0.8))
    setColor(imgui.ImGuiCol_TabDimmedSelected,    col(0.20, 0.12, 0.10, 1.0))
    
    -- Scrollbar - subtle dark
    setColor(imgui.ImGuiCol_ScrollbarBg,          col(0.04, 0.04, 0.05, 0.6))
    setColor(imgui.ImGuiCol_ScrollbarGrab,        col(0.25, 0.20, 0.18, 0.8))
    setColor(imgui.ImGuiCol_ScrollbarGrabHovered, col(0.40, 0.25, 0.20, 0.9))
    setColor(imgui.ImGuiCol_ScrollbarGrabActive,  col(0.50, 0.30, 0.22, 1.0))
    
    -- Checkmark / selection - blood red
    setColor(imgui.ImGuiCol_CheckMark,            col(0.75, 0.20, 0.15, 1.0))
    setColor(imgui.ImGuiCol_SliderGrab,           col(0.45, 0.18, 0.12, 0.9))
    setColor(imgui.ImGuiCol_SliderGrabActive,     col(0.65, 0.25, 0.15, 1.0))
    
    -- Resize grip
    setColor(imgui.ImGuiCol_ResizeGrip,           col(0.30, 0.25, 0.20, 0.4))
    setColor(imgui.ImGuiCol_ResizeGripHovered,    col(0.50, 0.30, 0.20, 0.7))
    setColor(imgui.ImGuiCol_ResizeGripActive,     col(0.65, 0.35, 0.25, 1.0))
    
    -- Plot lines - pale ghostly
    setColor(imgui.ImGuiCol_PlotLines,            col(0.70, 0.68, 0.60, 0.8))
    setColor(imgui.ImGuiCol_PlotHistogram,        col(0.50, 0.20, 0.15, 0.9))
    
    -- Drag & drop target
    setColor(imgui.ImGuiCol_DragDropTarget,       col(0.75, 0.60, 0.30, 0.9))
    
    -- Spacing / sizing
    s.WindowRounding      = 4
    s.ChildRounding       = 3
    s.FrameRounding       = 2
    s.PopupRounding       = 3
    s.ScrollbarRounding   = 3
    s.GrabRounding        = 2
    
    s.WindowBorderSize    = 1
    s.ChildBorderSize     = 1
    s.PopupBorderSize     = 1
    s.FrameBorderSize     = 0
    s.TabBorderSize       = 1
    
    s.WindowPadding.x     = 14
    s.WindowPadding.y     = 12
    s.FramePadding.x      = 8
    s.FramePadding.y      = 5
    s.ItemSpacing.x       = 10
    s.ItemSpacing.y       = 8
    s.ItemInnerSpacing.x  = 6
    s.ItemInnerSpacing.y  = 4
    
    s.ScrollbarSize       = 12
    s.GrabMinSize         = 8
end

--- Set the ImGui font from a TTF file path.
-- Falls back to default if no font is provided.
function Theme:setFont(fontPath, size)
    local io = imgui.GetIO()
    
    if fontPath and love.filesystem.getInfo(fontPath) then
        local data = love.filesystem.read(fontPath)
        local cdata = ffi.new("char[?]", #data + 1)
        ffi.copy(cdata, data)
        io.Fonts:AddFontFromFileMemoryTTF(ffi.string(cdata), size or 18)
    end
    
    io.Fonts:Build()
end

return Theme