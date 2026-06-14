# Changelog

## 2026-06-14

### Phase 1 — MVP Complete ✅

**Proxy (Node.js) — 14 tests passing**
- Express 5.2 server with ESM modules
- Yahoo Finance v3 API wrapper (quote, history, search, market-status)
- TTL cache layer (node-cache, separate instances per data type)
- Auth middleware (X-API-Key header validation)
- Rate limit middleware (sliding window, configurable)
- Endpoints: `/api/quote/:symbol`, `/api/history/:symbol`, `/api/search?q=`, `/api/market-status`, `/api/news/:symbol`
- Health check: `/health`
- Deploy guide with PM2 + Nginx

**Roblox (Luau) — 9 modules**
- `GameConfig.lua` — Constants (balance, fees, proxy URL, cache TTLs)
- `Types.lua` — Shared Luau type definitions (Quote, Position, TradeResult, etc.)
- `ProxyClient.lua` — HttpService wrapper with server-side cache + stale fallback
- `PlayerData.lua` — DataStore persistence with batch writes + exponential backoff
- `Economy.lua` — Buy/sell execution, validation, fees, stats, trade history
- `Portfolio.lua` — P&L calculation, portfolio valuation with live quotes
- `NetworkHandler.server.lua` — 5 RemoteFunctions, player lifecycle, save loop
- `MarketScreen.client.lua` — Stock watchlist UI with live 2s refresh
- `TradeWidget.client.lua` — Buy/sell modal with quantity input + confirmation

**Design docs**
- `docs/superpowers/specs/2026-06-14-tradescape-design.md`
- `docs/superpowers/plans/2026-06-14-tradescape-phase-1.md`
- `roadmap.md` — 6-phase roadmap with progress tracking
- `proxy/deploy.md` — VPS deployment guide

### Renamed
- TradeVille → TradeScape (Zynga "VILLE" trademark + TradeVille.ro brokerage conflict)

### Registered
- GitHub: https://github.com/FiveTechSoft/tradescape
- Roblox Community: https://www.roblox.com/es/communities/173376366/TradeScape
