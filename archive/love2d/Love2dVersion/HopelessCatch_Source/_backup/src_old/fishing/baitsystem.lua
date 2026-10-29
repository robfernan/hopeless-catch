-- fishing/baitsystem.lua - Bait management and tackle box
local BaitSystem = {}

-- Current bait state
local currentBait = nil
local showTacklebox = false
local selectedBaitIndex = 1
local tackleboxScrollOffset = 0

-- Bait inventory with unique IDs and preference tags
-- Each bait has a `baitId` used by fishdata.lua to filter compatible species.
local baitInventory = {
    {name = "Worms",   baitId = "worms",   type = "basic", attraction = 1.0, asset = "bait_worms"},
    {name = "Minnows", baitId = "minnows", type = "live",  attraction = 1.5, asset = "bait_minnows"},
    {name = "Cheese",  baitId = "cheese",  type = "basic", attraction = 0.8, asset = "bait_cheese"},
    {name = "Corn",    baitId = "corn",    type = "basic", attraction = 0.7, asset = "bait_corn"}
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
    if baitInventory[baitIndex] then
        currentBait = baitInventory[baitIndex]
        return true
    else
        return false
    end
end

function BaitSystem:consumeBait()
    -- With unlimited bait, always succeed if a bait is selected
    if currentBait then
        return true
    end
    return false
end

function BaitSystem:getBaitModifiers()
    if not currentBait then
        return {attraction = 0.5, baitId = nil}
    end
    return {attraction = currentBait.attraction, baitId = currentBait.baitId}
end

--- Get the unique bait ID of the currently selected bait.
-- This is passed to FishData:selectFish() for preference filtering.
function BaitSystem:getCurrentBaitId()
    if not currentBait then return nil end
    return currentBait.baitId
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
