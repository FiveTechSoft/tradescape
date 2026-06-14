-- GameConfig.lua — Constants for TradeScape economy and configuration
-- Place in: ServerScriptService/GameConfig

local GameConfig = {}

-- Economy
GameConfig.STARTING_BALANCE = 10000
GameConfig.TRANSACTION_FEE_RATE = 0.001 -- 0.1% per trade
GameConfig.MIN_SHARES = 1
GameConfig.MAX_SHARES_PER_TRADE = 10000
GameConfig.MAX_SLOTS_BASE = 5 -- portfolio slots for level 1

-- Proxy
GameConfig.PROXY_URL = "https://your-proxy-url.com" -- CHANGE in production
GameConfig.PROXY_API_KEY = "tradescape-dev-key-change-me"
GameConfig.PROXY_TIMEOUT = 10 -- seconds
GameConfig.STALE_DATA_THRESHOLD = 120 -- seconds before showing "data unavailable"

-- Cache
GameConfig.QUOTE_CACHE_TTL = 60 -- seconds, server-side
GameConfig.MARKET_STATUS_CACHE_TTL = 60

-- DataStore
GameConfig.DATASTORE_NAME = "PlayerData"
GameConfig.SAVE_INTERVAL = 6 -- seconds, batch save
GameConfig.MAX_RETRIES = 3
GameConfig.RETRY_BACKOFF = {6, 12, 24} -- seconds per retry

-- UI
GameConfig.UI_REFRESH_INTERVAL = 2 -- seconds between UI updates
GameConfig.SPARKLINE_POINTS = 30 -- data points in mini chart

return GameConfig
