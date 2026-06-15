-- OptionsManager.lua — Simplified options trading (calls/puts)
-- Requires "options_basic" perk (level 25+). Educational, not full options chain.

local ProxyClient = require(script.Parent.Parent.ProxyClient)
local Economy = require(script.Parent.Economy)

local OptionsManager = {}

-- Contract types
-- call: right to BUY at strike price — profit if stock goes UP
-- put:  right to SELL at strike price — profit if stock goes DOWN
--
-- Simplified pricing: premium = intrinsic + time value
-- Strike prices: ±5%, ±10%, ±20% from current price

function OptionsManager.getAvailableStrikes(symbol)
	local quote = ProxyClient.getQuote(symbol)
	if not quote or not quote.p then return {} end

	local currentPrice = quote.p
	local strikes = {}
	local percentages = { -0.20, -0.10, -0.05, 0, 0.05, 0.10, 0.20 }

	for _, pct in ipairs(percentages) do
		local strike = math.floor(currentPrice * (1 + pct) * 100) / 100
		local expiry = os.time() + (7 * 86400) -- 7 days expiration
		local daysToExpiry = 7

		-- Simplified Black-Scholes: intrinsic + time premium
		local intrinsicCall = math.max(0, currentPrice - strike)
		local intrinsicPut = math.max(0, strike - currentPrice)
		local timePremium = currentPrice * 0.02 * (daysToExpiry / 365) * 100

		table.insert(strikes, {
			strike = strike,
			expiry = expiry,
			daysToExpiry = daysToExpiry,
			callPremium = math.max(0.01, math.floor((intrinsicCall + timePremium) * 100) / 100),
			putPremium = math.max(0.01, math.floor((intrinsicPut + timePremium) * 100) / 100),
		})
	end

	return strikes, currentPrice, quote.n
end

-- Buy an option contract (1 contract = 100 shares notional, simplified)
function OptionsManager.buyOption(playerData, symbol, optionType, strike, premium)
	local totalCost = premium * 100 -- 1 contract = 100 shares notional
	local fee = Economy.calculateFee(totalCost)

	if playerData.balance < (totalCost + fee) then
		return false, string.format("Need $%.2f. (Have $%.2f)", totalCost + fee, playerData.balance)
	end

	playerData.balance = playerData.balance - totalCost - fee

	-- Store option position
	if not playerData.options then playerData.options = {} end
	table.insert(playerData.options, {
		symbol = symbol:upper(),
		type = optionType, -- "call" or "put"
		strike = strike,
		premium = premium,
		shares = 100,
		opened = os.time(),
		expiry = os.time() + (7 * 86400),
		status = "open",
	})

	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = symbol,
		type = "option_" .. optionType,
		shares = 100,
		price = premium,
		total = totalCost,
		fee = fee,
		balanceAfter = playerData.balance,
	})

	return true, string.format("Bought %s %s $%.0f @ $%.2f x100",
		symbol, optionType == "call" and "Call" or "Put", strike, premium)
end

-- Exercise or sell option early (before expiry)
function OptionsManager.exerciseOption(playerData, optionIndex)
	if not playerData.options or not playerData.options[optionIndex] then
		return false, "Option not found"
	end

	local opt = playerData.options[optionIndex]
	if opt.status ~= "open" then
		return false, "Option already closed"
	end

	local quote = ProxyClient.getQuote(opt.symbol)
	if not quote or not quote.p then
		return false, "Cannot get current price"
	end

	local currentPrice = quote.p
	local profit = 0

	if opt.type == "call" then
		profit = math.max(0, (currentPrice - opt.strike) * opt.shares - (opt.premium * opt.shares))
	else -- put
		profit = math.max(0, (opt.strike - currentPrice) * opt.shares - (opt.premium * opt.shares))
	end

	playerData.balance = playerData.balance + profit

	local fee = Economy.calculateFee(profit)
	playerData.balance = playerData.balance - fee

	opt.status = "exercised"
	opt.exercisePrice = currentPrice
	opt.exerciseProfit = profit
	opt.exercisedAt = os.time()

	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = opt.symbol,
		type = "option_exercise",
		shares = 100,
		price = currentPrice,
		profitLoss = profit,
		fee = fee,
		balanceAfter = playerData.balance,
	})

	if profit > 0 then
		return true, string.format("Exercised! Profit: $%.2f", profit)
	else
		return true, "Option expired worthless (out of the money)"
	end
end

function OptionsManager.getPlayerOptions(playerData)
	return playerData.options or {}
end

return OptionsManager
