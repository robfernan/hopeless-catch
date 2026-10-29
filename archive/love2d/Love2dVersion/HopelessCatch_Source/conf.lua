-- conf.lua - Hopeless Catch Engine Configuration
function love.conf(t)
    t.identity = "HopelessCatch"
    t.version = "11.4"
    
    t.window.title = "Hopeless Catch"
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = true
    
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
    
    t.console = true
end
