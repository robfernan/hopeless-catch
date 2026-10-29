-- src/data/baitdata.lua - Bait types, quantities, and Rotten Tide degradation
local BaitData = {
    inventory = {
        { id = "worms", name = "Fat Worms", count = 10, potency = 1.0, asset = "bait_worms", desc = "Standard garden earthworms. Squirming blindly." },
        { id = "corn", name = "Sweet Corn", count = 8, potency = 0.9, asset = "bait_corn", desc = "Golden niblets soaked in artificial syrup." },
        { id = "minnows", name = "Live Minnows", count = 6, potency = 1.2, asset = "bait_minnows", desc = "Frantic small fish swimming in a rusted bucket." },
        { id = "cheese", name = "Pungent Cheese", count = 5, potency = 1.1, asset = "bait_cheese", desc = "Aged curd with an overpowering reek." },
        { id = "rotten_meat", name = "Rotten Offal", count = 3, potency = 1.8, asset = "bait_worms", desc = "Necrotic meat pulled from the tide. Attracts the unmentionable." }
    },
    selectedIdx = 1
}

function BaitData.getSelected()
    return BaitData.inventory[BaitData.selectedIdx]
end

function BaitData.select(index)
    if index >= 1 and index <= #BaitData.inventory then
        BaitData.selectedIdx = index
    end
end

function BaitData.consumeSelected()
    local b = BaitData.getSelected()
    if b and b.count > 0 then
        b.count = b.count - 1
        return true
    end
    return false
end

function BaitData.applyRottenTide()
    -- During high rotten tide, clean baits spoil into necrotic lures
    for _, b in ipairs(BaitData.inventory) do
        if b.id == "worms" and math.random() < 0.3 then
            b.name = "Necrotic Maggots"
            b.potency = 1.5
        end
    end
end

return BaitData
