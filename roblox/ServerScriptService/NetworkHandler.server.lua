-- NetworkHandler.server.lua — RemoteFunction handlers for client-server communication
-- Place in: ServerScriptService/NetworkHandler (Script, not ModuleScript)
--
-- Handles: GetQuote, ExecuteTrade, GetPortfolio, SearchSymbols, GetInitialData
-- Uses RemoteFunctions in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Require server modules
local ProxyClient = require(script.Parent.ProxyClient)
local Economy = require(script.Parent.TradingService.Economy)
local Portfolio = require(script.Parent.TradingService.Portfolio)
local PlayerData = require(script.Parent.DataStore.PlayerData)
local XPManager = require(script.Parent.TradingService.XPManager)
local Perks = require(script.Parent.TradingService.Perks)
local Missions = require(script.Parent.TradingService.Missions)
local OfficeManager = require(script.Parent.TradingService.OfficeManager)

-- Loaded players (in-memory, synced to DataStore periodically)
local activePlayers = {}

-- ============================================================
-- RemoteFunctions setup
-- ============================================================
local NetworkEvents = Instance.new("Folder")
NetworkEvents.Name = "NetworkEvents"
NetworkEvents.Parent = ReplicatedStorage

local function createRemoteFunction(name)
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = NetworkEvents
	return rf
end

local GetQuote = createRemoteFunction("GetQuote")
local ExecuteTrade = createRemoteFunction("ExecuteTrade")
local GetPortfolio = createRemoteFunction("GetPortfolio")
local SearchSymbols = createRemoteFunction("SearchSymbols")
local GetInitialData = createRemoteFunction("GetInitialData")
local GetXPProgress = createRemoteFunction("GetXPProgress")
local GetAvailablePerks = createRemoteFunction("GetAvailablePerks")
local UnlockPerk = createRemoteFunction("UnlockPerk")
local GetDailyMissions = createRemoteFunction("GetDailyMissions")
local ClaimMission = createRemoteFunction("ClaimMission")
local GetOfficeInfo = createRemoteFunction("GetOfficeInfo")

-- ============================================================
-- GetQuote — fetch current quote for a symbol
-- ============================================================
GetQuote.OnServerInvoke = function(player, symbol)
	local data = activePlayers[player.UserId]
	if not data then
		return nil, "not_loaded"
	end

	return ProxyClient.getQuote(symbol)
end

-- ============================================================
-- ExecuteTrade — buy or sell shares
-- ============================================================
ExecuteTrade.OnServerInvoke = function(player, tradeType, symbol, shares)
	local data = activePlayers[player.UserId]
	if not data then
		return { success = false, message = "Player data not loaded. Rejoin." }
	end

	symbol = symbol:upper()
	shares = math.floor(tonumber(shares) or 0)

	-- Fetch latest quote
	local quote = ProxyClient.getQuote(symbol)
	if not quote then
		return { success = false, message = "Could not fetch current price. Try again." }
	end

	-- Validate
	local valid, errMsg = Economy.validateTrade(data, quote, shares, tradeType)
	if not valid then
		return { success = false, message = errMsg }
	end

	-- Execute
	local result
	if tradeType == "buy" then
		result = Economy.executeBuy(data, quote, shares)
	else
		result = Economy.executeSell(data, quote, shares)
	end

	-- Queue save
	PlayerData.queueSave(data)

	return result
end

-- ============================================================
-- GetPortfolio — return player's current portfolio + P&L
-- ============================================================
GetPortfolio.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then
		return nil, "not_loaded"
	end

	return Portfolio.calculateValue(data)
end

-- ============================================================
-- SearchSymbols — search for stock symbols
-- ============================================================
SearchSymbols.OnServerInvoke = function(player, query)
	return ProxyClient.search(query)
end

-- ============================================================
-- GetInitialData — called on player join, returns full profile
-- ============================================================
GetInitialData.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then
		return nil
	end

	return {
		balance = data.balance,
		level = data.level or 1,
		rank = data.rank or "Novato",
		xp = data.xp or 0,
		stats = data.stats or {},
		officeLevel = data.officeLevel or 0,
		positions = data.positions or {},
		perks = data.perks or {},
	}
end

-- ============================================================
-- GetXPProgress — returns XP, level, progress bar data
-- ============================================================
GetXPProgress.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return nil end
	data.xp = data.xp or 0
	return XPManager.getXPProgress(data.xp)
end

-- ============================================================
-- GetAvailablePerks — list perks player can unlock
-- ============================================================
GetAvailablePerks.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return nil end
	return Perks.getAvailablePerks(data)
end

-- ============================================================
-- UnlockPerk — spend perk points to unlock a perk
-- ============================================================
UnlockPerk.OnServerInvoke = function(player, perkId)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end
	local ok, msg = Perks.unlockPerk(data, perkId)
	PlayerData.queueSave(data)
	return { success = ok, message = msg }
end

-- ============================================================
-- GetDailyMissions — get today's 3 missions
-- ============================================================
GetDailyMissions.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return nil end
	return Missions.getDailyMissions(data)
end

-- ============================================================
-- ClaimMission — claim mission reward
-- ============================================================
ClaimMission.OnServerInvoke = function(player, missionId)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end
	local ok, msg = Missions.claimMission(data, missionId)
	if ok then
		PlayerData.queueSave(data)
	end
	return { success = ok, message = msg }
end

-- ============================================================
-- GetOfficeInfo — office level and progress
-- ============================================================
GetOfficeInfo.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return nil end
	return OfficeManager.getOfficeInfo(data)
end

-- ============================================================
-- Player lifecycle
-- ============================================================
local function onPlayerAdded(player)
	local userId = player.UserId

	-- Load from DataStore
	local data = PlayerData.load(userId)
	if not data then
		data = PlayerData.createDefault(userId)
		PlayerData.queueSave(data)
	end

	activePlayers[userId] = data
	print("[NetworkHandler] Loaded player", player.Name, "Balance:", data.balance)
end

local function onPlayerRemoving(player)
	local userId = player.UserId
	local data = activePlayers[userId]
	if data then
		PlayerData.forceSave(data)
		activePlayers[userId] = nil
		print("[NetworkHandler] Saved player", player.Name)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ============================================================
-- Save loop — batch persistence every heartbeat
-- ============================================================
RunService.Heartbeat:Connect(function()
	PlayerData.processQueue()
end)

print("[NetworkHandler] TradeScape server initialized")
