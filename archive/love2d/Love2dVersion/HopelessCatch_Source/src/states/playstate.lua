-- src/states/playstate.lua - Core Fishing Simulation & Dread Loop
local Assets = require("src.core.assets")
local SkyRenderer = require("src.world.skyrenderer")
local Terrain = require("src.world.terrain")
local Water = require("src.world.water")
local Lighting = require("src.world.lighting")
local Weather = require("src.world.weather")

local Player = require("src.entities.player")
local DayNight = require("src.systems.daynight")
local FishingSystem = require("src.systems.fishingsystem")

local HUD = require("src.ui.hud")
local CatchDisplay = require("src.ui.catchdisplay")
local TackleBox = require("src.ui.tacklebox")
local Journal = require("src.ui.journal")
local Input = require("src.core.input")

local PlayState = {
    modal = nil, -- nil, "catch", "tackle", "journal", "cabin_fade"
    cabinTimer = 0,
    sm = nil
}

function PlayState.new(stateMachine)
    local self = setmetatable({}, { __index = PlayState })
    self.sm = stateMachine
    return self
end

function PlayState:enter(params)
    self.modal = nil
    self.cabinTimer = 0
    local w, h = love.graphics.getDimensions()
    local minX, maxX, standY, horizonY, dockEdgeY, lanternX, lanternY = Terrain.getDockBounds(w, h)
    Player.init(w * 0.5, standY)
    Assets.startAmbient()
    Weather.init()
    
    -- Begin game in full daylight with golden sunlight
    DayNight.time = 0.45
    DayNight.isNight = false
    DayNight.day = 1
    DayNight.rottenTideLevel = 1.0
    
    if params and params.openJournal then
        self.modal = "journal"
    end
end

function PlayState:resume(params)
    if params and params.openJournal then
        self.modal = "journal"
    end
end

function PlayState:update(dt)
    local w, h = love.graphics.getDimensions()
    local minX, maxX, standY, horizonY, dockEdgeY, lanternX, lanternY = Terrain.getDockBounds(w, h)
    
    -- Firmly lock fisherman feet to the wooden dock planks!
    Player.y = standY
    
    -- Ensure game is in bright sunlight when starting day 1
    if DayNight.day == 1 and DayNight.time > 0.80 then
        DayNight.time = 0.45
        DayNight.isNight = false
    end
    
    -- Cabin Sleep fade
    if self.modal == "cabin_fade" then
        self.cabinTimer = self.cabinTimer + dt
        if self.cabinTimer >= 2.5 then
            DayNight.advanceDay()
            self.modal = nil
            self.cabinTimer = 0
        end
        return
    end
    
    -- Catch Display auto-modal trigger
    if FishingSystem.state == "caught" and self.modal ~= "catch" then
        self.modal = "catch"
        Journal.addCatch(DayNight.day, FishingSystem.caughtFish)
    end
    
    -- Modal updates
    if self.modal == "tackle" then
        TackleBox.updateInput(Input, w, h)
        if Input.isPressed("tackle") or Input.isPressed("cancel") then
            self.modal = nil
        end
        return
    elseif self.modal == "journal" then
        if Input.isPressed("journal") or Input.isPressed("cancel") then
            self.modal = nil
        end
        return
    elseif self.modal == "catch" then
        if Input.isPressed("action") or Input.isPressed("cancel") then
            self.modal = nil
            FishingSystem.reset()
        end
        return
    end
    
    -- In-game hotkeys
    if Input.isPressed("cancel") then
        self.sm:push("pause")
        return
    elseif Input.isPressed("tackle") and FishingSystem.state == "idle" then
        self.modal = "tackle"
        return
    elseif Input.isPressed("journal") then
        self.modal = "journal"
        return
    elseif Input.isPressed("rest") and FishingSystem.state == "idle" then
        self.modal = "cabin_fade"
        self.cabinTimer = 0
        return
    end
    
    -- Core simulation
    local canMove = (FishingSystem.state == "idle" or FishingSystem.state == "charging")
    Player.update(dt, Input, canMove, minX, maxX)
    Player.y = standY -- Enforce position on the pier floor
    DayNight.update(dt)
    Water.update(dt)
    Weather.update(dt, DayNight, horizonY, dockEdgeY)
    FishingSystem.update(dt, Input, Player, DayNight, horizonY, dockEdgeY)
end

function PlayState:draw()
    local w, h = love.graphics.getDimensions()
    local minX, maxX, standY, horizonY, dockEdgeY, lanternX, lanternY = Terrain.getDockBounds(w, h)
    
    -- 1. Sky & Celestial Layer
    SkyRenderer.draw(DayNight, w, h)
    Weather.drawSky(w, h, DayNight)
    
    -- 2. Distant Mountains & Horizon Forest Layer (Behind water)
    Terrain.drawBackground(w, h, DayNight)
    
    -- 3. Water Surface Layer (Mode-7 2.5D deep lake lakebed)
    Water.draw(w, h, DayNight)
    Weather.drawOverlays(w, h, horizonY, dockEdgeY)
    
    -- 4. Foreground Pier Layer (Drawn over water under fisherman feet)
    Terrain.draw(w, h, DayNight)
    
    -- 4. Entity & Fishing Line Layer
    FishingSystem.draw(Player, horizonY, dockEdgeY)
    Player.draw(FishingSystem.state)
    
    -- 5. Dynamic Lighting & Dread Vignette Layer
    Lighting.draw(w, h, DayNight, Player.x, Player.y, lanternX, lanternY)
    
    -- 6. HUD Layer
    HUD.draw(w, h, DayNight, FishingSystem)
    
    -- 7. Modals
    if self.modal == "catch" then
        CatchDisplay.draw(w, h, FishingSystem.caughtFish)
    elseif self.modal == "tackle" then
        TackleBox.draw(w, h)
    elseif self.modal == "journal" then
        Journal.draw(w, h, DayNight.day)
    elseif self.modal == "cabin_fade" then
        local fade = math.sin((self.cabinTimer / 2.5) * math.pi)
        love.graphics.setColor(0, 0, 0, fade)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setFont(Assets.fonts.large)
        love.graphics.setColor(0.9, 0.85, 0.78, fade)
        love.graphics.printf("Resting in the cabin as the Rotten Tide rolls in...", 0, h * 0.45, w, "center")
    end
end

return PlayState
