# Changelog

## 2026-06-14

### Phase 3 — Advanced Trading Complete ✅

**Orders:**
- `Orders.lua` — Limit buy/sell, stop-loss, take-profit; 10s matching loop; 90-day GTC; auto-execute via Economy
- 5 new RemoteFunctions: CreateOrder, CancelOrder, GetOrders, ShortSell, CoverShort
- Perk-gated (limit_orders, stop_loss, take_profit, short_selling)

**Short selling:**
- `Economy.validateShortSell` — 50% margin requirement
- `Economy.executeShortSell` — Negative share positions, margin tracking
- `Economy.executeCover` — Buy-back with profit/loss calculation

**Charts:**
- `ChartView.client.lua` — Candlestick rendering with wicks, volume bars, price axis
- Timeframe selector: 1D, 1W, 1M, 3M, 6M, 1Y
- Exposed via `_G.ShowChart(symbol, historyData)`

**News:**
- `NewsWidget.client.lua` — Context-sensitive "Why did it move?" panel
- Educational tips based on price move magnitude

### Phase 2 — RPG & Progression Complete ✅

**Server:** XPManager (50 levels, 6 ranks), Perks (10 perks), Missions (10 missions, daily rotation), OfficeManager (5 levels)
**Client:** ProfileScreen UI — XP bar, perks tab, missions tab, office info (Tab key)

### Phase 1 — MVP Complete ✅

**Proxy:** Express 5.2 on Render (`tradescape-nxq0.onrender.com`), Yahoo Finance v3, 14 tests
**Roblox:** 14 Luau modules, trading + portfolio + market UI
**Published:** https://www.roblox.com/games/10326856686 (pending public)

### Renamed
- TradeVille → TradeScape (Zynga "VILLE" trademark + TradeVille.ro brokerage conflict)
