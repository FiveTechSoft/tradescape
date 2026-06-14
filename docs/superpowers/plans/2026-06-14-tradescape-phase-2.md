# TradeScape Phase 2 — RPG & Progression

> **Goal:** Add XP system, levels, perks, daily missions, and virtual office progression.

**Architecture:** New server modules (XPManager, Missions, Perks, OfficeManager) wire into existing Economy (XP on trade) and NetworkHandler (new RemoteFunctions). Client gets XP bar, mission panel, office view.

**Depends on:** Phase 1 complete (proxy + trading core)

---

## Tasks

### Task 2.1: XPManager
- Create `roblox/ServerScriptService/TradingService/XPManager.lua`
- XP calculation per trade, level thresholds, rank names
- Functions: `calculateXP(profit, profitPercent)`, `getLevel(xp)`, `getRank(level)`, `addXP(playerData, amount)`

### Task 2.2: Perks
- Create `roblox/ServerScriptService/TradingService/Perks.lua`
- Perk definitions with costs/minLevel, unlock logic
- Perk points: 1 per level

### Task 2.3: Missions
- Create `roblox/ServerScriptService/TradingService/Missions.lua`
- 10 mission definitions, daily rotation (3 per day), progress tracking

### Task 2.4: OfficeManager
- Create `roblox/ServerScriptService/TradingService/OfficeManager.lua`
- Office levels 0-4 based on total profit milestones

### Task 2.5: Update Economy for XP
- Modify `Economy.lua` — call XPManager on sell, add `addXP` call

### Task 2.6: Update PlayerData
- Ensure default profile has `xp`, `level`, `rank`, `perks`, `missions`, `officeLevel` (already partially done)

### Task 2.7: New RemoteFunctions
- Add: `GetMissions`, `ClaimMission`, `UnlockPerk`, `GetPerks`, `GetOfficeLevel`
- Update `NetworkHandler.server.lua`

### Task 2.8: RPG UI (client)
- Create `ProfileScreen.client.lua` — XP bar, level, rank, perks list, mission panel
- Create `OfficeView.client.lua` — Simple 3D office indicator or 2D representation
