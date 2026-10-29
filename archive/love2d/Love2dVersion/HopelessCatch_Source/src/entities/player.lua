-- src/entities/player.lua - Fisherman Entity, Animation, and Rod Anchor
local Assets = require("src.core.assets")

local Player = {
    x = 450,
    y = 606,
    vx = 0,
    speed = 180,
    facing = 1, -- 1 = right, -1 = left
    isFishing = false,
    walkTimer = 0
}

function Player.init(startX, startY)
    Player.x = startX or 450
    Player.y = startY or 606
    Player.vx = 0
    Player.facing = 1
    Player.isFishing = false
end

function Player.update(dt, input, canMove, minX, maxX)
    if not canMove then
        Player.vx = 0
        return
    end
    
    local move = 0
    if input.isDown("left") then move = move - 1 end
    if input.isDown("right") then move = move + 1 end
    
    if move ~= 0 then
        Player.facing = move
        Player.vx = move * Player.speed
        Player.walkTimer = Player.walkTimer + dt * 8
    else
        Player.vx = 0
    end
    
    Player.x = Player.x + Player.vx * dt
    if minX and Player.x < minX then Player.x = minX end
    if maxX and Player.x > maxX then Player.x = maxX end
end

function Player.draw(fishingState)
    local sheet = Assets.getImage("player_sheet")
    local bob = (Player.vx ~= 0) and math.sin(Player.walkTimer) * 3 or 0
    
    -- Ground drop shadow firmly anchoring boots to the wooden pier planks
    love.graphics.setColor(0.06, 0.04, 0.02, 0.60)
    love.graphics.ellipse("fill", Player.x, Player.y - 1, 28, 8)
    
    if sheet and Assets.quads.player then
        local q = Assets.quads.player.idle
        local isFlip = (Player.facing == -1)
        
        if fishingState == "charging" then
            q = isFlip and Assets.quads.player.charge_flip or Assets.quads.player.charge
        elseif fishingState == "flying" or fishingState == "bobbing" or fishingState == "biting" then
            q = isFlip and Assets.quads.player.cast_flip or Assets.quads.player.cast
        elseif fishingState == "reeling" then
            q = isFlip and Assets.quads.player.reel_flip or Assets.quads.player.reel
        else
            q = isFlip and Assets.quads.player.idle_flip or Assets.quads.player.idle
        end
        
        local _, _, qw, qh = q:getViewport()
        local scale = 160 / qh
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sheet, q, Player.x, Player.y + bob + 4, 0, scale, scale, qw * 0.5, qh)
    else
        local img = Assets.getImage("player_back") or Assets.getImage("player")
        if img then
            local iw = img:getWidth()
            local ih = img:getHeight()
            local scale = 160 / ih
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, Player.x, Player.y + bob + 4, 0, scale, scale, iw * 0.5, ih)
        end
    end
end

function Player.getRodTip(fishingState)
    local bob = (Player.vx ~= 0) and math.sin(Player.walkTimer) * 3 or 0
    local f = Player.facing or 1
    
    if fishingState == "charging" then
        return Player.x - (33 * f), Player.y - 144 + bob
    elseif fishingState == "reeling" then
        return Player.x + (56 * f), Player.y - 148 + bob
    elseif fishingState == "flying" or fishingState == "bobbing" or fishingState == "biting" then
        return Player.x + (36 * f), Player.y - 148 + bob
    else -- idle
        return Player.x - (68 * f), Player.y - 86 + bob
    end
end

return Player
