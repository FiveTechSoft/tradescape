-- Missions.lua — Daily mission definitions and progress tracking
-- Place in: ServerScriptService/TradingService/Missions

local Missions = {}

-- Mission definitions
local MISSION_DEFS = {
	first_buy = {
		name = "First Trade",
		description = "Buy your first stock",
		rewardXP = 50,
		oneTime = true,
	},
	profit_any = {
		name = "In The Green",
		description = "Close a trade with profit",
		rewardXP = 30,
		oneTime = false,
	},
	profit_100 = {
		name = "Daily Earner",
		description = "Earn $100 or more today",
		rewardXP = 75,
		oneTime = false,
	},
	survive_dip = {
		name = "Diamond Hands",
		description = "Hold a position through a -3% drop without selling",
		rewardXP = 40,
		oneTime = false,
	},
	diversify_3 = {
		name = "Diversified",
		description = "Hold positions in 3 different sectors",
		rewardXP = 60,
		oneTime = false,
	},
	hold_3days = {
		name = "Patient Investor",
		description = "Hold a stock for 3 days without selling",
		rewardXP = 100,
		oneTime = false,
	},
	big_win = {
		name = "Big Winner",
		description = "Earn $500+ on a single trade",
		rewardXP = 150,
		oneTime = false,
	},
	comeback = {
		name = "Comeback Kid",
		description = "Recover from a >$200 loss with a later profit",
		rewardXP = 200,
		oneTime = false,
	},
	streak_3 = {
		name = "Hot Streak",
		description = "Win 3 trades in a row",
		rewardXP = 80,
		oneTime = false,
	},
	trade_5 = {
		name = "Active Trader",
		description = "Execute 5 trades today",
		rewardXP = 50,
		oneTime = false,
	},
}

function Missions.getDailyMissions(playerData)
	local completed = {}
	if playerData.completedMissions then
		for _, id in ipairs(playerData.completedMissions) do
			completed[id] = true
		end
	end

	local daily = {}
	for id, def in pairs(MISSION_DEFS) do
		if not def.oneTime or not completed[id] then
			local progress = 0
			local target = 1
			if playerData.missionProgress and playerData.missionProgress[id] then
				progress = playerData.missionProgress[id].progress or 0
				target = playerData.missionProgress[id].target or 1
			end
			table.insert(daily, {
				id = id,
				name = def.name,
				description = def.description,
				rewardXP = def.rewardXP,
				oneTime = def.oneTime,
				progress = progress,
				target = target,
				done = completed[id] or progress >= target,
			})
		end
	end

	-- Show 3 random missions (or all if <= 3)
	if #daily > 3 then
		-- Simple shuffle and take 3
		math.randomseed(os.time())
		for i = #daily, 2, -1 do
			local j = math.random(i)
			daily[i], daily[j] = daily[j], daily[i]
		end
		local selected = {}
		for i = 1, 3 do
			table.insert(selected, daily[i])
		end
		return selected
	end

	return daily
end

function Missions.updateProgress(playerData, missionId, progress)
	if not playerData.missionProgress then
		playerData.missionProgress = {}
	end

	if not playerData.missionProgress[missionId] then
		playerData.missionProgress[missionId] = { progress = 0, target = 1 }
	end

	playerData.missionProgress[missionId].progress =
		math.min((playerData.missionProgress[missionId].progress or 0) + progress,
			playerData.missionProgress[missionId].target)
end

function Missions.claimMission(playerData, missionId)
	local def = MISSION_DEFS[missionId]
	if not def then
		return false, "Unknown mission"
	end

	local completed = {}
	if playerData.completedMissions then
		for _, id in ipairs(playerData.completedMissions) do
			completed[id] = true
		end
	end

	if def.oneTime and completed[missionId] then
		return false, "Already completed"
	end

	-- Check progress
	local prog = playerData.missionProgress and playerData.missionProgress[missionId]
	if not prog or prog.progress < prog.target then
		return false, "Mission not complete"
	end

	-- Award XP
	playerData.xp = (playerData.xp or 0) + def.rewardXP

	-- Mark complete
	if def.oneTime then
		if not playerData.completedMissions then
			playerData.completedMissions = {}
		end
		table.insert(playerData.completedMissions, missionId)
	end

	-- Reset progress for repeatable missions
	if not def.oneTime then
		if playerData.missionProgress and playerData.missionProgress[missionId] then
			playerData.missionProgress[missionId].progress = 0
		end
	end

	return true, string.format("%s completed! +%d XP", def.name, def.rewardXP)
end

-- Trigger progress updates based on game events
function Missions.onTradeCompleted(playerData, tradeResult)
	-- "first_buy" and "profit_any" and "trade_5"
	if tradeResult.type == "buy" then
		Missions.updateProgress(playerData, "first_buy", 1)
	end

	Missions.updateProgress(playerData, "trade_5", 1)

	if tradeResult.profitLoss and tradeResult.profitLoss > 0 then
		Missions.updateProgress(playerData, "profit_any", 1)

		-- "profit_100": track cumulative daily profit
		Missions.updateProgress(playerData, "profit_100", tradeResult.profitLoss)

		-- "big_win": single trade profit > $500
		if tradeResult.profitLoss >= 500 then
			Missions.updateProgress(playerData, "big_win", 1)
		end
	end

	-- "streak_3": check streak
	local stats = playerData.stats
	if stats and stats.currentStreak >= 3 then
		Missions.updateProgress(playerData, "streak_3", 1)
	end
end

return Missions
