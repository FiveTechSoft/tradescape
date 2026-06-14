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
local Orders = require(script.Parent.TradingService.Orders)
local ClubManager = require(script.Parent.TradingService.ClubManager)
local TournamentManager = require(script.Parent.TradingService.TournamentManager)
local Leaderboard = require(script.Parent.DataStore.Leaderboard)
local CopyTrade = require(script.Parent.TradingService.CopyTrade)

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
local CreateOrder = createRemoteFunction("CreateOrder")
local CancelOrder = createRemoteFunction("CancelOrder")
local GetOrders = createRemoteFunction("GetOrders")
local ShortSell = createRemoteFunction("ShortSell")
local CoverShort = createRemoteFunction("CoverShort")

-- Club
local CreateClub = createRemoteFunction("CreateClub")
local JoinClub = createRemoteFunction("JoinClub")
local LeaveClub = createRemoteFunction("LeaveClub")
local InviteToClub = createRemoteFunction("InviteToClub")
local KickFromClub = createRemoteFunction("KickFromClub")
local SendClubChat = createRemoteFunction("SendClubChat")
local GetClubInfo = createRemoteFunction("GetClubInfo")

-- Tournament
local GetTournamentEntry = createRemoteFunction("GetTournamentEntry")
local ExecuteTournamentTrade = createRemoteFunction("ExecuteTournamentTrade")
local GetTournamentLeaderboard = createRemoteFunction("GetTournamentLeaderboard")

-- Leaderboard
local GetGlobalLeaderboard = createRemoteFunction("GetGlobalLeaderboard")

-- Copy trade
local GetTopTraderPortfolio = createRemoteFunction("GetTopTraderPortfolio")

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
-- CreateOrder — place a limit/stop/take-profit order
-- ============================================================
CreateOrder.OnServerInvoke = function(player, orderType, symbol, qty, targetPrice)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	-- Check perk requirements
	local perkMap = {
		limit_buy = "limit_orders",
		limit_sell = "limit_orders",
		stop_loss = "stop_loss",
		take_profit = "take_profit",
	}
	local requiredPerk = perkMap[orderType]
	if requiredPerk and not Perks.hasPerk(data, requiredPerk) then
		return { success = false, message = "Perk not unlocked: " .. requiredPerk }
	end

	local ok, msg = Orders.createOrder(data, orderType, symbol, qty, targetPrice)
	PlayerData.queueSave(data)
	return { success = ok, message = msg }
end

-- ============================================================
-- CancelOrder — cancel a pending order
-- ============================================================
CancelOrder.OnServerInvoke = function(player, orderId)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	local ok, msg = Orders.cancelOrder(data, orderId)
	if ok then PlayerData.queueSave(data) end
	return { success = ok, message = msg }
end

-- ============================================================
-- GetOrders — get all pending orders
-- ============================================================
GetOrders.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return {} end
	return Orders.getPendingOrders(data)
end

-- ============================================================
-- ShortSell — execute a short sale (requires short_selling perk)
-- ============================================================
ShortSell.OnServerInvoke = function(player, symbol, shares)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	if not Perks.hasPerk(data, "short_selling") then
		return { success = false, message = "Short selling requires level 5 + Short Selling perk" }
	end

	symbol = symbol:upper()
	shares = math.floor(tonumber(shares) or 0)

	local quote = ProxyClient.getQuote(symbol)
	if not quote then
		return { success = false, message = "Could not fetch price" }
	end

	local valid, errMsg = Economy.validateShortSell(data, quote, shares)
	if not valid then
		return { success = false, message = errMsg }
	end

	local result = Economy.executeShortSell(data, quote, shares)
	PlayerData.queueSave(data)
	return result
end

-- ============================================================
-- CoverShort — buy back to close a short position
-- ============================================================
CoverShort.OnServerInvoke = function(player, symbol, shares)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	symbol = symbol:upper()
	shares = math.floor(tonumber(shares) or 0)

	local quote = ProxyClient.getQuote(symbol)
	if not quote then
		return { success = false, message = "Could not fetch price" }
	end

	local result = Economy.executeCover(data, quote, shares)
	PlayerData.queueSave(data)
	return result
end

-- ============================================================
-- CLUBS
-- ============================================================
CreateClub.OnServerInvoke = function(player, clubName)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end
	if data.clubId then return { success = false, message = "Already in a club: " .. (data.clubName or "") } end

	local ok, msg, clubId = ClubManager.createClub(player.UserId, clubName)
	if ok then
		data.clubId = clubId
		data.clubRole = "owner"
		data.clubName = clubName
		PlayerData.queueSave(data)
	end
	return { success = ok, message = msg, clubId = clubId }
end

GetClubInfo.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data or not data.clubId then return nil end

	local club = ClubManager.loadClub(data.clubId)
	if club then
		ClubManager.updateStats(club, activePlayers)
		ClubManager.saveClub(club)
	end
	return club
end

InviteToClub.OnServerInvoke = function(player, targetUserId)
	local data = activePlayers[player.UserId]
	if not data or not data.clubId then return { success = false, message = "Not in a club" } end

	local club = ClubManager.loadClub(data.clubId)
	if not club then return { success = false, message = "Club not found" } end

	local ok, msg = ClubManager.invite(club, player.UserId, targetUserId)
	if ok then ClubManager.saveClub(club) end
	return { success = ok, message = msg }
end

JoinClub.OnServerInvoke = function(player, clubId)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end
	if data.clubId then return { success = false, message = "Already in a club" } end

	local club = ClubManager.loadClub(clubId)
	if not club then return { success = false, message = "Club not found" } end

	local ok, msg = ClubManager.acceptInvite(club, player.UserId)
	if ok then
		ClubManager.saveClub(club)
		data.clubId = clubId
		data.clubRole = "member"
		data.clubName = club.name
		PlayerData.queueSave(data)
	end
	return { success = ok, message = msg }
end

LeaveClub.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data or not data.clubId then return { success = false, message = "Not in a club" } end

	local club = ClubManager.loadClub(data.clubId)
	if club then
		ClubManager.leaveClub(club, player.UserId)
		ClubManager.saveClub(club)
	end
	data.clubId = nil
	data.clubRole = nil
	data.clubName = nil
	PlayerData.queueSave(data)
	return { success = true, message = "Left club" }
end

KickFromClub.OnServerInvoke = function(player, targetUserId)
	local data = activePlayers[player.UserId]
	if not data or not data.clubId then return { success = false, message = "Not in a club" } end

	local club = ClubManager.loadClub(data.clubId)
	if not club then return { success = false, message = "Club not found" } end

	local ok, msg = ClubManager.kick(club, player.UserId, targetUserId)
	if ok then ClubManager.saveClub(club) end
	return { success = ok, message = msg }
end

SendClubChat.OnServerInvoke = function(player, message)
	local data = activePlayers[player.UserId]
	if not data or not data.clubId then return { success = false, message = "Not in a club" } end

	local club = ClubManager.loadClub(data.clubId)
	if not club then return { success = false, message = "Club not found" } end

	local chat = ClubManager.sendChat(club, player.UserId, player.Name, message)
	ClubManager.saveClub(club)
	return chat
end

-- ============================================================
-- TOURNAMENT
-- ============================================================
GetTournamentEntry.OnServerInvoke = function(player)
	return TournamentManager.getEntry(player.UserId)
end

ExecuteTournamentTrade.OnServerInvoke = function(player, tradeType, symbol, shares)
	-- Simplified for MVP: same as regular trade but on tournament balance
	local entry = TournamentManager.getEntry(player.UserId)
	-- TODO: full tournament trading logic (Phase 4.5)
	return { success = false, message = "Tournament trading coming soon" }
end

GetTournamentLeaderboard.OnServerInvoke = function(player)
	return TournamentManager.getLeaderboard()
end

-- ============================================================
-- LEADERBOARD
-- ============================================================
GetGlobalLeaderboard.OnServerInvoke = function(player, category)
	category = category or "value"
	if category == "value" then return Leaderboard.getByValue() end
	if category == "level" then return Leaderboard.getByLevel() end
	return Leaderboard.getByValue()
end

-- ============================================================
-- COPY TRADE
-- ============================================================
GetTopTraderPortfolio.OnServerInvoke = function(player, targetUserId)
	local data = activePlayers[player.UserId]
	if not data then return nil end

	local Perks = require(script.Parent.TradingService.Perks)
	if not Perks.hasPerk(data, "copy_trade_view") then
		return nil, "Requires copy_trade_view perk"
	end

	local targetData = activePlayers[targetUserId]
	if not targetData then return nil end

	return CopyTrade.getSanitizedPortfolio(targetData)
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
-- Track last order processing time
local lastOrderProcess = 0
local lastLeaderboardRefresh = 0

RunService.Heartbeat:Connect(function()
	PlayerData.processQueue()

	-- Process orders every 10 seconds
	local now = os.time()
	if now - lastOrderProcess >= 10 then
		lastOrderProcess = now
		for userId, data in pairs(activePlayers) do
			local filled = Orders.processOrders(data)
			if #filled > 0 then
				PlayerData.queueSave(data)
			end
		end
	end

	if now - lastLeaderboardRefresh >= 300 then
		lastLeaderboardRefresh = now
		Leaderboard.refresh(activePlayers)
	end
end)

print("[NetworkHandler] TradeScape server initialized")
