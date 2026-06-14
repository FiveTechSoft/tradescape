-- TournamentManager.lua — Weekly trading tournaments
-- Separate $10K portfolio, pure skill, 7-day cycle

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local TournamentManager = {}

local tourneyStore = DataStoreService:GetDataStore("Tournaments")
local STARTING_BALANCE = 10000
local DURATION = 7 * 86400 -- 7 days

-- Get current tournament week number
function TournamentManager.getCurrentWeek()
	return math.floor(os.time() / DURATION)
end

-- Get or create tournament entry for a player
function TournamentManager.getEntry(userId)
	local week = TournamentManager.getCurrentWeek()
	local key = "week_" .. week .. "_player_" .. userId

	local ok, data = pcall(function()
		return tourneyStore:GetAsync(key)
	end)

	if ok and data then
		return data
	end

	-- Create new entry
	local newEntry = {
		userId = userId,
		week = week,
		balance = STARTING_BALANCE,
		positions = {},
		tradeCount = 0,
		started = os.time(),
	}

	pcall(function()
		tourneyStore:SetAsync(key, newEntry)
	end)

	return newEntry
end

-- Save tournament entry
function TournamentManager.saveEntry(entry)
	local key = "week_" .. entry.week .. "_player_" .. entry.userId
	pcall(function()
		tourneyStore:SetAsync(key, entry)
	end)
end

-- Get tournament leaderboard (top 50 by profit %)
function TournamentManager.getLeaderboard()
	local week = TournamentManager.getCurrentWeek()
	-- For MVP, return placeholder — full implementation needs ordered datastore
	-- In production, cache leaderboard and update periodically
	return { week = week, entries = {} }
end

return TournamentManager
