-- Portfolio.lua — Portfolio calculations and queries
-- Place in: ServerScriptService/TradingService/Portfolio
--
-- Read-only portfolio operations (P&L, total value, etc.)
-- Trades are executed through Economy module.

local ProxyClient = require(script.Parent.Parent.ProxyClient)

local Portfolio = {}

-- ============================================================
-- Calculate current value and P&L for all positions
-- ============================================================
function Portfolio.calculateValue(playerData)
	local totalValue = playerData.balance
	local totalCost = 0
	local totalProfit = 0
	local positions = {}

	for symbol, pos in pairs(playerData.positions) do
		local quote = ProxyClient.getQuote(symbol)

		if quote then
			local currentValue = quote.p * pos.shares
			local profitLoss = currentValue - pos.totalCost
			local profitPercent = 0
			if pos.totalCost > 0 then
				profitPercent = (profitLoss / pos.totalCost) * 100
			end

			positions[symbol] = {
				symbol = symbol,
				name = quote.n,
				shares = pos.shares,
				avgPrice = pos.avgPrice,
				totalCost = pos.totalCost,
				currentPrice = quote.p,
				currentValue = currentValue,
				profitLoss = profitLoss,
				profitPercent = profitPercent,
				change = quote.c,
				changePercent = quote.cp,
				opened = pos.opened,
			}

			totalValue = totalValue + currentValue
			totalCost = totalCost + pos.totalCost
			totalProfit = totalProfit + profitLoss
		else
			-- Data unavailable, use last known cost as fallback
			positions[symbol] = {
				symbol = symbol,
				shares = pos.shares,
				avgPrice = pos.avgPrice,
				totalCost = pos.totalCost,
				currentPrice = nil,
				currentValue = pos.totalCost,
				profitLoss = 0,
				profitPercent = 0,
				change = 0,
				changePercent = 0,
				opened = pos.opened,
				stale = true,
			}

			totalValue = totalValue + pos.totalCost
		end
	end

	local totalProfitPercent = 0
	if totalCost > 0 then
		totalProfitPercent = (totalProfit / totalCost) * 100
	end

	return {
		balance = playerData.balance,
		positions = positions,
		totalValue = totalValue,
		totalCost = totalCost,
		totalProfit = totalProfit,
		totalProfitPercent = totalProfitPercent,
	}
end

-- ============================================================
-- Get simple portfolio summary (lightweight, for leaderboard)
-- ============================================================
function Portfolio.getSummary(playerData)
	local data = Portfolio.calculateValue(playerData)
	local count = 0
	for _ in pairs(data.positions) do count = count + 1 end

	return {
		userId = playerData.userId,
		balance = data.balance,
		totalValue = data.totalValue,
		totalProfit = data.totalProfit,
		totalProfitPercent = data.totalProfitPercent,
		positionCount = count,
	}
end

return Portfolio
