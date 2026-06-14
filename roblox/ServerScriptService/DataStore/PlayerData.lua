-- PlayerData.lua — DataStore persistence for player profiles
-- Place in: ServerScriptService/DataStore/PlayerData
--
-- Batch-writes player data to avoid DataStore throttling.
-- Retries with exponential backoff on failure.

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(script.Parent.Parent.GameConfig)

local PlayerData = {}

local store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)

-- Write queue: { [userId] = data }
local writeQueue = {}
local lastSave = 0

-- ============================================================
-- Create default profile for new player
-- ============================================================
function PlayerData.createDefault(userId)
	return {
		userId = userId,
		created = os.time(),

		-- Economy
		balance = GameConfig.STARTING_BALANCE,
		totalDeposited = GameConfig.STARTING_BALANCE,

		-- Portfolio
		positions = {}, -- { [symbol] = Position }

		-- History (MVP: last 500 trades at most)
		tradeHistory = {},

		-- Stats
		stats = {
			totalTrades = 0,
			profitableTrades = 0,
			totalProfit = 0,
			totalLoss = 0,
			bestTrade = nil,  -- { symbol, profit }
			worstTrade = nil, -- { symbol, loss }
			currentStreak = 0,
			bestStreak = 0,
		},

		-- RPG (minimal for MVP, expanded in Phase 2)
		xp = 0,
		level = 1,
		rank = "Novato",
		perks = {},
		completedMissions = {},
		officeLevel = 0,
	}
end

-- ============================================================
-- Load player data
-- ============================================================
function PlayerData.load(userId)
	local key = "player_" .. tostring(userId)

	local success, data = pcall(function()
		return store:GetAsync(key)
	end)

	if success and data then
		return data
	end

	return nil
end

-- ============================================================
-- Queue save (batched to respect DataStore limits)
-- ============================================================
function PlayerData.queueSave(data)
	writeQueue[data.userId] = data
end

-- ============================================================
-- Process the write queue (call on a loop every SAVE_INTERVAL)
-- ============================================================
function PlayerData.processQueue()
	local now = os.time()
	if now - lastSave < GameConfig.SAVE_INTERVAL then
		return
	end

	lastSave = now
	local toSave = {}

	-- Drain queue
	for userId, data in pairs(writeQueue) do
		toSave[userId] = data
		writeQueue[userId] = nil
	end

	-- Save all with retry
	for userId, data in pairs(toSave) do
		local saved = false
		for attempt = 1, GameConfig.MAX_RETRIES do
			local success, err = pcall(function()
				local key = "player_" .. tostring(userId)
				store:SetAsync(key, data)
			end)

			if success then
				saved = true
				break
			else
				warn("[PlayerData] Save failed for", userId, "attempt", attempt, ":", err)
				-- Wait with exponential backoff
				task.wait(GameConfig.RETRY_BACKOFF[attempt])
			end
		end

		if not saved then
			warn("[PlayerData] CRITICAL: Failed to save data for", userId, "after all retries. Re-queueing.")
			writeQueue[userId] = data
		end
	end
end

-- ============================================================
-- Force immediate save (use sparingly, e.g. on player leave)
-- ============================================================
function PlayerData.forceSave(data)
	local key = "player_" .. tostring(data.userId)
	local success, err = pcall(function()
		store:SetAsync(key, data)
	end)

	if not success then
		warn("[PlayerData] Force save failed for", data.userId, ":", err)
	end

	return success
end

return PlayerData
