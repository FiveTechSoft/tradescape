-- Economy.lua — Balance management, transaction validation, fees, stats
-- Place in: ServerScriptService/TradingService/Economy
--
-- All balance mutations go through this module.
-- No direct balance manipulation anywhere else.

local GameConfig = require(script.Parent.Parent.GameConfig)
local XPManager = require(script.Parent.XPManager)
local Missions = require(script.Parent.Missions)

local Economy = {}

-- ============================================================
-- Calculate transaction fee
-- ============================================================
function Economy.calculateFee(totalCost)
	return math.max(math.floor(totalCost * GameConfig.TRANSACTION_FEE_RATE), 0)
end

-- ============================================================
-- Check if player can afford a purchase
-- ============================================================
function Economy.canAfford(playerData, totalCost)
	local fee = Economy.calculateFee(totalCost)
	return playerData.balance >= (totalCost + fee), fee, totalCost + fee
end

-- ============================================================
-- Validate trade parameters
-- ============================================================
function Economy.validateTrade(playerData, quote, shares, tradeType)
	-- Type validation
	if tradeType ~= "buy" and tradeType ~= "sell" then
		return false, "Invalid trade type. Use 'buy' or 'sell'."
	end

	-- Shares validation
	shares = math.floor(shares)
	if shares < GameConfig.MIN_SHARES then
		return false, string.format("Minimum %d share per trade.", GameConfig.MIN_SHARES)
	end
	if shares > GameConfig.MAX_SHARES_PER_TRADE then
		return false, string.format("Maximum %d shares per trade.", GameConfig.MAX_SHARES_PER_TRADE)
	end

	-- Price validation
	if not quote or not quote.p or quote.p <= 0 then
		return false, "Invalid quote data. Try again."
	end

	-- Market status
	if quote.m and quote.m ~= "open" and quote.m ~= "pre" and quote.m ~= "post" then
		return false, string.format("Market is %s. Trading not available.", quote.m)
	end

	local totalCost = quote.p * shares

	if tradeType == "buy" then
		local canPay, fee, required = Economy.canAfford(playerData, totalCost)
		if not canPay then
			return false, string.format(
				"Not enough cash. Need $%.2f more. (Balance: $%.2f, Required: $%.2f incl. $%.0f fee)",
				required - playerData.balance,
				playerData.balance,
				required,
				fee
			)
		end

		-- Check portfolio slot limit
		local maxSlots = Economy.getMaxSlots(playerData)
		local currentPositions = 0
		for _ in pairs(playerData.positions) do
			currentPositions = currentPositions + 1
		end
		if playerData.positions[quote.s] == nil and currentPositions >= maxSlots then
			return false, string.format("Portfolio full. Max %d different stocks. Sell first or unlock more slots.", maxSlots)
		end

	elseif tradeType == "sell" then
		local position = playerData.positions[quote.s]
		if not position then
			return false, string.format("You don't own any %s.", quote.s)
		end
		if shares > position.shares then
			return false, string.format("You only have %d shares of %s.", position.shares, quote.s)
		end
	end

	return true, nil
end

-- ============================================================
-- Execute a buy
-- ============================================================
function Economy.executeBuy(playerData, quote, shares)
	local totalCost = quote.p * shares
	local fee = Economy.calculateFee(totalCost)
	local totalDeduction = totalCost + fee

	playerData.balance = playerData.balance - totalDeduction

	-- Update or create position
	local existing = playerData.positions[quote.s]
	if existing then
		local newShares = existing.shares + shares
		local newCost = existing.totalCost + totalCost
		existing.shares = newShares
		existing.avgPrice = newCost / newShares
		existing.totalCost = newCost
	else
		playerData.positions[quote.s] = {
			symbol = quote.s,
			shares = shares,
			avgPrice = quote.p,
			totalCost = totalCost,
			opened = os.time(),
		}
	end

	-- Record trade
	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = quote.s,
		type = "buy",
		shares = shares,
		price = quote.p,
		total = totalCost,
		fee = fee,
		balanceAfter = playerData.balance,
	})

	playerData.stats.totalTrades = playerData.stats.totalTrades + 1

	-- Trigger mission progress for buys
	Missions.onTradeCompleted(playerData, {
		type = "buy",
		symbol = quote.s,
		shares = shares,
	})

	return {
		success = true,
		message = string.format("Bought %d %s at $%.2f. Fee: $%.0f", shares, quote.s, quote.p, fee),
		newBalance = playerData.balance,
		position = playerData.positions[quote.s],
	}
end

-- ============================================================
-- Execute a sell
-- ============================================================
function Economy.executeSell(playerData, quote, shares)
	local totalValue = quote.p * shares
	local fee = Economy.calculateFee(totalValue)
	local totalReceived = totalValue - fee

	playerData.balance = playerData.balance + totalReceived

	local position = playerData.positions[quote.s]
	local profitLoss = (quote.p - position.avgPrice) * shares - fee

	position.shares = position.shares - shares
	if position.shares <= 0 then
		playerData.positions[quote.s] = nil
	else
		position.totalCost = position.totalCost * (position.shares / (position.shares + shares))
	end

	-- Record trade
	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = quote.s,
		type = "sell",
		shares = shares,
		price = quote.p,
		total = totalValue,
		fee = fee,
		profitLoss = profitLoss,
		balanceAfter = playerData.balance,
	})

	-- Update stats
	playerData.stats.totalTrades = playerData.stats.totalTrades + 1
	if profitLoss > 0 then
		playerData.stats.profitableTrades = playerData.stats.profitableTrades + 1
		playerData.stats.totalProfit = playerData.stats.totalProfit + profitLoss
		playerData.stats.currentStreak = playerData.stats.currentStreak + 1
		if playerData.stats.currentStreak > playerData.stats.bestStreak then
			playerData.stats.bestStreak = playerData.stats.currentStreak
		end
	else
		playerData.stats.totalLoss = playerData.stats.totalLoss + math.abs(profitLoss)
		playerData.stats.currentStreak = 0
	end

	-- Track best/worst
	if not playerData.stats.bestTrade or profitLoss > playerData.stats.bestTrade.profit then
		playerData.stats.bestTrade = { symbol = quote.s, profit = profitLoss }
	end
	if not playerData.stats.worstTrade or profitLoss < playerData.stats.worstTrade.loss then
		playerData.stats.worstTrade = { symbol = quote.s, loss = profitLoss }
	end

	-- RPG: award XP and update missions
	local profitPercent = 0
	if position.avgPrice > 0 and position.totalCost > 0 then
		profitPercent = (profitLoss / position.totalCost) * 100
	end
	local xpResult = XPManager.addXP(playerData, XPManager.calculateXP(profitLoss, profitPercent, profitLoss > 0))

	-- Trigger mission progress
	Missions.onTradeCompleted(playerData, {
		type = "sell",
		symbol = quote.s,
		profitLoss = profitLoss,
		shares = shares,
	})

	-- Check office upgrade
	local OfficeManager = require(script.Parent.OfficeManager)
	local officeResult = OfficeManager.updateOffice(playerData)

	-- Merge RPG results
	result.xpResult = xpResult
	result.officeResult = officeResult

	if xpResult.leveledUp then
		result.message = result.message .. string.format(" | ⬆ Level %d! (%s)", xpResult.newLevel, xpResult.newRank)
	end
	if officeResult.upgraded then
		result.message = result.message .. string.format(" | 🏢 Office: %s!", officeResult.newName)
	end

	return {
		success = true,
		message = string.format("Sold %d %s at $%.2f. %s $%.2f. Fee: $%.0f",
			shares, quote.s, quote.p,
			profitLoss >= 0 and "Profit:" or "Loss:",
			math.abs(profitLoss), fee),
		newBalance = playerData.balance,
		position = playerData.positions[quote.s],
		profitLoss = profitLoss,
	}
end

-- ============================================================
-- Trade history (keep last 500)
-- ============================================================
function Economy.recordTrade(playerData, trade)
	table.insert(playerData.tradeHistory, 1, trade)

	if #playerData.tradeHistory > 500 then
		local trimmed = {}
		for i = 1, 500 do
			trimmed[i] = playerData.tradeHistory[i]
		end
		playerData.tradeHistory = trimmed
	end
end

-- ============================================================
-- Portfolio slot calculation
-- ============================================================
function Economy.getMaxSlots(playerData)
	local slots = GameConfig.MAX_SLOTS_BASE
	for _, perk in ipairs(playerData.perks) do
		if perk == "extra_slot_1" then
			slots = slots + 1
		elseif perk == "extra_slot_2" then
			slots = slots + 3
		end
	end
	return slots
end

return Economy
