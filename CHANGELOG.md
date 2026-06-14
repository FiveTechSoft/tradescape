# Changelog

## 2026-06-14

### Phase 2 — RPG & Progression Complete ✅

**Server modules:**
- `XPManager.lua` — 50-level threshold table, rank system (Novato→Whale), XP calculation from trades
- `Perks.lua` — 10 perks (extra slots, short selling, limit orders, stop-loss, options, etc.), unlock logic with perk points
- `Missions.lua` — 10 mission definitions (first_buy, profit_100, survive_dip, diversify_3, etc.), daily rotation (3 per day), progress tracking, claim rewards
- `OfficeManager.lua` — Office visual progression (Phone→Laptop→Dual Screen→Multi Screen→Executive) based on net profit

**Integration:**
- `Economy.lua` updated — awards XP on trades, triggers mission progress, checks office upgrades
- `NetworkHandler.server.lua` updated — 6 new RemoteFunctions: GetXPProgress, GetAvailablePerks, UnlockPerk, GetDailyMissions, ClaimMission, GetOfficeInfo
- `GetInitialData` expanded to include RPG fields (level, rank, xp, perks, officeLevel)

**Client UI:**
- `ProfileScreen.client.lua` — XP bar with progress, level/rank display, Perks tab (unlock with perk points), Missions tab (track progress, claim rewards), Office info. Open with Tab key.

### Phase 1 — MVP Complete ✅

**Proxy (Node.js) — 14 tests passing**
- Express 5.2 server deployed on Render: `https://tradescape-nxq0.onrender.com`
- Yahoo Finance v3 API wrapper (quote, history, search, market-status)
- TTL cache layer, auth middleware, rate limiting
- Deploy config with PM2 + Nginx guide

**Roblox (Luau) — 14 modules**
- `GameConfig.lua`, `Types.lua`, `ProxyClient.lua`, `PlayerData.lua`
- `Economy.lua`, `Portfolio.lua`, `NetworkHandler.server.lua`
- `MarketScreen.client.lua`, `TradeWidget.client.lua`

**Published:**
- Roblox Experience: https://www.roblox.com/games/10326757850
- Community: https://www.roblox.com/es/communities/173376366/TradeScape
- GitHub: https://github.com/FiveTechSoft/tradescape

### Renamed
- TradeVille → TradeScape (Zynga "VILLE" trademark + TradeVille.ro brokerage conflict)
