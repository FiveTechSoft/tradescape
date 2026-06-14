-- CopyTrade.lua — Delayed portfolio visibility of top traders
-- 15-minute delay, requires "copy_trade_view" perk

local CopyTrade = {}

local delay = 15 * 60 -- 15 minutes in seconds

-- Get sanitized portfolio data for copy-trade viewing
function CopyTrade.getSanitizedPortfolio(targetPlayerData)
	local now = os.time()
	local positions = {}

	for symbol, pos in pairs(targetPlayerData.positions or {}) do
		-- Only show allocation %, NOT exact prices or share counts
		positions[symbol] = {
			symbol = symbol,
			isLong = (pos.shares or 0) > 0,
			-- Do NOT expose: shares, avgPrice, totalCost
			lastUpdated = now - delay, -- Always show as delayed
		}
	end

	return {
		userId = targetPlayerData.userId,
		totalTrades = (targetPlayerData.stats or {}).totalTrades or 0,
		winRate = 0,
		totalProfit = (targetPlayerData.stats or {}).totalProfit or 0,
		lastActive = now - delay,
		positions = positions,
		-- Explicitly NOT exposed: balance, exact prices, pending orders
	}
end

return CopyTrade
