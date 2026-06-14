# TradeScape Phase 3 — Advanced Trading

> **Goal:** Limit orders, stop-loss/take-profit, short selling, candlestick charts, news.

---

## Tasks

### 3.1: Orders engine
- Create `Orders.lua` — Limit buy/sell, stop-loss, take-profit
- Order matching loop (checks every 10s against current prices)
- Order lifecycle: pending → filled/expired/cancelled

### 3.2: Short selling in Economy
- Update `Economy.lua` — Support short positions
- Borrow shares, sell first, buy back later
- Requires "short_selling" perk

### 3.3: Order RemoteFunctions
- Update `NetworkHandler.server.lua` — CreateOrder, CancelOrder, GetOrders

### 3.4: Chart data client
- Create `ChartData.client.lua` — Fetch history, calculate SMA/RSI/MACD locally
- Multiple timeframes

### 3.5: Chart UI
- Create `ChartView.client.lua` — Candlestick chart rendering
- Toggle between line/candlestick views
- Volume bars, indicator overlays

### 3.6: News widget
- Create `NewsWidget.client.lua` — "Why did this move?" for big changes
- Fetches from proxy news endpoint
