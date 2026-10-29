-- fishing/fishdata.lua - Fish species and their properties
local FishData = {}

-- Fish data - All available fish using your assets
FishData.dayFish = {
    {name = "Sunfish", description = "A small, peaceful fish that glints in the sunlight.", rarity = 0.8, difficulty = 1, asset = "fish_sunfish"},
    {name = "Bass", description = "A common freshwater fish, nothing unusual about it.", rarity = 0.6, difficulty = 2, asset = "fish_bass"},
    {name = "Trout", description = "A beautiful fish with spotted sides.", rarity = 0.4, difficulty = 2, asset = "fish_trout"},
    {name = "Catfish", description = "A bottom feeder with whiskers.", rarity = 0.5, difficulty = 3, asset = "fish_catfish"},
    {name = "Golden Carp", description = "A rare, beautiful golden fish that brings good fortune.", rarity = 0.1, difficulty = 4, asset = "fish_golden_carp"}
}

-- Night fish - including the more exotic species
FishData.nightFish = {
    {name = "Pale Crawler", description = "A mysterious pale fish that only comes out at night.", rarity = 0.5, difficulty = 3, asset = "fish_pale_crawler"},
    {name = "Bleeding Carp", description = "An unusual carp with strange red markings.", rarity = 0.3, difficulty = 4, asset = "fish_bleeding_carp"},
    {name = "Whispering Eel", description = "A long, slender eel that seems to move with purpose.", rarity = 0.2, difficulty = 5, asset = "fish_whispering_eel"},
    {name = "Fishman", description = "Something that shouldn't exist... but does.", rarity = 0.05, difficulty = 6, asset = "fishman"}
}

-- Get fish pool based on time of day
function FishData:getFishPool(isNight)
    return isNight and self.nightFish or self.dayFish
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
function FishData:selectFish(dayNightCycle, currentBait)
    -- Determine if it's night time
    local isNight = false
    if dayNightCycle and dayNightCycle.isNight then
        isNight = dayNightCycle.isNight
    end
    
    -- Get the appropriate fish pool
    local fishPool = self:getFishPool(isNight)
    
    -- Select fish from pool using weighted probability
    return self:selectFishFromPool(fishPool, currentBait)
end

-- Helper function for weighted selection
function FishData:selectFishFromPool(fishPool, currentBait)
    local totalWeight = 0
    for _, fish in ipairs(fishPool) do
        totalWeight = totalWeight + fish.rarity
    end
    
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for _, fish in ipairs(fishPool) do
        currentWeight = currentWeight + fish.rarity
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

return FishData
