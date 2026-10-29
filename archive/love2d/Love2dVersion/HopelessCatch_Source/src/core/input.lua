-- src/core/input.lua - Unified Input and Key Management
local Input = {
    _down = {},
    _pressed = {},
    _released = {},
    _mouse = { x = 0, y = 0, down = {}, pressed = {}, released = {} },
    _wheel = { x = 0, y = 0 },
    
    -- Binding mappings
    bindings = {
        left = {"a", "left"},
        right = {"d", "right"},
        up = {"w", "up"},
        down = {"s", "down"},
        action = {"space", "return"},
        cancel = {"escape", "backspace"},
        journal = {"tab", "j"},
        tackle = {"b", "t"},
        rest = {"h", "r"}
    }
}

function Input.update()
    Input._pressed = {}
    Input._released = {}
    Input._mouse.pressed = {}
    Input._mouse.released = {}
    Input._wheel.x, Input._wheel.y = 0, 0
    Input._mouse.x, Input._mouse.y = love.mouse.getPosition()
end

function Input.keypressed(key)
    Input._down[key] = true
    Input._pressed[key] = true
end

function Input.keyreleased(key)
    Input._down[key] = false
    Input._released[key] = true
end

function Input.mousepressed(x, y, button)
    Input._mouse.down[button] = true
    Input._mouse.pressed[button] = true
end

function Input.mousereleased(x, y, button)
    Input._mouse.down[button] = false
    Input._mouse.released[button] = true
end

function Input.wheelmoved(x, y)
    Input._wheel.x, Input._wheel.y = x, y
end

function Input.isDown(actionOrKey)
    if Input._down[actionOrKey] then return true end
    local list = Input.bindings[actionOrKey]
    if list then
        for _, k in ipairs(list) do
            if Input._down[k] then return true end
        end
    end
    return false
end

function Input.isPressed(actionOrKey)
    if Input._pressed[actionOrKey] then return true end
    local list = Input.bindings[actionOrKey]
    if list then
        for _, k in ipairs(list) do
            if Input._pressed[k] then return true end
        end
    end
    return false
end

function Input.isReleased(actionOrKey)
    if Input._released[actionOrKey] then return true end
    local list = Input.bindings[actionOrKey]
    if list then
        for _, k in ipairs(list) do
            if Input._released[k] then return true end
        end
    end
    return false
end

function Input.getMouse()
    return Input._mouse.x, Input._mouse.y
end

function Input.isMouseDown(button)
    return Input._mouse.down[button or 1] == true
end

function Input.isMousePressed(button)
    return Input._mouse.pressed[button or 1] == true
end

return Input
