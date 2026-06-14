-- XPManager.lua — XP calculation, level thresholds, rank names
-- Place in: ServerScriptService/TradingService/XPManager

local XPManager = {}

-- Level thresholds (XP required to reach each level)
local LEVELS = {
	0,     -- level 1
	100,   -- level 2
	250,   -- level 3
	500,   -- level 4
	800,   -- level 5 (Trader)
	1200,  -- level 6
	1700,  -- level 7
	2300,  -- level 8
	3000,  -- level 9
	4000,  -- level 10 (Broker)
	5200,  -- level 11
	6600,  -- level 12
	8200,  -- level 13
	10000, -- level 14
	12000, -- level 15 (Broker II)
	15000, -- level 16
	18500, -- level 17
	22500, -- level 18
	27000, -- level 19
	32000, -- level 20
	38000, -- level 21
	45000, -- level 22
	53000, -- level 23
	62000, -- level 24
	72000, -- level 25 (Magnate)
	85000, -- level 26
	100000,-- level 27
	120000,-- level 28
	140000,-- level 29
	165000,-- level 30
	195000,-- level 31
	230000,-- level 32
	270000,-- level 33
	315000,-- level 34
	365000,-- level 35
	420000,-- level 36
	480000,-- level 37
	545000,-- level 38
	615000,-- level 39
	690000,-- level 40
	770000,-- level 41
	855000,-- level 42
	945000,-- level 43
	1040000,-- level 44
	1140000,-- level 45
	1250000,-- level 46
	1370000,-- level 47
	1500000,-- level 48
	1650000,-- level 49
	2000000,-- level 50 (Whale)
}

-- Rank names
local RANKS = {
	[1] = "Novato",
	[5] = "Trader",
	[10] = "Broker",
	[15] = "Broker II",
	[25] = "Magnate",
	[50] = "Whale",
}

function XPManager.getLevel(xp)
	for level = #LEVELS, 1, -1 do
		if xp >= LEVELS[level] then
			return level
		end
	end
	return 1
end

function XPManager.getRank(level)
	local rank = "Novato"
	for threshold, name in pairs(RANKS) do
		if level >= threshold then
			rank = name
		end
	end
	return rank
end

function XPManager.getXPForLevel(level)
	return LEVELS[level] or 0
end

function XPManager.getXPProgress(xp)
	local currentLevel = XPManager.getLevel(xp)
	local currentLevelXP = LEVELS[currentLevel] or 0
	local nextLevel = math.min(currentLevel + 1, #LEVELS)
	local nextLevelXP = LEVELS[nextLevel] or currentLevelXP

	return {
		currentLevel = currentLevel,
		currentLevelXP = currentLevelXP,
		nextLevelXP = nextLevelXP,
		totalXP = xp,
		progress = (xp - currentLevelXP) / math.max(nextLevelXP - currentLevelXP, 1),
		rank = XPManager.getRank(currentLevel),
	}
end

-- Calculate XP from a trade
function XPManager.calculateXP(profit, profitPercent, isWin)
	local xp = 0
	if isWin then
		xp = math.floor(profitPercent * 10)
		xp = math.max(xp, 5)
		if profit >= 1000 then xp = xp + 20 end
		if profit >= 10000 then xp = xp + 100 end
	else
		xp = math.floor(profitPercent * 3)
		xp = math.max(xp, -20)
	end
	return xp
end

-- Award XP to player, handle level-ups
function XPManager.addXP(playerData, amount)
	playerData.xp = playerData.xp + amount
	if playerData.xp < 0 then
		playerData.xp = 0
	end

	local newLevel = XPManager.getLevel(playerData.xp)
	local oldLevel = playerData.level or 1

	if newLevel > oldLevel then
		playerData.level = newLevel
		playerData.rank = XPManager.getRank(newLevel)
		return {
			leveledUp = true,
			oldLevel = oldLevel,
			newLevel = newLevel,
			newRank = playerData.rank,
			perkPointsGained = newLevel - oldLevel,
		}
	elseif newLevel < oldLevel then
		playerData.level = newLevel
		playerData.rank = XPManager.getRank(newLevel)
	end

	return { leveledUp = false }
end

-- Perk points available
function XPManager.getAvailablePerkPoints(playerData)
	local spent = 0
	for _, perk in ipairs(playerData.perks or {}) do
		-- Perk data is { name = "perk_id", cost = N }
		spent = spent + (perk.cost or 0)
	end
	return playerData.level - spent
end

return XPManager
