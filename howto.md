# TradeScape — Development Guide

> Roblox Trading RPG with real global market data.
> Built June 14, 2026. 4 phases complete.
> GitHub: https://github.com/FiveTechSoft/tradescape

---

## Quick Resume

```bash
# Rebuild Roblox place file
/c/Users/Anto/AppData/Local/Microsoft/WinGet/Packages/Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe/rojo.exe build -o tradescape.rbxlx

# Run proxy tests
cd proxy && npm test

# Start proxy locally
cd proxy && npm run dev

# Open in Roblox Studio (Windows)
$studioExe = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Recurse -Filter "RobloxStudioBeta.exe" | Select-Object -First 1
Start-Process $studioExe.FullName -ArgumentList "C:\pipe\tradescape.rbxlx"
```

---

## Project Structure

```
c:\pipe/
├── howto.md                          # This file — dev guide
├── CHANGELOG.md                       # All changes by phase
├── README.md                          # Public project overview
├── roadmap.md                         # 6-phase roadmap with progress
├── default.project.json               # Rojo project config
├── render.yaml                        # Render deploy config
├── .gitignore                         # node_modules, .env, Roblox files
│
├── proxy/                             # Node.js backend
│   ├── package.json                   # Express 5.2, yahoo-finance2 3.15, node-cache
│   ├── .env.example                   # Environment template (API_KEY, PORT, etc.)
│   ├── .env                           # Local env (gitignored, has real API key)
│   ├── deploy.md                      # VPS deployment guide (PM2 + Nginx)
│   ├── src/
│   │   ├── index.js                   # Express entry — mounts all routes + middleware
│   │   ├── cache.js                   # node-cache wrapper (5 TTL instances)
│   │   ├── services/
│   │   │   └── yahoo.js              # Yahoo Finance v3 API (getQuote, getHistory, search, marketStatus)
│   │   ├── middleware/
│   │   │   ├── auth.js               # X-API-Key header validation
│   │   │   └── rateLimit.js          # Sliding window rate limiter (configurable)
│   │   └── routes/
│   │       ├── quote.js              # GET /api/quote/:symbol (cache 60s)
│   │       ├── history.js            # GET /api/history/:symbol?range=1m|3m|6m|1y (cache 300s)
│   │       ├── search.js             # GET /api/search?q= (cache 3600s)
│   │       ├── marketStatus.js       # GET /api/market-status (cache 60s)
│   │       └── news.js               # GET /api/news/:symbol (cache 300s)
│   └── tests/
│       ├── middleware.test.js         # Auth + rate limit tests
│       ├── quote.test.js             # Quote endpoint tests
│       ├── history.test.js           # History endpoint tests
│       ├── search.test.js            # Search endpoint tests
│       └── marketStatus.test.js      # Market status tests
│
├── roblox/                            # Roblox Luau source
│   ├── ServerScriptService/
│   │   ├── GameConfig.lua            # Constants (balance, proxy URL, fees, cache TTLs)
│   │   ├── ProxyClient.lua           # HttpService wrapper + server-side cache + stale fallback
│   │   ├── NetworkHandler.server.lua  # ALL RemoteFunctions + player lifecycle + loops
│   │   ├── TradingService/
│   │   │   ├── Economy.lua           # Buy, sell, short, cover, fees, validation, stats
│   │   │   ├── Portfolio.lua         # P&L calculation, portfolio valuation
│   │   │   ├── Orders.lua            # Limit/stop/take-profit orders, 10s matching loop
│   │   │   ├── XPManager.lua         # XP calculation, 50-level thresholds, ranks
│   │   │   ├── Perks.lua             # 10 perk definitions, unlock logic
│   │   │   ├── Missions.lua          # 10 missions, daily rotation, progress, claims
│   │   │   ├── OfficeManager.lua     # Office tier progression (profit thresholds)
│   │   │   ├── ClubManager.lua       # Club CRUD, members, roles, chat, stats
│   │   │   ├── TournamentManager.lua # Weekly tournaments, separate $10K portfolios
│   │   │   └── CopyTrade.lua         # Sanitized delayed portfolio sharing
│   │   └── DataStore/
│   │       ├── PlayerData.lua        # DataStore persistence + batch writes + retry
│   │       └── Leaderboard.lua       # Global rankings cache (5min refresh)
│   ├── ReplicatedStorage/
│   │   └── Types.lua                 # Shared Luau type definitions
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── UI/
│               ├── MarketScreen.client.lua    # Watchlist (16 symbols, 2s refresh)
│               ├── TradeWidget.client.lua     # Buy/sell modal
│               ├── ProfileScreen.client.lua   # XP bar, perks, missions (Tab key)
│               ├── ChartView.client.lua       # Candlestick chart, timeframes
│               ├── NewsWidget.client.lua      # "Why did it move?" panel
│               ├── ClubScreen.client.lua      # Club panel (C key)
│               └── LeaderboardScreen.client.lua # Rankings (L key)
│
└── docs/superpowers/
    ├── specs/
    │   └── 2026-06-14-tradescape-design.md    # Full game design spec
    └── plans/
        ├── 2026-06-14-tradescape-phase-1.md   # MVP: proxy + trading core
        ├── 2026-06-14-tradescape-phase-2.md   # RPG: levels, perks, missions
        ├── 2026-06-14-tradescape-phase-3.md   # Advanced: orders, shorts, charts
        └── 2026-06-14-tradescape-phase-4.md   # Social: clubs, tournaments
```

---

## Development Workflow

### Adding a new feature

1. **Update `roadmap.md`** — add the feature to the appropriate phase
2. **Write a plan** in `docs/superpowers/plans/YYYY-MM-DD-tradescape-phase-N.md`
3. **Use subagent-driven development** — dispatch one agent per task
4. **After each task:** verify proxy tests pass, commit
5. **Rebuild .rbxlx** with Rojo
6. **Update CHANGELOG** with new features
7. **Push to GitHub** — Render auto-deploys from master

### Subagent dispatch pattern
```
Agent with: exact file paths, complete code, no placeholders
→ Agent creates file, commits
→ Verify (run proxy tests if applicable)
→ Update CHANGELOG + roadmap
→ Push
```

### Testing proxy
```bash
cd c:\pipe\proxy
npm test                    # Run all 14 tests
node --test tests/quote.test.js  # Run specific test file
```

Roblox Luau code cannot be tested from CLI — test in Roblox Studio.

---

## Architecture Overview

```
Yahoo Finance API
        ↓ (yahoo-finance2 v3, requires `new YahooFinance()`)
Node.js Proxy (Express 5.2, Render free tier)
  - Cache: node-cache, separate TTL per data type
  - Auth: X-API-Key header shared between proxy and Roblox
  - Rate limit: sliding window, 100 req/min default
        ↓ HTTPS
Roblox Server (HttpService via ProxyClient.lua)
  - Server-side cache + stale fallback (120s)
  - DataStore: batch writes every 6s, exponential backoff
  - Order processing: every 10s heartbeat
  - Leaderboard refresh: every 5 min
        ↓ RemoteFunctions (22 total)
Roblox Client (Luau LocalScripts)
  - 7 UI screens: Market, Trade, Profile, Chart, News, Club, Leaderboard
  - Keys: Tab=Profile, C=Club, L=Leaderboard
```

---

## Key URLs & Credentials

| Item | Value | Where to change |
|------|-------|-----------------|
| GitHub repo | https://github.com/FiveTechSoft/tradescape | — |
| Proxy URL | https://tradescape-nxq0.onrender.com | `GameConfig.lua:14`, `render.yaml` |
| API Key | `615942e2f23d63b2f765d6d9771319291323442d86ae73ab8bf9d81cad75724b` | `GameConfig.lua:15`, `.env`, Render dashboard |
| Roblox Experience ID | 10326856686 | `CHANGELOG.md`, Render in Studio |
| Roblox Community ID | 173376366 | Roblox dashboard |
| Render Service | tradescape-nxq0 | Render dashboard |
| Render Service ID | srv-d8n9fibtqb8s73ctsiag | Render dashboard |

### Render Settings
- Root Directory: (empty)
- Build Command: `cd proxy && npm install`
- Start Command: `cd proxy && npm start`
- Env Var: `API_KEY` = (see above)

---

## Current State

### Completed (Phases 1-4)
- ✅ Proxy: all 5 endpoints + auth + rate limit + caching (14 tests)
- ✅ Trading: buy/sell market orders, portfolio with P&L
- ✅ RPG: 50 levels, 6 ranks, XP, 10 perks, 10 missions, 5 office tiers
- ✅ Advanced: limit/stop/take-profit orders, short selling, candlestick charts
- ✅ Social: clubs, tournaments, global leaderboard, copy-trading
- ✅ UI: 7 screens (Market, Trade, Profile, Chart, News, Club, Leaderboard)
- ✅ Deployment: Render free tier, Rojo build system
- ✅ GitHub: full CI-ready repo structure

### Pending
- ⬜ Phase 5: Monetization (Robux cosmetics, premium data, themes)
- ⬜ Phase 6: Expansion (options/futures, market events, seasons)
- ⬜ Roblox new creator waiting period (24-72h to make public)
- ⬜ VPS deployment (currently on Render free tier)

---

## Known Issues & Notes

1. **yahoo-finance2 v3 breaking change:** Must use `new YahooFinance()`, not direct import. The service wrapper in `proxy/src/services/yahoo.js` already handles this.

2. **Express 5.x** is in use, not Express 4. Route mounting uses `app.use(router)`.

3. **Render cold start:** Free tier sleeps after 15min inactivity. First request takes ~30s to wake. Subsequent requests are fast.

4. **Roblox new creator limit:** New accounts have a waiting period before games can be made public. Experience 10326856686 is pending. Check https://create.roblox.com/dashboard/creations/experiences/10326856686/overview

5. **Rojo path:** The Rojo CLI is installed via winget at a specific path. See the "Quick Resume" section above. Add to PATH for convenience.

6. **Market closed on weekends:** Prices won't update. Market status endpoint returns "closed" for all exchanges on Saturday/Sunday.

7. **No Roblox CI:** All Luau code is written to files but cannot be tested from CLI. Testing requires Roblox Studio.

---

## Future Dev Sessions

When resuming development:

1. `git pull` to get latest
2. Check `roadmap.md` for next phase
3. Write a new plan in `docs/superpowers/plans/`
4. Dispatch subagents per task
5. Rebuild `.rbxlx` after changes
6. `git push` — Render auto-deploys
7. Open in Roblox Studio to test

For Phase 5 (Monetization): focus on Robux products that don't give gameplay advantage — more portfolio slots, office decorations, premium data, visual themes.

For Phase 6 (Expansion): options trading, futures, market crash events, seasons, public API.
