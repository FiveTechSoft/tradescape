-- Leaderboard.lua — Global rankings: value, profit%, level
-- Refreshed every 5 minutes, cached in memory

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(script.Parent.Parent.GameConfig)

local Leaderboard = {}

-- In-memory cache
local cachedLeaderboard = {
	byValue = {},      -- top 100 by total value
	byProfit = {},     -- top 100 by weekly profit %
	byLevel = {},      -- top 100 by level + XP
	updated = 0,
}

local CACHE_TTL = 300 -- 5 minutes

function Leaderboard.getByValue()
	if os.time() - cachedLeaderboard.updated < CACHE_TTL then
		return cachedLeaderboard.byValue
	end
	return cachedLeaderboard.byValue -- Return cached even if stale
end

function Leaderboard.getByProfit()
	return cachedLeaderboard.byProfit
end

function Leaderboard.getByLevel()
	return cachedLeaderboard.byLevel
end

-- Update all leaderboards (called by server every 5 min)
function Leaderboard.refresh(activePlayers)
	-- Build rankings from active player data
	local entries = {}
	for userId, data in pairs(activePlayers) do
		local totalValue = data.balance or 0
		for _, pos in pairs(data.positions or {}) do
			totalValue = totalValue + (pos.totalCost or 0)
		end

		table.insert(entries, {
			userId = userId,
			totalValue = totalValue,
			totalProfit = (data.stats or {}).totalProfit or 0,
			totalProfitPercent = 0, -- calculated from totalCost vs totalValue
			level = data.level or 1,
			xp = data.xp or 0,
			rank = data.rank or "Novato",
			winRate = (data.stats or {}).profitableTrades or 0,
		})
	end

	-- Sort by value (desc)
	table.sort(entries, function(a, b) return a.totalValue > b.totalValue end)
	local byValue = {}
	for i = 1, math.min(100, #entries) do
		byValue[i] = entries[i]
	end

	-- Sort by level
	local byLevel = {}
	for i, e in ipairs(entries) do byLevel[i] = e end
	table.sort(byLevel, function(a, b)
		if a.level == b.level then return a.xp > b.xp end
		return a.level > b.level
	end)
	local topLevel = {}
	for i = 1, math.min(100, #byLevel) do
		topLevel[i] = byLevel[i]
	end

	cachedLeaderboard = {
		byValue = byValue,
		byProfit = byValue, -- TODO: calculate by profit %
		byLevel = topLevel,
		updated = os.time(),
	}
end

return Leaderboard
