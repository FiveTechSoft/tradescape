-- NetworkHandler.server.lua — RemoteFunction handlers for client-server communication
-- Place in: ServerScriptService/NetworkHandler (Script, not ModuleScript)
--
-- Handles: GetQuote, ExecuteTrade, GetPortfolio, SearchSymbols, GetInitialData
-- Uses RemoteFunctions in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Require server modules
local ProxyClient = require(script.Parent.ProxyClient)
local Economy = require(script.Parent.TradingService.Economy)
local Portfolio = require(script.Parent.TradingService.Portfolio)

-- DataStore modules may fail in local Studio testing
local PlayerData_ok, PlayerData = pcall(require, script.Parent.DataStore.PlayerData)
local XPManager = require(script.Parent.TradingService.XPManager)
local Perks = require(script.Parent.TradingService.Perks)
local Missions = require(script.Parent.TradingService.Missions)
local OfficeManager = require(script.Parent.TradingService.OfficeManager)
local Orders = require(script.Parent.TradingService.Orders)

local ClubManager_ok, ClubManager = pcall(require, script.Parent.TradingService.ClubManager)
local TournamentManager_ok, TournamentManager = pcall(require, script.Parent.TradingService.TournamentManager)
local Leaderboard_ok, Leaderboard = pcall(require, script.Parent.DataStore.Leaderboard)
local CopyTrade = require(script.Parent.TradingService.CopyTrade)
local ShopManager = require(script.Parent.TradingService.ShopManager)
local ThemeManager = require(script.Parent.TradingService.ThemeManager)
local OptionsManager = require(script.Parent.TradingService.OptionsManager)
local EventManager_ok, EventManager = pcall(require, script.Parent.TradingService.EventManager)
local SeasonManager_ok, SeasonManager = pcall(require, script.Parent.TradingService.SeasonManager)

if not PlayerData_ok then warn("[NetworkHandler] PlayerData load failed:", PlayerData) end
if not ClubManager_ok then warn("[NetworkHandler] ClubManager load failed:", ClubManager) end
if not TournamentManager_ok then warn("[NetworkHandler] TournamentManager load failed:", TournamentManager) end
if not Leaderboard_ok then warn("[NetworkHandler] Leaderboard load failed:", Leaderboard) end
if not EventManager_ok then warn("[NetworkHandler] EventManager load failed:", EventManager) end
if not SeasonManager_ok then warn("[NetworkHandler] SeasonManager load failed:", SeasonManager) end

-- Stub DataStore-dependent modules for local testing
local function noop(...) return {} end
if not PlayerData_ok then
	PlayerData = { load = noop, createDefault = function() return { balance = 10000, positions = {}, perks = {}, stats = { totalTrades = 0, profitableTrades = 0, totalProfit = 0, totalLoss = 0, currentStreak = 0, bestStreak = 0 }, xp = 0, level = 1, rank = "Novato", tradeHistory = {}, completedMissions = {}, officeLevel = 0 } end, queueSave = noop, forceSave = noop, processQueue = noop }
end
if not ClubManager_ok then ClubManager = { createClub = noop, loadClub = noop, saveClub = noop, invite = noop, acceptInvite = noop, leaveClub = noop, kick = noop, sendChat = noop, updateStats = noop } end
if not TournamentManager_ok then TournamentManager = { getEntry = noop, getLeaderboard = function() return { entries = {} } end } end
if not Leaderboard_ok then Leaderboard = { getByValue = function() return {} end, getByLevel = function() return {} end, refresh = noop } end
if not EventManager_ok then EventManager = { getActiveEvent = noop, joinEvent = noop, getMarketMood = function() return "neutral" end, checkEvents = noop } end
if not SeasonManager_ok then SeasonManager = { getSeasonStats = noop } end

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
local GetQuotes = createRemoteFunction("GetQuotes")
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

-- Shop & Themes
local GetShopItems = createRemoteFunction("GetShopItems")
local GetTheme = createRemoteFunction("GetTheme")
local SetTheme = createRemoteFunction("SetTheme")

-- Options
local GetOptionStrikes = createRemoteFunction("GetOptionStrikes")
local BuyOption = createRemoteFunction("BuyOption")
local ExerciseOption = createRemoteFunction("ExerciseOption")
local GetMyOptions = createRemoteFunction("GetMyOptions")

-- Events
local GetActiveEvent = createRemoteFunction("GetActiveEvent")
local JoinEvent = createRemoteFunction("JoinEvent")
local GetMarketMood = createRemoteFunction("GetMarketMood")

-- Seasons
local GetSeasonStats = createRemoteFunction("GetSeasonStats")

-- News
local GetSymbolNews = createRemoteFunction("GetSymbolNews")
local GetMarketNews = createRemoteFunction("GetMarketNews")

-- ============================================================
-- GetQuote — fetch current quote for a symbol
-- ============================================================
GetQuote.OnServerInvoke = function(player, symbol)
	return ProxyClient.getQuote(symbol)
end

-- ============================================================
-- GetQuotes — fetch multiple quotes in one call (batch)
-- ============================================================
GetQuotes.OnServerInvoke = function(player, symbols)
	if type(symbols) ~= "table" then return {} end
	return ProxyClient.getQuotes(symbols)
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
		return {
			balance = 10000,
			positions = {},
			totalValue = 10000,
			totalCost = 0,
			totalProfit = 0,
			totalProfitPercent = 0,
		}
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
		return {
			balance = 10000,
			level = 1,
			rank = "Novato",
			xp = 0,
			stats = {},
			officeLevel = 0,
			positions = {},
			perks = {},
		}
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

	if not Perks.hasPerk(data, "copy_trade_view") then
		return nil, "Requires copy_trade_view perk"
	end

	local targetData = activePlayers[targetUserId]
	if not targetData then return nil end

	return CopyTrade.getSanitizedPortfolio(targetData)
end

-- ============================================================
-- SHOP & THEMES
-- ============================================================
GetShopItems.OnServerInvoke = function(player)
	return ShopManager.getProducts()
end

GetTheme.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return "dark" end
	return data.theme or "dark"
end

SetTheme.OnServerInvoke = function(player, themeId)
	local data = activePlayers[player.UserId]
	if not data then return false end
	data.theme = themeId
	PlayerData.queueSave(data)
	return true
end

-- ============================================================
-- OPTIONS
-- ============================================================
GetOptionStrikes.OnServerInvoke = function(player, symbol)
	local data = activePlayers[player.UserId]
	if not data then return nil end

	if not Perks.hasPerk(data, "options_basic") then
		return nil, "Requires Options Basic perk (level 25+)"
	end

	return OptionsManager.getAvailableStrikes(symbol)
end

BuyOption.OnServerInvoke = function(player, symbol, optionType, strike, premium)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	if not Perks.hasPerk(data, "options_basic") then
		return { success = false, message = "Requires level 25+ and Options Basic perk" }
	end

	local ok, msg = OptionsManager.buyOption(data, symbol, optionType, strike, premium)
	if ok then PlayerData.queueSave(data) end
	return { success = ok, message = msg }
end

ExerciseOption.OnServerInvoke = function(player, optionIndex)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end

	local ok, msg = OptionsManager.exerciseOption(data, optionIndex)
	if ok then PlayerData.queueSave(data) end
	return { success = ok, message = msg }
end

GetMyOptions.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return {} end
	return OptionsManager.getPlayerOptions(data)
end

-- ============================================================
-- EVENTS
-- ============================================================
GetActiveEvent.OnServerInvoke = function(player)
	return EventManager.getActiveEvent()
end

JoinEvent.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then return { success = false, message = "Not loaded" } end
	return { success = EventManager.joinEvent(player.UserId, data) }
end

GetMarketMood.OnServerInvoke = function(player)
	return EventManager.getMarketMood()
end

-- ============================================================
-- SEASONS
-- ============================================================
GetSeasonStats.OnServerInvoke = function(player)
	return SeasonManager.getSeasonStats(player.UserId)
end

-- ============================================================
-- NEWS
-- ============================================================
GetSymbolNews.OnServerInvoke = function(player, symbol)
	return ProxyClient.getNews(symbol)
end

GetMarketNews.OnServerInvoke = function(player)
	return ProxyClient.getMarketNews()
end

-- Purchase verification (process receipt from Roblox)
-- This is called automatically by Roblox when a purchase completes
local function onPurchaseComplete(player, productId)
	local data = activePlayers[player.UserId]
	if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local product = ShopManager.processPurchase(player, productId)
	if product then
		local ok = ShopManager.grantProduct(data, productId)
		if ok then
			PlayerData.queueSave(data)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = onPurchaseComplete

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

	EventManager.checkEvents()
end)

print("[NetworkHandler] TradeScape server initialized")
