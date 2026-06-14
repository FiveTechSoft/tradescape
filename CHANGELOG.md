# Changelog

## 2026-06-14 — Full Game Built

### Phase 5 — Monetization (Cosmetic Only) ✅

**Shop:**
- `ShopManager.lua` — 6 products (extra slots, premium data, office skins, name color, verified badge)
- `MarketplaceService.ProcessReceipt` purchase verification
- `ShopScreen.client.lua` — Shop UI with Buy buttons + Theme picker (S key)

**Themes:**
- `ThemeManager.lua` — 5 themes: Bloomberg Dark, Light Mode, Matrix, Midnight Blue, Terminal Green
- Applied globally via `_G.ApplyTheme`

### Phase 4 — Social & Competitive ✅
Clubs (20 members, chat, stats), tournaments (weekly $10K), leaderboard (value/level), copy-trading (15min delay)

### Phase 3 — Advanced Trading ✅
Orders (limit/stop/take-profit), short selling (50% margin), candlestick charts (6 timeframes), NewsWidget

### Phase 2 — RPG & Progression ✅
XPManager (50 levels, 6 ranks), Perks (10), Missions (10 daily), OfficeManager (5 tiers), ProfileScreen UI

### Phase 1 — MVP ✅
Proxy (Express 5.2, 14 tests, Render deploy), trading core (buy/sell, portfolio, DataStore), MarketScreen + TradeWidget

### Published
- Roblox: https://www.roblox.com/games/10326856686 (pending public)
- Community: https://www.roblox.com/es/communities/173376366/TradeScape
- GitHub: https://github.com/FiveTechSoft/tradescape
- Proxy: https://tradescape-nxq0.onrender.com

### Stats
- 14 proxy tests ✅
- 30 Luau modules
- 25 RemoteFunctions
- 8 UI screens (Market, Trade, Profile, Chart, News, Club, Leaderboard, Shop)
- Keys: Tab=Profile, C=Club, L=Leaderboard, S=Shop
- 5 visual themes
- 5 implementation plans
- 1 comprehensive dev guide (howto.md)

### Renamed
TradeVille → TradeScape
