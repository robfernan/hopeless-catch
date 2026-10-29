-- fishing/fishdata.lua - Fish species and their properties
local FishData = {}

-- Fish data - All available fish using your assets
-- `preferredBaits` lists the baitId values this species will bite on.
-- If nil or empty, the fish bites on any bait (universal).
FishData.dayFish = {
    {name = "Sunfish", description = "A small, peaceful fish that glints in the sunlight.", rarity = 0.8, difficulty = 1, asset = "fish_sunfish",
     preferredBaits = {"worms", "corn"}},
    {name = "Bass", description = "A common freshwater fish, nothing unusual about it.", rarity = 0.6, difficulty = 2, asset = "fish_bass",
     preferredBaits = {"minnows", "worms"}},
    {name = "Trout", description = "A beautiful fish with spotted sides.", rarity = 0.4, difficulty = 2, asset = "fish_trout",
     preferredBaits = {"minnows", "corn"}},
    {name = "Catfish", description = "A bottom feeder with whiskers.", rarity = 0.5, difficulty = 3, asset = "fish_catfish",
     preferredBaits = {"worms", "cheese"}},
    {name = "Golden Carp", description = "A rare, beautiful golden fish that brings good fortune.", rarity = 0.1, difficulty = 4, asset = "fish_golden_carp",
     preferredBaits = {"corn", "cheese"}}
}

-- Night fish - including the more exotic species
-- `nightNarrative` is a creepy snippet unlocked (25% chance) when caught at night.
FishData.nightFish = {
    {name = "Pale Crawler", description = "A mysterious pale fish that only comes out at night.", rarity = 0.5, difficulty = 3, asset = "fish_pale_crawler",
     preferredBaits = {"worms", "cheese"},
     nightNarrative = "Its scales were translucent. I could see something moving inside."},
    {name = "Bleeding Carp", description = "An unusual carp with strange red markings.", rarity = 0.3, difficulty = 4, asset = "fish_bleeding_carp",
     preferredBaits = {"corn", "minnows"},
     nightNarrative = "The blood wasn't red anymore by the time I looked away."},
    {name = "Whispering Eel", description = "A long, slender eel that seems to move with purpose.", rarity = 0.2, difficulty = 5, asset = "fish_whispering_eel",
     preferredBaits = {"minnows"},
     nightNarrative = "It whispered my name. I was sure of it."},
    {name = "Fishman", description = "Something that shouldn't exist... but does.", rarity = 0.05, difficulty = 6, asset = "fishman",
     preferredBaits = nil,
     nightNarrative = "It had too many fingers."} -- Fishman bites on ANY bait (it doesn't care what you offer)
}

-- Get fish pool based on time of day (unfiltered)
function FishData:getFishPool(isNight)
    return isNight and self.nightFish or self.dayFish
end

--- Filter the fish pool by bait preference.
-- A fish is included if:
--   • it has no `preferredBaits` restriction (universal, e.g. Fishman), OR
--   • its `preferredBaits` list contains the given baitId.
-- If no fish match the bait, falls back to the full pool so the player
-- always gets a bite (just less likely to get their preferred species).
function FishData:getFilteredFishPool(isNight, baitId)
    local fullPool = self:getFishPool(isNight)
    
    -- No bait selected or no ID: return full pool (any fish can bite)
    if not baitId then
        return fullPool
    end
    
    local filtered = {}
    for _, fish in ipairs(fullPool) do
        -- nil preferredBaits means "bites on anything"
        if fish.preferredBaits == nil then
            table.insert(filtered, fish)
        else
            for _, id in ipairs(fish.preferredBaits) do
                if id == baitId then
                    table.insert(filtered, fish)
                    break
                end
            end
        end
    end
    
    -- Fallback: if filtering removed everything, use the full pool
    if #filtered == 0 then
        return fullPool
    end
    
    return filtered
end

-- Get all fish for collection purposes
function FishData:getAllFish()
    local allFish = {}
    for _, fish in ipairs(self.dayFish) do
        table.insert(allFish, fish)
    end
    for _, fish in ipairs(self.nightFish) do
        table.insert(allFish, fish)
    end
    return allFish
end

-- Main selectFish function that takes day/night cycle and bait
-- @param dayNightCycle DayNightCycle module (or nil)
-- @param currentBait table with a `baitId` field, or just the baitId string, or nil
function FishData:selectFish(dayNightCycle, currentBait)
    -- Determine if it's night time
    local isNight = false
    if dayNightCycle then
        if type(dayNightCycle.isNightTime) == "function" then
            isNight = dayNightCycle:isNightTime()
        elseif type(dayNightCycle.getTimeOfDay) == "function" then
            local t = dayNightCycle:getTimeOfDay()
            isNight = (t < 0.3 or t > 0.8)
        end
    end
    
    -- Extract the bait ID from whatever format was passed
    local baitId = nil
    if type(currentBait) == "string" then
        baitId = currentBait
    elseif type(currentBait) == "table" and currentBait.baitId then
        baitId = currentBait.baitId
    end
    
    -- Get the appropriate fish pool, filtered by bait preference
    local fishPool = self:getFilteredFishPool(isNight, baitId)
    
    -- Select fish from pool using weighted probability
    local selectedFish = self:selectFishFromPool(fishPool, currentBait)
    
    if isNight and selectedFish then
        -- Fishman stinger: fire horror event when the Fishman is hooked at night
        if selectedFish.name == "Fishman" then
            local HorrorEvents = require("world.horrorevents")
            if type(HorrorEvents.triggerFishmanStinger) == "function" then
                HorrorEvents:triggerFishmanStinger()
            end
        end
        
        -- Rare night catch narrative unlock (25% chance)
        local fishDef = self:getFishDefinition(selectedFish.name, true)
        if fishDef and fishDef.nightNarrative then
            if math.random() < 0.25 then
                local Journal = require("ui.journal")
                local DayNightCycle = require("world.daynightcycle")
                local dayNum = 1
                if type(DayNightCycle.getCurrentDay) == "function" then
                    dayNum = DayNightCycle:getCurrentDay()
                end
                -- Use the narrative-specific method if available, else fall back
                if type(Journal.unlockNarrativeSnippet) == "function" then
                    Journal:unlockNarrativeSnippet(dayNum, fishDef.nightNarrative, selectedFish.name)
                else
                    Journal:unlockSecretEntry(dayNum, fishDef.nightNarrative)
                end
            end
        end
    end
    
    return selectedFish
end

-- Helper function for weighted selection
-- Applies a small attraction bonus if the bait is in the fish's preferred list.
function FishData:selectFishFromPool(fishPool, currentBait)
    -- Extract baitId for preference weighting
    local baitId = nil
    if type(currentBait) == "string" then
        baitId = currentBait
    elseif type(currentBait) == "table" and currentBait.baitId then
        baitId = currentBait.baitId
    end
    
    local totalWeight = 0
    for _, fish in ipairs(fishPool) do
        local weight = fish.rarity
        -- Boost weight by 50% if this is a preferred bait (increases odds)
        if baitId and fish.preferredBaits then
            for _, id in ipairs(fish.preferredBaits) do
                if id == baitId then
                    weight = weight * 1.5
                    break
                end
            end
        end
        totalWeight = totalWeight + weight
    end
    
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for _, fish in ipairs(fishPool) do
        -- Use the same boosted weight as calculated above
        local weight = fish.rarity
        if baitId and fish.preferredBaits then
            for _, id in ipairs(fish.preferredBaits) do
                if id == baitId then
                    weight = weight * 1.5
                    break
                end
            end
        end
        currentWeight = currentWeight + weight
        if roll <= currentWeight then
            -- Return a copy with the proper structure
            return {
                name = fish.name,
                type = fish.asset,
                description = fish.description,
                difficulty = fish.difficulty,
                rarity = fish.rarity < 0.3 and "rare" or (fish.rarity < 0.6 and "uncommon" or "common")
            }
        end
    end
    
    -- Fallback to first fish
    local fish = fishPool[1]
    return {
        name = fish.name,
        type = fish.asset,
        description = fish.description,
        difficulty = fish.difficulty,
        rarity = fish.rarity < 0.3 and "rare" or (fish.rarity < 0.6 and "uncommon" or "common")
    }
end

--- Look up a fish definition by name from the appropriate pool.
-- @param name string fish display name
-- @param isNight boolean which pool to search
function FishData:getFishDefinition(name, isNight)
    local pool = isNight and self.nightFish or self.dayFish
    for _, fish in ipairs(pool) do
        if fish.name == name then
            return fish
        end
    end
    -- Also check the other pool (edge case: Fishman at day via debug)
    local otherPool = isNight and self.dayFish or self.nightFish
    for _, fish in ipairs(otherPool) do
        if fish.name == name then
            return fish
        end
    end
    return nil
end

return FishData
