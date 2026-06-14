# TradeScape Phase 4 — Social & Competitive

> **Goal:** Trading clubs, weekly tournaments, copy-trading, global leaderboard.

## Tasks

### 4.1: ClubManager
- Create club, join/leave, invite/kick, roles (owner/admin/member)
- Max 20 members, chat (simple message log)
- Club portfolio aggregation, weekly profit % ranking
- DataStore: `club_{clubId}`

### 4.2: TournamentManager
- Weekly: $10K fresh balance each Monday, 7 days
- Separate tournament portfolio from main
- P&L% leaderboard

### 4.3: Leaderboard
- Rankings by: total value, weekly profit %, level/XP
- Top 100 cached, refreshed every 5 min

### 4.4: Copy-trade visibility
- Delayed portfolio data (15 min) of top players
- Requires "copy_trade_view" perk

### 4.5: RemoteFunctions for social features

### 4.6: Club UI (client)
### 4.7: Leaderboard UI (client)
### 4.8: Tournament UI (client)
