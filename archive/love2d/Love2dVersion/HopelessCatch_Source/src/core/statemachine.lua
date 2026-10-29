-- src/core/statemachine.lua - Pushdown Stack & Finite State Machine
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states)
    local self = setmetatable({}, StateMachine)
    self.states = states or {}
    self.stack = {}
    return self
end

function StateMachine:register(name, stateInstance)
    self.states[name] = stateInstance
end

function StateMachine:change(name, ...)
    if #self.stack > 0 then
        local current = self.stack[#self.stack]
        if current.exit then current:exit() end
        self.stack[#self.stack] = nil
    end
    
    local nextState = self.states[name]
    assert(nextState, "StateMachine: State not found: " .. tostring(name))
    table.insert(self.stack, nextState)
    if nextState.enter then nextState:enter(...) end
end

function StateMachine:push(name, ...)
    if #self.stack > 0 then
        local current = self.stack[#self.stack]
        if current.pause then current:pause() end
    end
    
    local nextState = self.states[name]
    assert(nextState, "StateMachine: State not found: " .. tostring(name))
    table.insert(self.stack, nextState)
    if nextState.enter then nextState:enter(...) end
end

function StateMachine:pop(...)
    if #self.stack > 0 then
        local current = self.stack[#self.stack]
        if current.exit then current:exit() end
        table.remove(self.stack)
    end
    
    if #self.stack > 0 then
        local top = self.stack[#self.stack]
        if top.resume then top:resume(...) end
    end
end

function StateMachine:current()
    return self.stack[#self.stack]
end

function StateMachine:currentName()
    local cur = self:current()
    if not cur then return nil end
    for name, state in pairs(self.states) do
        if state == cur then return name end
    end
    return nil
end

function StateMachine:update(dt)
    local cur = self:current()
    if cur and cur.update then
        cur:update(dt)
    end
end

function StateMachine:draw()
    -- Render from bottom of stack up if states request background persistence (e.g. pause overlay)
    for i, state in ipairs(self.stack) do
        if state.draw then
            state:draw()
        end
    end
end

return StateMachine
