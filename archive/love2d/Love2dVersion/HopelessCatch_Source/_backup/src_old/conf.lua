-- Hopeless Catch - Love2D Configuration
function love.conf(t)
    t.window.title = "Hopeless Catch"
    t.version = "11.5" -- Love2D version target
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = 1
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    t.identity = "HopelessCatch"
    t.console = true -- Attach/open a terminal console window on Windows to see print/debug logs live
end
