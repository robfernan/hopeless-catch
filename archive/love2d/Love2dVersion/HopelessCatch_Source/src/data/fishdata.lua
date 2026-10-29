-- src/data/fishdata.lua - Species, Rarities, Depths, and Horror Lore
local FishData = {}

-- Regular Day Species
FishData.dayFish = {
    {
        id = "sunfish",
        name = "Sunfish",
        rarity = 0.8,
        difficulty = 1,
        asset = "fish_sunfish",
        preferredBaits = {"worms", "corn"},
        desc = "A small, peaceful fish that glints in the sunlight.",
        nightNarrative = "Its belly was packed with black mud and small human teeth."
    },
    {
        id = "bass",
        name = "Bass",
        rarity = 0.6,
        difficulty = 2,
        asset = "fish_bass",
        preferredBaits = {"minnows", "worms"},
        desc = "A common freshwater predator. Nothing unusual about it... yet.",
        nightNarrative = "Its eyes were clouding over with pale milky film."
    },
    {
        id = "trout",
        name = "Trout",
        rarity = 0.45,
        difficulty = 2,
        asset = "fish_trout",
        preferredBaits = {"minnows", "corn"},
        desc = "A spotted fish found near cold currents.",
        nightNarrative = "Cold to the touch. Too cold. Like river ice."
    },
    {
        id = "catfish",
        name = "Catfish",
        rarity = 0.35,
        difficulty = 3,
        asset = "fish_catfish",
        preferredBaits = {"worms", "cheese", "rotten_meat"},
        desc = "A bottom dweller that gorges on decay.",
        nightNarrative = "Its whiskers twitched in rhythm, spelling something in the dark."
    },
    {
        id = "golden_carp",
        name = "Golden Carp",
        rarity = 0.1,
        difficulty = 4,
        asset = "fish_golden_carp",
        preferredBaits = {"corn", "cheese"},
        desc = "A rare golden fish whispered to grant fortune.",
        nightNarrative = "The gold began to peel away, revealing rotting flesh beneath."
    }
}

-- Night & Rotten Tide Species
FishData.nightFish = {
    {
        id = "pale_crawler",
        name = "Pale Crawler",
        rarity = 0.5,
        difficulty = 3,
        asset = "fish_pale_crawler",
        preferredBaits = {"worms", "cheese", "rotten_meat"},
        desc = "A translucent blind predator from subterranean caves.",
        nightNarrative = "Its skin was cellophane. I could see black bile circulating."
    },
    {
        id = "bleeding_carp",
        name = "Bleeding Carp",
        rarity = 0.3,
        difficulty = 4,
        asset = "fish_bleeding_carp",
        preferredBaits = {"minnows", "rotten_meat"},
        desc = "Covered in crimson gashes that never coagulate.",
        nightNarrative = "The blood pooling on the dock hissed when it touched the wood."
    },
    {
        id = "whispering_eel",
        name = "Whispering Eel",
        rarity = 0.18,
        difficulty = 5,
        asset = "fish_whispering_eel",
        preferredBaits = {"minnows"},
        desc = "A serpentine horror that mimics human vocal cords.",
        nightNarrative = "It gasped my mother's name with its dying breath."
    },
    {
        id = "fishman",
        name = "The Lake Warden (Fishman)",
        rarity = 0.05,
        difficulty = 6,
        asset = "fish_fishman",
        preferredBaits = nil, -- Bites on any bait; hunts YOU
        desc = "It was not born of this water. It commands it.",
        nightNarrative = "It gripped the dock with five webbed fingers and smiled."
    }
}

-- Forbidden Waters Deep Trench Abominations
FishData.forbiddenFish = {
    {
        id = "necrotic_gargoyle",
        name = "Rotten Goliath",
        rarity = 0.4,
        difficulty = 6,
        asset = "fish_catfish",
        preferredBaits = {"rotten_meat", "worms"},
        desc = "A mass of coalesced rot dredged from the forbidden trench.",
        nightNarrative = "The water receded around it in disgust."
    },
    {
        id = "elder_amalgam",
        name = "Whispering Amalgam",
        rarity = 0.2,
        difficulty = 7,
        asset = "fish_whispering_eel",
        preferredBaits = nil,
        desc = "Countless fish bodies fused into a writhing choir.",
        nightNarrative = "Every eye turned to look behind me."
    }
}

function FishData.getPool(isNight, isForbidden)
    if isForbidden then
        return FishData.forbiddenFish
    elseif isNight then
        return FishData.nightFish
    else
        return FishData.dayFish
    end
end

function FishData.selectFish(isNight, isForbidden, baitId)
    local pool = FishData.getPool(isNight, isForbidden)
    
    local eligible = {}
    for _, fish in ipairs(pool) do
        if not baitId or not fish.preferredBaits then
            table.insert(eligible, fish)
        else
            for _, b in ipairs(fish.preferredBaits) do
                if b == baitId then
                    table.insert(eligible, fish)
                    break
                end
            end
        end
    end
    
    if #eligible == 0 then eligible = pool end
    
    -- Weight selection by rarity
    local totalWeight = 0
    for _, f in ipairs(eligible) do totalWeight = totalWeight + f.rarity end
    
    local roll = math.random() * totalWeight
    local current = 0
    for _, f in ipairs(eligible) do
        current = current + f.rarity
        if roll <= current then
            return f
        end
    end
    
    return eligible[1]
end

return FishData
