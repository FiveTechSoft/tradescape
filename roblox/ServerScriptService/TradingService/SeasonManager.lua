-- SeasonManager.lua — Monthly optional seasonal resets

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(script.Parent.Parent.GameConfig)

local SeasonManager = {}
local seasonStore = DataStoreService:GetDataStore("Seasons")

-- Seasons are monthly. Each season has its own leaderboard.
function SeasonManager.getCurrentSeason()
	local now = os.time()
	local year = os.date("*t", now).year
	local month = os.date("*t", now).month
	return string.format("%d-%02d", year, month)
end

function SeasonManager.getSeasonStats(userId)
	local season = SeasonManager.getCurrentSeason()
	local key = "season_" .. season .. "_player_" .. userId

	local ok, data = pcall(function()
		return seasonStore:GetAsync(key)
	end)
	if ok and data then return data end

	return {
		userId = userId,
		season = season,
		startingBalance = GameConfig.STARTING_BALANCE,
		highestBalance = GameConfig.STARTING_BALANCE,
		totalTrades = 0,
		totalProfit = 0,
		joined = os.time(),
	}
end

function SeasonManager.updateSeasonStats(userId, playerData)
	local season = SeasonManager.getCurrentSeason()
	local stats = SeasonManager.getSeasonStats(userId)

	stats.highestBalance = math.max(stats.highestBalance, playerData.balance or 0)
	stats.totalTrades = (stats.totalTrades or 0) + 1
	stats.totalProfit = (playerData.stats or {}).totalProfit or 0

	local key = "season_" .. season .. "_player_" .. userId
	pcall(function()
		seasonStore:SetAsync(key, stats)
	end)
end

return SeasonManager
