-- fishing/baitsystem.lua - Bait management and tackle box
local BaitSystem = {}

-- Current bait state
local currentBait = nil
local showTacklebox = false
local selectedBaitIndex = 1
local tackleboxScrollOffset = 0

-- Bait inventory with counts
local baitInventory = {
    {name = "Worms", type = "basic", attraction = 1.0, asset = "bait_worms"},
    {name = "Minnows", type = "live", attraction = 1.5, asset = "bait_minnows"},
    {name = "Cheese", type = "basic", attraction = 0.8, asset = "bait_cheese"},
    {name = "Corn", type = "basic", attraction = 0.7, asset = "bait_corn"}
}

function BaitSystem:init()
    currentBait = nil
    showTacklebox = false
    selectedBaitIndex = 1
    tackleboxScrollOffset = 0
    
    -- No bait counts needed - unlimited bait
end

-- Bait System Functions
function BaitSystem:getBaitInventory()
    return baitInventory
end

function BaitSystem:getCurrentBait()
    return currentBait
end

function BaitSystem:getBaitCount(baitType)
    -- Return unlimited bait (always return 999)
    return 999
end

function BaitSystem:useBait(baitItem)
    -- With unlimited bait, we don't decrease the count
    -- This method exists so the game doesn't crash but does nothing
    return true
end

function BaitSystem:selectBait(baitIndex)
    print("DEBUG: selectBait called with index", baitIndex)
    if baitInventory[baitIndex] then
        currentBait = baitInventory[baitIndex]
        print("Selected: " .. currentBait.name)
        return true
    else
        print("Invalid bait selection!")
        return false
    end
end

function BaitSystem:consumeBait()
    if currentBait and currentBait.count > 0 then
        currentBait.count = currentBait.count - 1
        if currentBait.count <= 0 then
            print("Out of " .. currentBait.name .. "!")
        end
        return true
    end
    return false
end

function BaitSystem:getBaitModifiers()
    if not currentBait then
        return {attraction = 0.5}
    end
    return {attraction = currentBait.attraction}
end

-- Tackle Box Functions
function BaitSystem:toggleTacklebox()
    showTacklebox = not showTacklebox
    if showTacklebox then
        selectedBaitIndex = 1
        tackleboxScrollOffset = 0
        print("Tacklebox opened")
    else
        print("Tacklebox closed")
    end
end

function BaitSystem:isTackleboxOpen()
    return showTacklebox
end

function BaitSystem:navigateTackleboxUp()
    if selectedBaitIndex > 1 then
        selectedBaitIndex = selectedBaitIndex - 1
    end
end

function BaitSystem:navigateTackleboxDown()
    if selectedBaitIndex < #baitInventory then
        selectedBaitIndex = selectedBaitIndex + 1
    end
end

function BaitSystem:selectTackleboxBait()
    self:selectBait(selectedBaitIndex)
end

return BaitSystem
