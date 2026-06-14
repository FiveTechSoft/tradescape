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

### Fase 1 — Fundación (MVP)

| Feature | Descripción |
|---------|-------------|
| Proxy Node.js | Express + yahoo-finance2, 1 endpoint por símbolo, cache 60s |
| Conexión Roblox ↔ Proxy | HttpService server-side, polling cada 60s |
| UI de mercado | Lista de acciones con precio, cambio %, gráfico mini (sparkline) |
| Compra/Venta simple | A precio de mercado, 1 clic. Validación de saldo |
| Portfolio básico | Lista de posiciones, P&L en vivo, valor total |
| Saldo inicial | $10,000 virtuales al unirse |
| Persistencia | DataStore por jugador (saldo, posiciones, historial) |

### Fase 2 — Progresión y RPG

| Feature | Descripción |
|---------|-------------|
| Sistema de niveles | Novato → Trader → Broker → Magnate → Whale |
| XP de trading | Ganas XP por profit diario, pierdes en pérdidas grandes |
| Perks por nivel | Más slots de portfolio, short selling, órdenes avanzadas |
| Misiones diarias | Objetivos tipo: "Compra tu primera acción tech", "Sobrevive un -5%" |
| Oficina virtual | Cuarto que escala: teléfono → laptop → multi-pantalla → oficina premium |
| Recompensas cosméticas | Insignias, colores de nombre, avatares temáticos |

### Fase 3 — Trading Avanzado

| Feature | Descripción |
|---------|-------------|
| Órdenes Limit | Compra/vende solo si el precio alcanza X |
| Stop-Loss / Take-Profit | Cierre automático de posición |
| Short Selling | Venta en corto (desbloqueo en nivel Trader) |
| Gráficos profundos | Velas, volumen, indicadores (SMA, RSI, MACD) |
| Múltiples timeframes | 1D, 1W, 1M, 1Y |
| "Por qué subió/bajó" | Noticias reales ligadas a movimientos grandes |

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
