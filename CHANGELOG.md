# Changelog

## 2026-06-14

### Phase 4 — Social & Competitive ✅

**Server:**
- `ClubManager.lua` — Clubs (max 20 members), roles (owner/admin/member), invites, chat, stats
- `TournamentManager.lua` — Weekly tournaments ($10K fresh, 7-day cycle, separate DataStore)
- `Leaderboard.lua` — Global rankings by value/level, 5-min refresh, in-memory cache
- `CopyTrade.lua` — Sanitized portfolio sharing (15min delay, perk-gated)

**11 new RemoteFunctions:** CreateClub, JoinClub, LeaveClub, InviteToClub, KickFromClub, SendClubChat, GetClubInfo, GetTournamentEntry, ExecuteTournamentTrade, GetTournamentLeaderboard, GetGlobalLeaderboard, GetTopTraderPortfolio

**Client UI:**
- `ClubScreen.client.lua` — Full club panel: members, chat, stats (Press C)
- `LeaderboardScreen.client.lua` — Value/Level rankings, gold top-3 (Press L)

### Phase 3 — Advanced Trading ✅
Orders engine (limit/stop/take-profit), short selling (50% margin), candlestick charts (6 timeframes), NewsWidget

### Phase 2 — RPG & Progression ✅
XPManager (50 levels, 6 ranks), Perks (10), Missions (10 daily), OfficeManager (5 tiers), ProfileScreen UI

### Phase 1 — MVP ✅
Proxy (Express 5.2, 14 tests, Render deploy), Roblox trading core (20 Luau modules), MarketScreen + TradeWidget

### Published
- Roblox: https://www.roblox.com/games/10326856686 (pending public — new creator waiting period)
- Community: https://www.roblox.com/es/communities/173376366/TradeScape
- GitHub: https://github.com/FiveTechSoft/tradescape
- Proxy: https://tradescape-nxq0.onrender.com

### Renamed
TradeVille → TradeScape
