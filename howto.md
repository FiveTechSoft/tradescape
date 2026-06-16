# TradeScape — Development Guide

> Roblox trading RPG — city exploration + stock collection.
> GitHub: https://github.com/FiveTechSoft/tradescape

---

## Quick Resume

```bash
# Rebuild Roblox place file
& "C:\Users\Anto\AppData\Local\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe\rojo.exe" build -o tradescape.rbxlx

# Run proxy tests
cd proxy && npm test

# Start proxy locally
cd proxy && npm run dev

# Open in Roblox Studio (Windows)
$studioExe = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Recurse -Filter "RobloxStudioBeta.exe" | Select-Object -First 1
Start-Process $studioExe.FullName -ArgumentList "C:\pipe\tradescape.rbxlx"
```

---

## Roblox Studio MCP Setup

### What is it?
An MCP server that lets AI assistants (Codex, Claude, etc.) execute Luau code inside a live Roblox Studio session. You can read/write game state, take screenshots, and interact with running games.

### Installation (already done)

The MCP is registered in `~/.codex/config.toml`:
```toml
[mcp_servers.robloxstudio]
command = "npx"
args = ["-y", "@chrrxs/robloxstudio-mcp@latest", "--auto-install-plugin"]
```

### How to use it

**1. Open Roblox Studio** with the game file:
```powershell
$studioExe = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Recurse -Filter "RobloxStudioBeta.exe" | Select-Object -First 1
Start-Process $studioExe.FullName -ArgumentList "C:\pipe\tradescape.rbxlx"
```

**2. The MCP plugin auto-connects.** Verify with:
```powershell
curl.exe -s "http://localhost:58741/health"
```
You should see `"pluginConnected":true`.

**3. Start the game (F5).** The MCP gets 3 instances:
- `edit` — the editor (not running)
- `server` — the server during playtest
- `client-1` — the client during playtest

**4. Execute Luau code via MCP:**

```powershell
# Example: get game state from server
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"execute_luau","arguments":{"code":"return #workspace:GetChildren()","target":"server"}}}'
$json | Out-File -Encoding utf8 -FilePath "$env:TEMP\mcp_req.json"
curl.exe -s -X POST "http://localhost:58741/mcp" -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -d "@$env:TEMP\mcp_req.json"
```

**5. Available MCP tools:**

| Tool | Description |
|------|-------------|
| `execute_luau` | Run Luau code on server/client/edit |
| `get_connected_instances` | List connected Studio sessions |
| `capture_screenshot` | Take a screenshot of the game |
| `get_file_tree` | Get instance hierarchy |
| `get_place_info` | Get place ID, name, settings |
| `get_services` | List available services |
| `search_objects` | Find instances by name/class |
| `create_object` | Create new instances |
| `set_property` | Set instance properties |

**6. Targets:**
- `"target": "server"` — runs on the game server
- `"target": "client-1"` — runs on the first client
- `"target": "edit"` — runs in the editor (not playing)

**7. Important: MCP overrides are temporary.** When you restart Studio, all overrides (API key fixes, handler patches) are lost. You must reapply them or fix the code permanently.

### Common MCP commands

```powershell
# Check MCP status
curl.exe -s "http://localhost:58741/health"

# List connected instances
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_connected_instances","arguments":{}}}'

# Execute Luau on server
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"execute_luau","arguments":{"code":"return workspace:GetChildren()","target":"server"}}}'

# Execute Luau on client
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"execute_luau","arguments":{"code":"return game.Players.LocalPlayer.Name","target":"client-1"}}}'

# Take screenshot
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"capture_screenshot","arguments":{}}}'
```

### How to save screenshots

The MCP returns base64 JPEG. To save:
```powershell
# Run the screenshot command, save output to file
$json = '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"capture_screenshot","arguments":{}}}'; $json | Out-File -Encoding utf8 -FilePath "$env:TEMP\mcp_req.json"; curl.exe -s -X POST "http://localhost:58741/mcp" -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" -d "@$env:TEMP\mcp_req.json" > "$env:TEMP\screenshot.json"

# Extract base64 and save
$data = Get-Content "$env:TEMP\screenshot.json" -Raw
$match = [regex]::Match($data, '"data":"(/9j/[^"]+)"')
$b64 = $match.Groups[1].Value
[System.IO.File]::WriteAllBytes("C:\pipe\screenshot.jpg", [System.Convert]::FromBase64String($b64))
```

---

## Project Structure

```
C:\pipe/
├── howto.md                              # This file
├── CHANGELOG.md
├── README.md
├── roadmap.md
├── default.project.json                  # Rojo config
├── tradescape.rbxlx                      # Built Roblox place
│
├── proxy/                                # Node.js backend
│   ├── src/
│   │   ├── index.js
│   │   ├── cache.js
│   │   ├── services/yahoo.js
│   │   ├── middleware/auth.js
│   │   ├── middleware/rateLimit.js
│   │   └── routes/ (quote, history, search, marketStatus, news)
│   └── tests/
│
└── roblox/                               # Roblox Luau source
    ├── ServerScriptService/
    │   ├── GameConfig.lua                # Constants (proxy URL, API key)
    │   ├── ProxyClient.lua               # HttpService wrapper + cache
    │   ├── NetworkHandler.server.lua     # RemoteFunctions + player lifecycle
    │   ├── InitWorld.server.lua          # Creates Baseplate + SpawnLocation
    │   ├── CityBuilder.server.lua        # Builds explorable city (buildings, streets)
    │   ├── StockSpawner.server.lua       # Collectible stock items (Touched events)
    │   ├── EnemySpawner.server.lua       # Patrolling enemies on rooftops
    │   ├── NatureBuilder.server.lua      # Trees, plants, birds, street details
    │   ├── CarSpawner.server.lua         # Drivable cars on streets
    │   └── TradingService/               # Game economy modules
    ├── ReplicatedStorage/
    │   └── Types.lua
    └── StarterPlayer/StarterPlayerScripts/
        ├── InventoryUI.client.lua        # Collected stocks counter + inventory (I key)
        ├── CarControls.client.lua        # Enter/drive/exit cars (E/WASD/F)
        └── UI/                           # Market screens (disabled for Level 1)
```

---

## Game State

### Level 1: "The Collector"
- 2000x2000 city with ~150 explorable buildings
- Buildings have interiors (desks, shelves, stairs)
- 16 collectible stock items (AAPL, TSLA, MSFT, etc.)
- 30 patrolling enemies on rooftops
- ~80 cars driving on streets (drivable with E/WASD/F)
- Trees, bushes, flowers, birds flying
- Counter: "Collected: 0 / 16"
- Press I for inventory

### Stock collectibles locations
Scattered across the city:
- Downtown center (4 stocks)
- Northwest/Northeast corners (4 stocks)
- Mid-west/Mid-east (4 stocks)
- Near beach/far corners (4 stocks)

### Enemies
- Patrol rooftops, chase player if < 20 studs
- Red body, yellow glowing eyes
- Speed: patrol 16, chase 24

---

## Development Workflow

### Rebuild cycle
1. Edit `.lua` files in `roblox/`
2. Rebuild: `& "C:\Users\Anto\AppData\Local\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe\rojo.exe" build -o tradescape.rbxlx`
3. Close Studio, reopen with the new .rbxlx
4. Press F5 to test

### If Studio won't pick up changes
The saved place in Studio may override the .rbxlx. Solution:
1. Close Studio WITHOUT saving
2. Reopen the .rbxlx file directly
3. Press F5

### Testing via MCP
1. Open Studio, press F5
2. Check MCP: `curl.exe -s "http://localhost:58741/health"`
3. Execute Luau to test features
4. Take screenshots to verify

---

## Key Credentials

| Item | Value |
|------|-------|
| GitHub | https://github.com/FiveTechSoft/tradescape |
| Proxy | https://tradescape-nxq0.onrender.com |
| API Key | `615942e2f23d63b2f765d6d9771319291323442d86ae73ab8bf9d81cad75724b` |
| Roblox Experience | 10326856686 |
| MCP Port | localhost:58741 |
| MCP Package | `@chrrxs/robloxstudio-mcp@latest` |

---

## Known Issues

1. **MCP overrides are temporary** — lost on Studio restart. Fix code permanently in .lua files.
2. **Rojo build may not apply** — if Studio saved over the place file, close without saving and reopen.
3. **DataStore doesn't work in local testing** — use pcall stubs in NetworkHandler.
4. **Render cold start** — free tier sleeps after 15min, first request ~30s.
5. **`goto` is reserved in Luau** — use nested if/else instead.
6. **`_G` doesn't share between LocalScripts** — use `shared` instead.
