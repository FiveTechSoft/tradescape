# TradeVille — Design Document

> Roblox Trading RPG con datos reales de mercados globales.
> Fecha: 2026-06-14

---

## 1. Visión

Convertir el trading en una experiencia RPG didáctica y lúdica dentro de Roblox, usando datos reales de Yahoo Finance. Sin pay-to-win. Monetización solo cosmética.

---

## 2. Arquitectura General

```
Yahoo Finance (gratis, sin API key)
        │
        ▼
Node.js Proxy (VPS $5/mes)
  - Express + yahoo-finance2
  - Cache 60s por símbolo
        │ HTTPS + X-API-Key
        ▼
Roblox Server (HttpService)
  - ProxyClient (wrapper HTTP)
  - TradingService (lógica de negocio)
  - DataStore (persistencia)
        │ RemoteEvents
        ▼
Roblox Client (Luau UI)
  - Pantallas: Mercado, Portfolio, Charts, Perfil
  - Oficina 3D progresiva
```

---

## 3. API Proxy ↔ Roblox

### Endpoints

| Método | Ruta | Cache TTL |
|--------|------|-----------|
| GET | `/api/quote/:symbol` | 60s |
| GET | `/api/history/:symbol?range=1m\|3m\|6m\|1y` | 300s |
| GET | `/api/search?q=` | 3600s |
| GET | `/api/market-status` | 60s |
| GET | `/api/news/:symbol` | 300s |

### Formatos de respuesta

**Quote:**
```json
{
  "s": "AAPL", "n": "Apple Inc.", "p": 198.75, "c": 2.35, "cp": 1.20,
  "h": 200.10, "l": 196.50, "o": 197.00, "v": 52400000,
  "e": "NASDAQ", "m": "open", "t": 1718314200
}
```

**History:**
```json
{
  "s": "AAPL", "r": "1m",
  "d": [{ "t": 1718236800, "o": 197.00, "h": 198.50, "l": 196.20, "c": 197.80, "v": 48000000 }, ...]
}
```

**Search:**
```json
{
  "q": "apple",
  "r": [{ "s": "AAPL", "n": "Apple Inc.", "e": "NASDAQ", "t": "stock" }, ...]
}
```

**Market Status:**
```json
{ "us": "open", "de": "closed", "jp": "closed", "hk": "open" }
```

**News:**
```json
{
  "s": "AAPL",
  "n": [{ "t": "Apple beats earnings", "u": "https://...", "d": "2026-06-14", "s": "Reuters" }]
}
```

### Errores
```json
{ "error": "symbol_not_found", "message": "..." }
{ "error": "rate_limited", "retry_after": 15 }
{ "error": "market_closed", "last_price": 198.75, "last_update": 1718314200 }
```

### Seguridad
- Header `X-API-Key` compartido proxy ↔ Roblox
- Rate limit 100 req/min por IP

---

## 4. Arquitectura Roblox

```
ServerScriptService/
├── ProxyClient/init.lua       → wrapper HttpService + cache
├── TradingService/
│   ├── Portfolio.lua          → comprar, vender, posiciones
│   ├── Orders.lua             → limit, stop-loss, take-profit
│   ├── Economy.lua            → saldo, fees, validación
│   └── XPManager.lua          → cálculo XP, niveles, perks
├── DataStore/
│   ├── PlayerData.lua         → save/load perfil
│   ├── MarketData.lua         → cache de quotes
│   └── Leaderboard.lua       → rankings
└── GameConfig.lua             → constantes

ReplicatedStorage/
├── SharedTypes.lua            → tipos compartidos
└── NetworkEvents/             → RemoteFunctions

StarterPlayerScripts/
├── UIController/              → pantallas Luau
└── UIFramework/               → componentes reutilizables
```

---

## 5. Modelo de Datos

### PlayerProfile (DataStore: `player_{userId}`)
- **Economía:** balance, totalDeposited
- **Portfolio:** positions[] (symbol, shares, avgPrice, totalCost, opened)
- **Órdenes:** orders[] (id, type, symbol, qty, price, created, expires)
- **Historial:** tradeHistory[] (id, timestamp, symbol, type, shares, price, total, balanceAfter)
- **RPG:** xp, level, rank, perks[], completedMissions[], missionProgress[]
- **Estética:** officeLevel, title, badgeIds[]
- **Social:** clubId, clubRole
- **Stats:** totalTrades, profitableTrades, totalProfit, winRate, sharpeRatio, streak

### Club (DataStore: `club_{clubId}`)
- name, ownerId, members[] (máx 20), invites[], totalValue, rank, weekProfit

### MarketSnapshot (memoria server)
- symbol, name, price, change, changePercent, high, low, open, volume, exchange, marketState, updated

---

## 6. RPG y Progresión

### Niveles
| Nivel | Rango | XP req | Desbloquea |
|-------|-------|--------|------------|
| 1 | Novato | 0 | Compra/Venta, 5 slots |
| 5 | Trader | 500 | Short selling, +2 slots |
| 10 | Broker | 2000 | Órdenes Limit |
| 15 | Broker II | 4500 | Stop-Loss, Take-Profit |
| 25 | Magnate | 12000 | Opciones, +3 slots |
| 50 | Whale | 50000 | Máx perks, crear club |

### Cálculo XP
- Win: `profitPercent * 10` XP (mín 5)
- Loss: `profitPercent * 3` XP (máx -20)
- Bonus: +20 XP si profit ≥$1000, +100 XP si ≥$10000

### Misiones diarias (3 rotativas/día)
first_buy, profit_any, profit_100, survive_dip, diversify_3, hold_3days, short_win, limit_order_fill, big_win, comeback

### Perks
extra_slot_1, extra_slot_2, short_selling, limit_orders, stop_loss, take_profit, options_basic, data_premium, club_create, copy_trade_view

### Oficina Visual
0=Teléfono → 1=Laptop ($1k) → 2=Dual-screen ($10k) → 3=Multi-screen ($100k) → 4=Oficina ejecutiva ($1M)

---

## 7. Social y Competitivo

### Clubes
- 20 miembros máx, roles owner/admin/member
- Chat grupal (webhook vía proxy)
- Ranking por profit % semanal

### Torneos Semanales
- $10K frescos cada lunes, 7 días
- Puro skill, sin Robux/perks
- Top 1-3 reciben insignias + XP

### Copy-Trading
- 15 min delay, requiere perk
- Visible: allocation %, últimos 5 trades, winRate
- Oculto: precios exactos, órdenes pendientes, saldo

### Eventos de Mercado
- Crash Survival (S&P cae >2%)
- Earnings Season (predecir dirección)
- Bull Run (S&P +10% en 30 días)

---

## 8. Manejo de Errores

- **Proxy caído:** stale cache hasta 120s, banner amarillo, trading congelado
- **Mercado cerrado:** mensaje con hora apertura, sin trading
- **Saldo insuficiente:** error descriptivo con montos exactos
- **DataStore throttle:** cola batch cada 6s, backoff exponencial (6→12→24s)
- **Símbolo no encontrado:** fuzzy match con sugerencia
- **Jugador nuevo:** perfil default $10K, trigger tutorial
- **Desconexión:** trades atómicos server-side, no duplicados

---

## 9. Mercados Soportados

US (.us), Alemania (.DE), UK (.L), Francia (.PA), Japón (.T), Hong Kong (.HK), Shanghai (.SS), Australia (.AX), Brasil (.SA)

---

## 10. Fase 1 — MVP

1. Proxy Node.js funcional (quote, history, search, market-status)
2. Conexión Roblox ↔ Proxy
3. Compra/Venta simple a precio mercado
4. Portfolio básico con P&L en vivo
5. UI mercado: lista + sparkline + datos
6. DataStore persistencia por jugador
7. $10,000 saldo inicial
