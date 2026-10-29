-- GameState.lua - Enhanced game state management
local GameState = {}

local currentState = "menu"
local previousState = "menu"
local stateTimer = 0
local transitions = {}

-- Available game states
local states = {
    menu = "menu",           -- Start menu
    playing = "playing",     -- Main gameplay
    paused = "paused",       -- Pause menu
    settings = "settings",   -- Settings menu
    journal = "journal",     -- Journal view (full screen)
    game_over = "game_over", -- Game over screen
    credits = "credits"      -- Credits screen
}

function GameState:init()
    currentState = "menu"
    previousState = "menu"
    stateTimer = 0
    transitions = {}
end

function GameState:setState(newState)
    if states[newState] then
        previousState = currentState
        currentState = newState
        stateTimer = 0
        print("🎮 Game state changed to: " .. newState)
    else
        print("❌ Invalid game state: " .. tostring(newState))
    end
end

function GameState:getState()
    return currentState
end

function GameState:getPreviousState()
    return previousState
end

function GameState:isPlaying()
    return currentState == "playing"
end

function GameState:update(dt)
    stateTimer = stateTimer + dt
    
    -- Update transitions
    for i = #transitions, 1, -1 do
        local transition = transitions[i]
        transition.timer = transition.timer + dt
        if transition.timer >= transition.duration then
            table.remove(transitions, i)
        end
    end
end

function GameState:togglePause()
    if currentState == "playing" then
        self:setState("paused")
    elseif currentState == "paused" then
        self:setState("playing")
    end
end

function GameState:startTransition(type, duration)
    table.insert(transitions, {
        type = type or "fade",
        timer = 0,
        duration = duration or 0.5
    })
end

function GameState:isInTransition()
    return #transitions > 0
end

function GameState:canPause()
    return currentState == "playing"
end

function GameState:isGameActive()
    return currentState == "playing"
end

function GameState:getStateTimer()
    return stateTimer
end

function GameState:drawTransitions()
    for _, transition in ipairs(transitions) do
        if transition.type == "fade" then
            local alpha = 1 - (transition.timer / transition.duration)
            love.graphics.setColor(0, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        end
    end
end

return GameState
