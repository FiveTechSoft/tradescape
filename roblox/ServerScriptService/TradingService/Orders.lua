-- Orders.lua — Limit, stop-loss, take-profit order management
-- Place in: ServerScriptService/TradingService/Orders

local ProxyClient = require(script.Parent.Parent.ProxyClient)
local Economy = require(script.Parent.Economy)

local Orders = {}

-- Order lifetime: 90 days default (GTC = Good Till Cancelled)
local ORDER_MAX_AGE = 90 * 86400

function Orders.generateId()
	return "ord_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
end

-- Create a new order
function Orders.createOrder(playerData, orderType, symbol, qty, targetPrice)
	if not playerData.orders then
		playerData.orders = {}
	end

	-- Validate order type
	local validTypes = { limit_buy = true, limit_sell = true, stop_loss = true, take_profit = true }
	if not validTypes[orderType] then
		return false, "Invalid order type"
	end

	-- For stop_loss and take_profit, verify player has the position
	if orderType == "stop_loss" or orderType == "take_profit" then
		local pos = playerData.positions and playerData.positions[symbol]
		if not pos then
			return false, "You don't own " .. symbol
		end
		if (pos.shares or 0) < qty then
			return false, string.format("Only have %d shares", pos.shares)
		end
	end

	-- For limit_buy, check balance (approximate — just validate has SOME reasonable balance)
	if orderType == "limit_buy" then
		local estimatedCost = targetPrice * qty
		local fee = Economy.calculateFee(estimatedCost)
		if playerData.balance < (estimatedCost * 0.1) then -- At least 10% to be reasonable
			return false, "Insufficient balance for this order"
		end
	end

	local order = {
		id = Orders.generateId(),
		type = orderType,
		symbol = symbol:upper(),
		qty = qty,
		price = targetPrice,
		created = os.time(),
		expires = os.time() + ORDER_MAX_AGE,
		status = "pending", -- pending, filled, cancelled, expired
	}

	table.insert(playerData.orders, order)
	return true, "Order created", order
end

-- Cancel an order
function Orders.cancelOrder(playerData, orderId)
	for i, order in ipairs(playerData.orders or {}) do
		if order.id == orderId and order.status == "pending" then
			table.remove(playerData.orders, i)
			return true, "Order cancelled"
		end
	end
	return false, "Order not found or already executed"
end

-- Get pending orders
function Orders.getPendingOrders(playerData)
	local pending = {}
	for _, order in ipairs(playerData.orders or {}) do
		if order.status == "pending" then
			table.insert(pending, order)
		end
	end
	return pending
end

-- Process orders — called every 10s by server loop
-- Checks if any pending order's conditions are met
function Orders.processOrders(playerData)
	if not playerData.orders then return {} end

	local filled = {}
	local now = os.time()

	for _, order in ipairs(playerData.orders) do
		if order.status == "pending" then
			-- Check expiry
			if order.expires and now > order.expires then
				order.status = "expired"
			else
				-- Get current price
				local quote = ProxyClient.getQuote(order.symbol)
				if quote and quote.p then
					local currentPrice = quote.p
					local shouldExecute = false

					if order.type == "limit_buy" and currentPrice <= order.price then
						shouldExecute = true
					elseif order.type == "limit_sell" and currentPrice >= order.price then
						shouldExecute = true
					elseif order.type == "stop_loss" and currentPrice <= order.price then
						shouldExecute = true
					elseif order.type == "take_profit" and currentPrice >= order.price then
						shouldExecute = true
					end

					if shouldExecute then
						local tradeType = "buy"
						if order.type == "limit_sell" or order.type == "stop_loss" or order.type == "take_profit" then
							tradeType = "sell"
						end

						local result
						if tradeType == "buy" then
							result = Economy.executeBuy(playerData, quote, order.qty)
						else
							result = Economy.executeSell(playerData, quote, order.qty)
						end

						if result.success then
							order.status = "filled"
							order.filledAt = currentPrice
							order.filledTimestamp = now
							table.insert(filled, {
								order = order,
								result = result,
							})
						end
					end
				end
			end
		end
	end

	return filled
end

return Orders
