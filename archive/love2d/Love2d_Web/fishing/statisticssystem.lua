-- fishing/statisticssystem.lua - Fishing statistics and achievements
local StatisticsSystem = {}

-- Statistics data
local stats = {
    totalCasts = 0,
    totalCatches = 0,
    totalFishCaught = 0,
    lineBreaks = 0,
    fishEscaped = 0,
    bitesMissed = 0,
    fishCaughtByType = {
        sunfish = 0,
        bass = 0,
        trout = 0,
        catfish = 0,
        golden_carp = 0,
        pale_crawler = 0,
        bleeding_carp = 0,
        whispering_eel = 0,
        fishman = 0
    },
    baitUsed = {
        worms = 0,
        minnows = 0,
        corn = 0,
        cheese = 0
    },
    bestReactionTime = 999,
    worstReactionTime = 0,
    averageReactionTime = 0,
    reactionTimes = {},
    sessionStartTime = 0,
    totalPlayTime = 0,
    longestFight = 0,
    shortestFight = 999,
    consecutiveCatches = 0,
    bestStreak = 0
}

function StatisticsSystem:init()
    stats.sessionStartTime = love.timer.getTime()
    print("Fishing statistics initialized")
end

function StatisticsSystem:recordCast()
    stats.totalCasts = stats.totalCasts + 1
end

function StatisticsSystem:recordBaitUsed(baitType)
    if stats.baitUsed[baitType] then
        stats.baitUsed[baitType] = stats.baitUsed[baitType] + 1
    end
end

function StatisticsSystem:recordBiteMissed()
    stats.bitesMissed = stats.bitesMissed + 1
    stats.consecutiveCatches = 0 -- Reset streak
end

function StatisticsSystem:recordReactionTime(reactionTime)
    table.insert(stats.reactionTimes, reactionTime)
    
    -- Update best/worst reaction times
    if reactionTime < stats.bestReactionTime then
        stats.bestReactionTime = reactionTime
    end
    if reactionTime > stats.worstReactionTime then
        stats.worstReactionTime = reactionTime
    end
    
    -- Calculate average
    local total = 0
    for _, time in ipairs(stats.reactionTimes) do
        total = total + time
    end
    stats.averageReactionTime = total / #stats.reactionTimes
end

function StatisticsSystem:recordCatch(fishType, fightDuration)
    stats.totalCatches = stats.totalCatches + 1
    stats.totalFishCaught = stats.totalFishCaught + 1
    stats.consecutiveCatches = stats.consecutiveCatches + 1
    
    -- Update best streak
    if stats.consecutiveCatches > stats.bestStreak then
        stats.bestStreak = stats.consecutiveCatches
    end
    
    -- Record fish type
    if stats.fishCaughtByType[fishType] then
        stats.fishCaughtByType[fishType] = stats.fishCaughtByType[fishType] + 1
    end
    
    -- Record fight duration
    if fightDuration then
        if fightDuration > stats.longestFight then
            stats.longestFight = fightDuration
        end
        if fightDuration < stats.shortestFight then
            stats.shortestFight = fightDuration
        end
    end
end

function StatisticsSystem:recordLineBreak()
    stats.lineBreaks = stats.lineBreaks + 1
    stats.consecutiveCatches = 0 -- Reset streak
end

function StatisticsSystem:recordFishEscaped()
    stats.fishEscaped = stats.fishEscaped + 1
    stats.consecutiveCatches = 0 -- Reset streak
end

function StatisticsSystem:updatePlayTime()
    stats.totalPlayTime = love.timer.getTime() - stats.sessionStartTime
end

function StatisticsSystem:getCatchRate()
    if stats.totalCasts > 0 then
        return (stats.totalCatches / stats.totalCasts) * 100
    end
    return 0
end

function StatisticsSystem:getSuccessRate()
    local totalAttempts = stats.totalCatches + stats.lineBreaks + stats.fishEscaped
    if totalAttempts > 0 then
        return (stats.totalCatches / totalAttempts) * 100
    end
    return 0
end

function StatisticsSystem:getMostCaughtFish()
    local maxCount = 0
    local mostCaught = "none"
    
    for fishType, count in pairs(stats.fishCaughtByType) do
        if count > maxCount then
            maxCount = count
            mostCaught = fishType
        end
    end
    
    return mostCaught, maxCount
end

function StatisticsSystem:getMostUsedBait()
    local maxCount = 0
    local mostUsed = "none"
    
    for baitType, count in pairs(stats.baitUsed) do
        if count > maxCount then
            maxCount = count
            mostUsed = baitType
        end
    end
    
    return mostUsed, maxCount
end

function StatisticsSystem:getStatistics()
    self:updatePlayTime()
    
    local mostCaughtFish, fishCount = self:getMostCaughtFish()
    local mostUsedBait, baitCount = self:getMostUsedBait()
    
    return {
        totalCasts = stats.totalCasts,
        totalCatches = stats.totalCatches,
        lineBreaks = stats.lineBreaks,
        fishEscaped = stats.fishEscaped,
        bitesMissed = stats.bitesMissed,
        catchRate = self:getCatchRate(),
        successRate = self:getSuccessRate(),
        bestReactionTime = stats.bestReactionTime < 999 and stats.bestReactionTime or 0,
        worstReactionTime = stats.worstReactionTime,
        averageReactionTime = stats.averageReactionTime,
        totalPlayTime = stats.totalPlayTime,
        longestFight = stats.longestFight,
        shortestFight = stats.shortestFight < 999 and stats.shortestFight or 0,
        consecutiveCatches = stats.consecutiveCatches,
        bestStreak = stats.bestStreak,
        mostCaughtFish = mostCaughtFish,
        fishCount = fishCount,
        mostUsedBait = mostUsedBait,
        baitCount = baitCount,
        fishCaughtByType = stats.fishCaughtByType,
        baitUsed = stats.baitUsed
    }
end

function StatisticsSystem:printSessionSummary()
    local sessionStats = self:getStatistics()
    
    print("\n--- Fishing Session Summary ---")
    print("Total casts: " .. sessionStats.totalCasts)
    print("Total catches: " .. sessionStats.totalCatches)
    print("Catch rate: " .. string.format("%.1f%%", sessionStats.catchRate))
    print("Success rate: " .. string.format("%.1f%%", sessionStats.successRate))
    print("Best reaction time: " .. string.format("%.2fs", sessionStats.bestReactionTime))
    print("Current streak: " .. sessionStats.consecutiveCatches)
    print("Best streak: " .. sessionStats.bestStreak)
    print("Session time: " .. string.format("%.1f minutes", sessionStats.totalPlayTime / 60))
    
    if sessionStats.mostCaughtFish ~= "none" then
        print("Most caught fish: " .. sessionStats.mostCaughtFish .. " (" .. sessionStats.fishCount .. ")")
    end
end

return StatisticsSystem
