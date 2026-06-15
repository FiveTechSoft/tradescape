-- ProxyClient.lua — HttpService wrapper for TradeScape proxy API
-- Place in: ServerScriptService/ProxyClient
--
-- Provides cached, rate-limited access to market data proxy.
-- Handles stale cache fallback when proxy is unreachable.

local HttpService = game:GetService("HttpService")
local GameConfig = require(script.Parent.GameConfig)

local ProxyClient = {}

-- In-memory server cache: { [symbol] = { data = Quote, updated = os.time() } }
local quoteCache = {}
local marketStatusCache = nil
local marketStatusUpdated = 0

-- ============================================================
-- Quote
-- ============================================================
function ProxyClient.getQuotes(symbols)
	local cacheKey = table.concat(symbols, ",")
	local cached = getCached("quote", cacheKey)
	if cached then return cached end

	local ok, result = pcall(function()
		local url = string.format("%s/api/quotes", GameConfig.PROXY_URL)
		local body = HttpService:JSONEncode({ symbols = symbols })
		return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if decodeOk and data and data.quotes then
			local map = {}
			for _, q in ipairs(data.quotes) do
				if q.s then
					quoteCache[q.s] = { data = q, updated = os.time() }
					map[q.s] = q
				end
			end
			return map
		end
	end

	-- Fallback: fetch one by one
	local map = {}
	for _, sym in ipairs(symbols) do
		local q = ProxyClient.getQuote(sym)
		if q then map[sym] = q end
	end
	return map
end

function ProxyClient.getQuote(symbol)
	symbol = symbol:upper()

	-- Check cache
	local cached = quoteCache[symbol]
	if cached and (os.time() - cached.updated) < GameConfig.QUOTE_CACHE_TTL then
		return cached.data
	end

	-- Fetch from proxy
	local ok, result = pcall(function()
		local url = string.format("%s/api/quote/%s", GameConfig.PROXY_URL, symbol)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if not decodeOk or not data then
			warn("[ProxyClient] Failed to decode quote response for", symbol)
			if cached then
				cached.data.stale = true
				return cached.data
			end
			return nil, "decode_error", "Invalid response from proxy"
		end
		if data.error then
			warn("[ProxyClient] Quote error for", symbol, ":", data.message)
			-- Return stale if available
			if cached then
				cached.data.stale = true
				return cached.data
			end
			return nil, data.error, data.message
		end

		quoteCache[symbol] = { data = data, updated = os.time() }
		return data
	end

	-- Network error — return stale data if available
	if cached and (os.time() - cached.updated) < GameConfig.STALE_DATA_THRESHOLD then
		warn("[ProxyClient] Using stale data for", symbol)
		cached.data.stale = true
		return cached.data
	end

	return nil, "proxy_unavailable", "Market data temporarily unavailable"
end

-- ============================================================
-- History
-- ============================================================
function ProxyClient.getHistory(symbol, range)
	symbol = symbol:upper()
	range = range or "1m"

	local ok, result = pcall(function()
		local url = string.format("%s/api/history/%s?range=%s",
			GameConfig.PROXY_URL, symbol, range)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if not decodeOk or not data then
			warn("[ProxyClient] Failed to decode history response for", symbol)
			return nil, "decode_error"
		end
		if data.error then
			warn("[ProxyClient] History error for", symbol, ":", data.error)
			return nil, data.error
		end
		return data.d -- return just the candle array
	end

	return nil, "proxy_unavailable"
end

-- ============================================================
-- Search
-- ============================================================
function ProxyClient.search(query)
	local ok, result = pcall(function()
		local url = string.format("%s/api/search?q=%s", GameConfig.PROXY_URL, query)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if not decodeOk or not data then
			return {}
		end
		if data.error then
			return {}
		end
		return data.r
	end

	return {}
end

-- ============================================================
-- Market Status
-- ============================================================
function ProxyClient.getMarketStatus()
	-- Check cache
	if marketStatusCache and (os.time() - marketStatusUpdated) < GameConfig.MARKET_STATUS_CACHE_TTL then
		return marketStatusCache
	end

	local ok, result = pcall(function()
		local url = string.format("%s/api/market-status", GameConfig.PROXY_URL)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if decodeOk and data then
			marketStatusCache = data
			marketStatusUpdated = os.time()
			return marketStatusCache
		end
	end

	-- Return cached even if stale
	if marketStatusCache then
		return marketStatusCache
	end

	return nil
end

-- ============================================================
-- Cache management
-- ============================================================
function ProxyClient.invalidateQuote(symbol)
	quoteCache[symbol:upper()] = nil
end

function ProxyClient.invalidateAll()
	quoteCache = {}
	marketStatusCache = nil
	marketStatusUpdated = 0
end

-- ============================================================
-- News
-- ============================================================
function ProxyClient.getNews(symbol)
	symbol = symbol:upper()

	local ok, result = pcall(function()
		local url = string.format("%s/api/news/%s", GameConfig.PROXY_URL, symbol)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if decodeOk and data then
			return data.n or {}
		end
	end

	return {}
end

function ProxyClient.getMarketNews()
	local ok, result = pcall(function()
		local url = string.format("%s/api/news", GameConfig.PROXY_URL)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local decodeOk, data = pcall(function()
			return HttpService:JSONDecode(result)
		end)
		if decodeOk and data then
			return data.n or {}
		end
	end

	return {}
end

return ProxyClient
