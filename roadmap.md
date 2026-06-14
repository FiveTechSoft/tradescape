# 🏦 TradeScape — Roblox Trading RPG

> Simulador de trading con datos reales globales. Roblox es solo la plataforma. El mercado real es el juego.

---

## Arquitectura

```
[Yahoo Finance API]
        │
        ▼
[Proxy Node.js (VPS $5/mes)]
   - yahoo-finance2 (npm)
   - Cache 60s por símbolo
   - Normaliza datos para Roblox
        │
        ▼
[Roblox Server (HttpService)]
        │
        ▼
[Roblox Client (Luau)]
   - UI Roblox nativa
   - Datos en tiempo real vía server
   - Oficina virtual 3D
```

---

## Visión

Convertir el trading en una **experiencia RPG didáctica y lúdica** dentro de Roblox, usando datos reales de mercados financieros globales. Sin pay-to-win. Monetización solo cosmética.

---

## Roadmap

### Fase 1 — Fundación (MVP) ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Proxy Node.js | ✅ | Express + yahoo-finance2, 5 endpoints, cache 60s, 14 tests |
| Conexión Roblox ↔ Proxy | ✅ | HttpService via ProxyClient con cache + stale fallback |
| UI de mercado | ✅ | Watchlist 16 símbolos, refresh 2s, Bloomberg dark theme |
| Compra/Venta simple | ✅ | Modal buy/sell con validación, fees 0.1%, confirmación |
| Portfolio básico | ✅ | P&L en vivo, valor total, profit %, posiciones |
| Saldo inicial | ✅ | $10,000 virtuales al unirse |
| Persistencia | ✅ | DataStore batch writes, backoff exponencial, force save |

### Fase 2 — Progresión y RPG ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Sistema de niveles | ✅ | 50 niveles, 6 rangos (Novato→Whale), XP por trades |
| XP de trading | ✅ | Cálculo por profit %, bonus por size, pérdida de XP en losses |
| Perks por nivel | ✅ | 10 perks, 1 punto por nivel, árbol de desbloqueo |
| Misiones diarias | ✅ | 10 misiones, rotación diaria (3/día), progreso + claim |
| Oficina virtual | ✅ | 5 niveles (Phone→Executive), basado en profit neto |
| Perfil con UI | ✅ | ProfileScreen: XP bar, perks tab, missions tab, office info |

### Fase 3 — Trading Avanzado ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Órdenes Limit | ✅ | Compra/vende a precio objetivo, 90 días GTC |
| Stop-Loss / Take-Profit | ✅ | Cierre automático, gatillado por precio |
| Short Selling | ✅ | Venta en corto con 50% margen, perk-gated |
| Gráficos de velas | ✅ | Renderizado client-side, wicks, volumen |
| Timeframes | ✅ | 1D, 1W, 1M, 3M, 6M, 1Y |
| "Por qué subió/bajó" | ✅ | NewsWidget contextual + tips educativos |

### Fase 4 — Social y Competitivo ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Clubes de trading | ✅ | Grupos hasta 20, roles, chat, portfolio colectivo (C key) |
| Torneos semanales | ✅ | $10K frescos cada lunes, puro skill, 7 días |
| Copy-trading | ✅ | Perk-gated, 15min delay, portfolios sanitizados |
| Leaderboard global | ✅ | Por valor y nivel, top 100, refresh 5min (L key) |

### Fase 5 — Monetización (Cosmética) ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Tienda de Robux | ✅ | 6 productos, solo cosméticos, sin ventaja de juego |
| Slots extra | ✅ | +2 portfolio slots vía Robux |
| Skins de oficina | ✅ | 2 estilos (Modern, Classic Wall Street) |
| Insignias premium | ✅ | "Verified Trader" badge dorada |
| Datos premium | ✅ | Perk data_premium comprable |
| Themes visuales | ✅ | 5 themes (Dark, Light, Matrix, Midnight, Terminal) |

### Fase 6 — Expansión ✅ Completa

| Feature | Estado | Descripción |
|---------|--------|-------------|
| Opciones (calls/puts) | ✅ | Simplified Black-Scholes, strikes ±5-20%, nivel 25+ |
| Eventos de mercado | ✅ | Crash Survival, Earnings, Bull Run; triggers S&P 500 real |
| Seasons mensuales | ✅ | Stats por mes, leaderboards separados |
| Market mood | ✅ | Crash/Bearish/Neutral/Bullish/Bull en UI |
| API pública | ⬜ | Futuro: REST API para comunidad externa |

---

## 🎉 TradeScape — Juego Completo

**6 fases, 1 día, 33 módulos Luau, 33 RemoteFunctions, 14 tests proxy.**

### Fase 4 — Social y Competitivo

| Feature | Descripción |
|---------|-------------|
| Clubes de trading | Grupos de hasta 20, chat interno, portfolio colectivo, ranking |
| Torneos semanales | $10K frescos cada semana, gana quien más profit % |
| Copy-trading | Ver portfolios top traders (retrasado 15 min) |
| Leaderboard global | Por rendimiento, por patrimonio, por nivel |

### Fase 5 — Monetización (Solo Cosmética)

| Feature | Descripción |
|---------|-------------|
| Más slots de portfolio | Robux (no da dinero, solo flexibilidad) |
| Apariencia de oficina | Decoraciones, terminales, accesorios 3D |
| Insignias premium | "Trader Verificado", rangos élite |
| Acceso a datos avanzados | Gráficos premium, más indicadores, alertas |
| Themes visuales | Terminal Bloomberg, Dark Mode Pro, Matrix |

### Fase 6 — Expansión

| Feature | Descripción |
|---------|-------------|
| Opciones y futuros | Desbloqueo en nivel Magnate |
| Mercados globales 24h | Sincronización con husos horarios reales |
| Eventos de mercado | "Crash Survival" en caídas reales del S&P 500 |
| Temporadas | Reset mensual opcional (sin perder portfolio principal) |
| API pública | Para que la comunidad cree herramientas externas |

---

## Mercados Soportados

- 🇺🇸 USA (NYSE, NASDAQ) — sin sufijo
- 🇩🇪 Alemania — `.DE`
- 🇬🇧 Londres — `.L`
- 🇫🇷 París — `.PA`
- 🇯🇵 Tokio — `.T`
- 🇭🇰 Hong Kong — `.HK`
- 🇨🇳 Shanghai — `.SS`
- 🇦🇺 Australia — `.AX`
- 🇧🇷 São Paulo — `.SA`

Y más vía Yahoo Finance.

---

## Stack Técnico

| Capa | Tecnología |
|------|-----------|
| Juego | Roblox (Luau) |
| Backend Proxy | Node.js + Express + yahoo-finance2 |
| Hosting Proxy | VPS Linux $5-10/mes |
| API de Datos | Yahoo Finance (gratis, sin API key) |
| Backup API | Finnhub (60 req/min gratis) |
| Cache | En memoria, 60s TTL por símbolo |
| Persistencia | Roblox DataStore |

---

## Principios

- **No pay-to-win** — el dinero del juego solo se gana tradeando
- **Datos reales** — precios del mercado real, no simulados
- **Didáctico** — aprendes mecánicas financieras reales progresivamente
- **Lúdico** — RPG, misiones, eventos, social
- **Global** — mercados de todo el mundo desde el inicio
