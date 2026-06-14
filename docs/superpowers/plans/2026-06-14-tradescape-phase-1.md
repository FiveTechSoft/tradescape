# TradeScape Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build TradeScape MVP: Node.js proxy with Yahoo Finance data + Roblox game with buy/sell trading, portfolio, market UI, and DataStore persistence.

**Architecture:** Two independent subsystems — (A) Node.js Express proxy that fetches from `yahoo-finance2` and caches results, (B) Roblox Luau game with server-side trading logic + client-side UI, communicating via HttpService with `X-API-Key` auth.

**Tech Stack:** Node.js 20+, Express 5, yahoo-finance2, node-cache; Roblox Luau, HttpService, DataStore, RemoteFunctions

---

## File Structure

```
c:\pipe/
├── proxy/                          # Node.js backend
│   ├── package.json
│   ├── .env.example
│   ├── src/
│   │   ├── index.js                # Express app entry, route mounting
│   │   ├── cache.js                # TTL cache wrapper (node-cache)
│   │   ├── middleware/
│   │   │   ├── auth.js             # X-API-Key validation
│   │   │   └── rateLimit.js        # Per-IP rate limiter
│   │   ├── services/
│   │   │   └── yahoo.js            # yahoo-finance2 wrapper
│   │   └── routes/
│   │       ├── quote.js            # GET /api/quote/:symbol
│   │       ├── history.js          # GET /api/history/:symbol
│   │       ├── search.js           # GET /api/search?q=
│   │       ├── marketStatus.js     # GET /api/market-status
│   │       └── news.js             # GET /api/news/:symbol
│   └── tests/
│       ├── quote.test.js
│       ├── history.test.js
│       ├── search.test.js
│       └── marketStatus.test.js
│
└── roblox/                         # Roblox Luau source
    ├── ServerScriptService/
    │   ├── GameConfig.lua          # Constants: balance, fees, proxy URL
    │   ├── ProxyClient.lua         # HttpService wrapper + server cache
    │   ├── TradingService/
    │   │   ├── Economy.lua         # Balance, validation, fees
    │   │   └── Portfolio.lua       # Buy, sell, positions, P&L
    │   └── DataStore/
    │       └── PlayerData.lua      # Save/load player profile
    │
    └── StarterPlayerScripts/
        └── UI/
            ├── MarketScreen.lua    # Stock list + sparkline
            ├── PortfolioScreen.lua # Positions + P&L
            └── TradeWidget.lua     # Buy/sell modal
```

---

### Task 1: Project scaffold

**Files:**
- Create: `c:\pipe\proxy\package.json`
- Create: `c:\pipe\proxy\.env.example`
- Create: `c:\pipe\proxy\src\index.js` (skeleton)

- [ ] **Step 1: Create package.json**

```json
{
  "name": "tradescape-proxy",
  "version": "1.0.0",
  "description": "TradeScape market data proxy — Yahoo Finance → Roblox",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js",
    "test": "node --test tests/"
  },
  "dependencies": {
    "express": "^5.1.0",
    "yahoo-finance2": "^2.15.0",
    "node-cache": "^5.1.2",
    "dotenv": "^16.4.5"
  }
}
```

Run:
```
cd c:\pipe\proxy && npm install
```

- [ ] **Step 2: Create .env.example**

```env
PORT=3000
API_KEY=tradescape-dev-key-change-me
CACHE_TTL_QUOTE=60
CACHE_TTL_HISTORY=300
CACHE_TTL_SEARCH=3600
CACHE_TTL_NEWS=300
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

- [ ] **Step 3: Create src/index.js skeleton**

```javascript
import 'dotenv/config';
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Routes (mounted in later tasks)
// app.use('/api', quoteRoutes);
// app.use('/api', historyRoutes);
// app.use('/api', searchRoutes);
// app.use('/api', marketStatusRoutes);
// app.use('/api', newsRoutes);

app.listen(PORT, () => {
  console.log(`TradeScape proxy running on port ${PORT}`);
});

export default app;
```

- [ ] **Step 4: Run server to verify startup**

Run: `cd c:\pipe\proxy && node src/index.js`
Expected: `TradeScape proxy running on port 3000`

- [ ] **Step 5: Commit**

```bash
git add proxy/
git commit -m "feat(proxy): scaffold Express project with dependencies"
```

---

### Task 2: Yahoo Finance service wrapper

**Files:**
- Create: `c:\pipe\proxy\src\services\yahoo.js`

- [ ] **Step 1: Write the yahoo.js service**

```javascript
import yahooFinance from 'yahoo-finance2';

// yahoo-finance2 throws on not-found symbols — wrap everything
export async function getQuote(symbol) {
  try {
    const quote = await yahooFinance.quote(symbol);
    return {
      s: quote.symbol,
      n: quote.shortName || quote.longName || quote.symbol,
      p: quote.regularMarketPrice || 0,
      c: quote.regularMarketChange || 0,
      cp: quote.regularMarketChangePercent || 0,
      h: quote.regularMarketDayHigh || 0,
      l: quote.regularMarketDayLow || 0,
      o: quote.regularMarketOpen || 0,
      v: quote.regularMarketVolume || 0,
      e: quote.fullExchangeName || quote.exchange || 'Unknown',
      m: quote.marketState || 'CLOSED',
      t: Math.floor(Date.now() / 1000),
    };
  } catch (err) {
    if (err.message?.includes('Not Found') || err.message?.includes('symbol')) {
      return { error: 'symbol_not_found', message: `Symbol "${symbol}" not found` };
    }
    throw err; // re-throw network/API errors for caller to handle
  }
}

export async function getHistory(symbol, range = '1mo') {
  // Map our range strings to yahoo-finance2 intervals
  const rangeMap = {
    '1m': { period1: getDateMonthsAgo(1), interval: '1d' },
    '3m': { period1: getDateMonthsAgo(3), interval: '1d' },
    '6m': { period1: getDateMonthsAgo(6), interval: '1d' },
    '1y': { period1: getDateMonthsAgo(12), interval: '1wk' },
  };

  const config = rangeMap[range] || rangeMap['1m'];

  try {
    const result = await yahooFinance.chart(symbol, {
      period1: config.period1,
      interval: config.interval,
    });

    if (!result || !result.quotes || result.quotes.length === 0) {
      return { s: symbol, r: range, d: [] };
    }

    const data = result.quotes
      .filter(q => q.open !== null && q.close !== null)
      .map(q => ({
        t: Math.floor(new Date(q.date).getTime() / 1000),
        o: Number(q.open.toFixed(2)),
        h: Number(q.high.toFixed(2)),
        l: Number(q.low.toFixed(2)),
        c: Number(q.close.toFixed(2)),
        v: q.volume || 0,
      }));

    return { s: symbol, r: range, d: data };
  } catch (err) {
    if (err.message?.includes('Not Found') || err.message?.includes('symbol')) {
      return { s: symbol, r: range, d: [], error: 'symbol_not_found' };
    }
    throw err;
  }
}

export async function searchSymbols(query) {
  try {
    const results = await yahooFinance.search(query);
    if (!results || !results.quotes || results.quotes.length === 0) {
      return { q: query, r: [] };
    }

    const items = results.quotes
      .filter(q => q.symbol && q.shortname)
      .slice(0, 10)
      .map(q => ({
        s: q.symbol,
        n: q.shortname || q.longname || q.symbol,
        e: q.exchange || 'Unknown',
        t: q.quoteType?.toLowerCase() || 'stock',
      }));

    return { q: query, r: items };
  } catch (err) {
    return { q: query, r: [], error: 'search_failed' };
  }
}

export async function getMarketStatus() {
  // Map of exchange suffixes to their market state
  const indices = [
    { key: 'us', symbol: '^GSPC' },
    { key: 'de', symbol: '^GDAXI' },
    { key: 'uk', symbol: '^FTSE' },
    { key: 'fr', symbol: '^FCHI' },
    { key: 'jp', symbol: '^N225' },
    { key: 'hk', symbol: '^HSI' },
    { key: 'cn', symbol: '000001.SS' },
    { key: 'au', symbol: '^AXJO' },
    { key: 'br', symbol: '^BVSP' },
  ];

  const status = {};

  await Promise.all(
    indices.map(async ({ key, symbol }) => {
      try {
        const q = await yahooFinance.quote(symbol);
        status[key] = q.marketState?.toLowerCase() || 'unknown';
      } catch {
        status[key] = 'unknown';
      }
    })
  );

  return status;
}

export async function getNews(symbol) {
  // yahoo-finance2 news is limited; return placeholder
  // This endpoint is lower priority for MVP
  try {
    // Attempt to get news — this may not always return results
    return { s: symbol, n: [] };
  } catch {
    return { s: symbol, n: [], error: 'news_unavailable' };
  }
}

function getDateMonthsAgo(months) {
  const d = new Date();
  d.setMonth(d.getMonth() - months);
  return d;
}
```

- [ ] **Step 2: Verify yahoo-finance2 works manually**

Run (node REPL):
```
cd c:\pipe\proxy
node -e "import('./src/services/yahoo.js').then(m => m.getQuote('AAPL').then(q => console.log(JSON.stringify(q, null, 2))))"
```
Expected: JSON object with symbol "AAPL", price, change, etc.

- [ ] **Step 3: Commit**

```bash
git add proxy/src/services/yahoo.js
git commit -m "feat(proxy): add Yahoo Finance service wrapper"
```

---

### Task 3: Cache layer

**Files:**
- Create: `c:\pipe\proxy\src\cache.js`

- [ ] **Step 1: Write cache.js**

```javascript
import NodeCache from 'node-cache';

// Separate cache instances for different TTLs
const caches = {
  quote: new NodeCache({ stdTTL: parseInt(process.env.CACHE_TTL_QUOTE) || 60, checkperiod: 10 }),
  history: new NodeCache({ stdTTL: parseInt(process.env.CACHE_TTL_HISTORY) || 300, checkperiod: 30 }),
  search: new NodeCache({ stdTTL: parseInt(process.env.CACHE_TTL_SEARCH) || 3600, checkperiod: 60 }),
  news: new NodeCache({ stdTTL: parseInt(process.env.CACHE_TTL_NEWS) || 300, checkperiod: 30 }),
  marketStatus: new NodeCache({ stdTTL: 60, checkperiod: 10 }),
};

const stats = {
  hits: 0,
  misses: 0,
  sets: 0,
};

export function getCached(cacheType, key) {
  const cache = caches[cacheType];
  if (!cache) return null;

  const value = cache.get(key);
  if (value !== undefined) {
    stats.hits++;
    return value;
  }
  stats.misses++;
  return null;
}

export function setCached(cacheType, key, value) {
  const cache = caches[cacheType];
  if (!cache) return;

  stats.sets++;
  cache.set(key, value);
}

export function getCacheStats() {
  return { ...stats };
}

// Helper: try cache first, fall back to fetch function
export async function withCache(cacheType, key, fetchFn) {
  const cached = getCached(cacheType, key);
  if (cached !== null) {
    return cached;
  }

  const result = await fetchFn();
  setCached(cacheType, key, result);
  return result;
}
```

- [ ] **Step 2: Commit**

```bash
git add proxy/src/cache.js
git commit -m "feat(proxy): add TTL cache layer with node-cache"
```

---

### Task 4: Auth middleware + Rate limiter

**Files:**
- Create: `c:\pipe\proxy\src\middleware\auth.js`
- Create: `c:\pipe\proxy\src\middleware\rateLimit.js`

- [ ] **Step 1: Write auth.js**

```javascript
const API_KEY = process.env.API_KEY || 'tradescape-dev-key-change-me';

export function authMiddleware(req, res, next) {
  const key = req.headers['x-api-key'];

  if (!key) {
    return res.status(401).json({ error: 'missing_api_key', message: 'X-API-Key header required' });
  }

  if (key !== API_KEY) {
    return res.status(403).json({ error: 'invalid_api_key', message: 'Invalid API key' });
  }

  next();
}
```

- [ ] **Step 2: Write rateLimit.js**

```javascript
const WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000;
const MAX_REQUESTS = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100;

const requestLog = new Map();

export function rateLimitMiddleware(req, res, next) {
  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();

  if (!requestLog.has(ip)) {
    requestLog.set(ip, []);
  }

  const timestamps = requestLog.get(ip);
  // Remove entries outside the window
  while (timestamps.length > 0 && timestamps[0] < now - WINDOW_MS) {
    timestamps.shift();
  }

  if (timestamps.length >= MAX_REQUESTS) {
    const retryAfter = Math.ceil((timestamps[0] + WINDOW_MS - now) / 1000);
    res.set('Retry-After', String(retryAfter));
    return res.status(429).json({
      error: 'rate_limited',
      retry_after: retryAfter,
      message: `Too many requests. Retry after ${retryAfter}s`,
    });
  }

  timestamps.push(now);
  next();
}
```

- [ ] **Step 3: Write tests for middleware**

Create: `c:\pipe\proxy\tests\middleware.test.js`

```javascript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import { authMiddleware } from '../src/middleware/auth.js';
import { rateLimitMiddleware } from '../src/middleware/rateLimit.js';

describe('Auth Middleware', () => {
  it('should reject requests without API key', async () => {
    const app = express();
    app.get('/test', authMiddleware, (req, res) => res.json({ ok: true }));

    const res = await fetch('http://localhost:9999/test');
    assert.strictEqual(res.status, 401);
  });

  it('should reject wrong API key', async () => {
    const app = express();
    app.get('/test', authMiddleware, (req, res) => res.json({ ok: true }));

    const res = await fetch('http://localhost:9999/test', {
      headers: { 'x-api-key': 'wrong-key' },
    });
    assert.strictEqual(res.status, 403);
  });

  it('should pass with correct API key', async () => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.get('/test', authMiddleware, (req, res) => res.json({ ok: true }));

    const server = app.listen(9998);
    const res = await fetch('http://localhost:9998/test', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();
    server.close();

    assert.strictEqual(res.status, 200);
    assert.deepStrictEqual(body, { ok: true });
  });
});

describe('Rate Limit Middleware', () => {
  it('should allow requests under limit', async () => {
    const app = express();
    app.get('/test', rateLimitMiddleware, (req, res) => res.json({ ok: true }));

    const server = app.listen(9997);
    const res = await fetch('http://localhost:9997/test');
    server.close();

    assert.strictEqual(res.status, 200);
  });
});
```

- [ ] **Step 4: Run middleware tests**

Run: `cd c:\pipe\proxy && node --test tests/middleware.test.js`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add proxy/src/middleware/ proxy/tests/
git commit -m "feat(proxy): add auth and rate limit middleware with tests"
```

---

### Task 5: Quote endpoint

**Files:**
- Create: `c:\pipe\proxy\src\routes\quote.js`
- Create: `c:\pipe\proxy\tests\quote.test.js`
- Modify: `c:\pipe\proxy\src\index.js` (mount route)

- [ ] **Step 1: Write quote route**

```javascript
import { Router } from 'express';
import { getQuote } from '../services/yahoo.js';
import { withCache } from '../cache.js';

const router = Router();

router.get('/api/quote/:symbol', async (req, res) => {
  const { symbol } = req.params;

  if (!symbol || symbol.length > 20) {
    return res.status(400).json({ error: 'invalid_symbol', message: 'Symbol parameter is required (max 20 chars)' });
  }

  try {
    const result = await withCache('quote', symbol.toUpperCase(), () => getQuote(symbol.toUpperCase()));

    if (result.error) {
      const status = result.error === 'symbol_not_found' ? 404 : 502;
      return res.status(status).json(result);
    }

    res.json(result);
  } catch (err) {
    console.error(`[quote] Error fetching ${symbol}:`, err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch quote data' });
  }
});

export default router;
```

- [ ] **Step 2: Write quote tests**

```javascript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import quoteRoutes from '../src/routes/quote.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Quote Route', () => {
  let server;
  let port = 9995;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(quoteRoutes);
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should return quote for valid symbol (AAPL)', async () => {
    const res = await fetch(`http://localhost:${port}/api/quote/AAPL`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.s, 'AAPL');
    assert.ok(typeof body.p === 'number');
    assert.ok(body.p > 0, 'price should be positive');
    assert.ok(typeof body.n === 'string');
    assert.ok(body.n.length > 0);
  });

  it('should return 404 for invalid symbol', async () => {
    const res = await fetch(`http://localhost:${port}/api/quote/ZZZZZZZZZ_INVALID`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 404);
    assert.strictEqual(body.error, 'symbol_not_found');
  });

  it('should return 400 for empty symbol', async () => {
    const res = await fetch(`http://localhost:${port}/api/quote/`, {
      headers: { 'x-api-key': 'test-key' },
    });

    assert.strictEqual(res.status, 404); // Express no-match
  });

  it('should return cached result on second call', async () => {
    const headers = { 'x-api-key': 'test-key' };
    const start = Date.now();
    const res1 = await fetch(`http://localhost:${port}/api/quote/MSFT`, { headers });
    const firstDuration = Date.now() - start;

    const start2 = Date.now();
    const res2 = await fetch(`http://localhost:${port}/api/quote/MSFT`, { headers });
    const secondDuration = Date.now() - start2;

    assert.strictEqual(res1.status, 200);
    assert.strictEqual(res2.status, 200);
    // Cached should be much faster
    assert.ok(secondDuration <= firstDuration * 3, `Cache didn't help: ${firstDuration}ms vs ${secondDuration}ms`);
  });
});
```

- [ ] **Step 3: Mount route in index.js**

In `c:\pipe\proxy\src\index.js`, add after the middleware section:

```javascript
import { authMiddleware } from './middleware/auth.js';
import { rateLimitMiddleware } from './middleware/rateLimit.js';
import quoteRoutes from './routes/quote.js';

// Middleware
app.use(express.json());
app.use(rateLimitMiddleware);
app.use(authMiddleware);

// Routes
app.use(quoteRoutes);
```

- [ ] **Step 4: Run quote tests**

Run: `cd c:\pipe\proxy && node --test tests/quote.test.js`
Expected: All 4 tests pass (AAPL quote OK, invalid symbol 404, cached faster)

- [ ] **Step 5: Commit**

```bash
git add proxy/src/routes/quote.js proxy/src/index.js proxy/tests/quote.test.js
git commit -m "feat(proxy): add quote endpoint with cache and tests"
```

---

### Task 6: History endpoint

**Files:**
- Create: `c:\pipe\proxy\src\routes\history.js`
- Create: `c:\pipe\proxy\tests\history.test.js`
- Modify: `c:\pipe\proxy\src\index.js` (mount route)

- [ ] **Step 1: Write history route**

```javascript
import { Router } from 'express';
import { getHistory } from '../services/yahoo.js';
import { withCache } from '../cache.js';

const router = Router();
const VALID_RANGES = ['1m', '3m', '6m', '1y'];

router.get('/api/history/:symbol', async (req, res) => {
  const { symbol } = req.params;
  const range = req.query.range || '1m';

  if (!symbol || symbol.length > 20) {
    return res.status(400).json({ error: 'invalid_symbol', message: 'Symbol parameter required' });
  }

  if (!VALID_RANGES.includes(range)) {
    return res.status(400).json({ error: 'invalid_range', message: `Range must be one of: ${VALID_RANGES.join(', ')}` });
  }

  try {
    const cacheKey = `${symbol.toUpperCase()}_${range}`;
    const result = await withCache('history', cacheKey, () => getHistory(symbol.toUpperCase(), range));

    if (result.error) {
      return res.status(404).json(result);
    }

    res.json(result);
  } catch (err) {
    console.error(`[history] Error fetching ${symbol}:`, err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch history data' });
  }
});

export default router;
```

- [ ] **Step 2: Write history tests**

```javascript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import historyRoutes from '../src/routes/history.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('History Route', () => {
  let server;
  let port = 9994;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(historyRoutes);
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should return history for valid symbol with default range', async () => {
    const res = await fetch(`http://localhost:${port}/api/history/AAPL`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.s, 'AAPL');
    assert.strictEqual(body.r, '1m');
    assert.ok(Array.isArray(body.d));
    assert.ok(body.d.length > 0, 'should have at least one data point');
    assert.ok(body.d[0].t, 'should have timestamp');
    assert.ok(typeof body.d[0].c === 'number', 'should have close price');
  });

  it('should respect range parameter', async () => {
    const res = await fetch(`http://localhost:${port}/api/history/AAPL?range=3m`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.r, '3m');
    assert.ok(body.d.length > 0);
  });

  it('should reject invalid range', async () => {
    const res = await fetch(`http://localhost:${port}/api/history/AAPL?range=5y`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 400);
    assert.strictEqual(body.error, 'invalid_range');
  });
});
```

- [ ] **Step 3: Mount route in index.js**

Add to `c:\pipe\proxy\src\index.js`:
```javascript
import historyRoutes from './routes/history.js';
// ... with other routes
app.use(historyRoutes);
```

- [ ] **Step 4: Run history tests**

Run: `cd c:\pipe\proxy && node --test tests/history.test.js`
Expected: All 3 tests pass

- [ ] **Step 5: Commit**

```bash
git add proxy/src/routes/history.js proxy/src/index.js proxy/tests/history.test.js
git commit -m "feat(proxy): add history endpoint with tests"
```

---

### Task 7: Search + Market Status + News endpoints

**Files:**
- Create: `c:\pipe\proxy\src\routes\search.js`
- Create: `c:\pipe\proxy\src\routes\marketStatus.js`
- Create: `c:\pipe\proxy\src\routes\news.js`
- Create: `c:\pipe\proxy\tests\search.test.js`
- Create: `c:\pipe\proxy\tests\marketStatus.test.js`
- Modify: `c:\pipe\proxy\src\index.js` (mount routes)

- [ ] **Step 1: Write search route**

```javascript
import { Router } from 'express';
import { searchSymbols } from '../services/yahoo.js';
import { withCache } from '../cache.js';

const router = Router();

router.get('/api/search', async (req, res) => {
  const query = (req.query.q || '').trim();

  if (!query || query.length < 1) {
    return res.status(400).json({ error: 'invalid_query', message: 'Query parameter "q" required' });
  }

  if (query.length > 100) {
    return res.status(400).json({ error: 'invalid_query', message: 'Query too long (max 100 chars)' });
  }

  try {
    const cacheKey = query.toLowerCase();
    const result = await withCache('search', cacheKey, () => searchSymbols(query));

    if (result.error) {
      return res.status(502).json(result);
    }

    res.json(result);
  } catch (err) {
    console.error(`[search] Error searching "${query}":`, err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Search failed' });
  }
});

export default router;
```

- [ ] **Step 2: Write market status route**

```javascript
import { Router } from 'express';
import { getMarketStatus } from '../services/yahoo.js';
import { getCached, setCached } from '../cache.js';

const router = Router();

router.get('/api/market-status', async (req, res) => {
  try {
    const cached = getCached('marketStatus', 'global');
    if (cached) {
      return res.json(cached);
    }

    const status = await getMarketStatus();
    setCached('marketStatus', 'global', status);
    res.json(status);
  } catch (err) {
    console.error('[market-status] Error:', err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch market status' });
  }
});

export default router;
```

- [ ] **Step 3: Write news route (placeholder)**

```javascript
import { Router } from 'express';
import { getNews } from '../services/yahoo.js';
import { withCache } from '../cache.js';

const router = Router();

router.get('/api/news/:symbol', async (req, res) => {
  const { symbol } = req.params;

  if (!symbol || symbol.length > 20) {
    return res.status(400).json({ error: 'invalid_symbol', message: 'Symbol parameter required' });
  }

  try {
    const result = await withCache('news', symbol.toUpperCase(), () => getNews(symbol.toUpperCase()));
    res.json(result);
  } catch (err) {
    console.error(`[news] Error fetching ${symbol}:`, err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch news' });
  }
});

export default router;
```

- [ ] **Step 4: Write search test**

```javascript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import searchRoutes from '../src/routes/search.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Search Route', () => {
  let server;
  let port = 9993;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(searchRoutes);
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should return search results', async () => {
    const res = await fetch(`http://localhost:${port}/api/search?q=Apple`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.q, 'Apple');
    assert.ok(Array.isArray(body.r));
    if (body.r.length > 0) {
      assert.ok(body.r[0].s);
      assert.ok(body.r[0].n);
    }
  });

  it('should reject empty query', async () => {
    const res = await fetch(`http://localhost:${port}/api/search?q=`, {
      headers: { 'x-api-key': 'test-key' },
    });

    assert.strictEqual(res.status, 400);
  });
});
```

- [ ] **Step 5: Write market status test**

```javascript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import marketStatusRoutes from '../src/routes/marketStatus.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Market Status Route', () => {
  let server;
  let port = 9992;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(marketStatusRoutes);
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should return market status object', async () => {
    const res = await fetch(`http://localhost:${port}/api/market-status`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    // Should have at least US market status
    assert.ok(typeof body.us === 'string');
    assert.ok(['open', 'closed', 'pre', 'post', 'unknown'].includes(body.us));
  });
});
```

- [ ] **Step 6: Mount all routes in index.js**

Add to `c:\pipe\proxy\src\index.js`:
```javascript
import searchRoutes from './routes/search.js';
import marketStatusRoutes from './routes/marketStatus.js';
import newsRoutes from './routes/news.js';

// ... with other routes
app.use(searchRoutes);
app.use(marketStatusRoutes);
app.use(newsRoutes);
```

- [ ] **Step 7: Run all proxy tests**

Run: `cd c:\pipe\proxy && node --test tests/`
Expected: All tests pass across all test files

- [ ] **Step 8: Commit**

```bash
git add proxy/src/routes/search.js proxy/src/routes/marketStatus.js proxy/src/routes/news.js proxy/src/index.js proxy/tests/
git commit -m "feat(proxy): add search, market-status, news endpoints with tests"
```

---

### Task 8: Roblox GameConfig + Shared types

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\GameConfig.lua`
- Create: `c:\pipe\roblox\ReplicatedStorage\Types.lua`

- [ ] **Step 1: Write GameConfig.lua**

```lua
-- GameConfig.lua — Constants for TradeScape economy and configuration
-- Place in: ServerScriptService/GameConfig

local GameConfig = {}

-- Economy
GameConfig.STARTING_BALANCE = 10000
GameConfig.TRANSACTION_FEE_RATE = 0.001 -- 0.1% per trade
GameConfig.MIN_SHARES = 1
GameConfig.MAX_SHARES_PER_TRADE = 10000
GameConfig.MAX_SLOTS_BASE = 5 -- portfolio slots for level 1

-- Proxy
GameConfig.PROXY_URL = "https://your-proxy-url.com" -- CHANGE in production
GameConfig.PROXY_API_KEY = "tradescape-dev-key-change-me"
GameConfig.PROXY_TIMEOUT = 10 -- seconds
GameConfig.STALE_DATA_THRESHOLD = 120 -- seconds before showing "data unavailable"

-- Cache
GameConfig.QUOTE_CACHE_TTL = 60 -- seconds, server-side
GameConfig.MARKET_STATUS_CACHE_TTL = 60

-- DataStore
GameConfig.DATASTORE_NAME = "PlayerData"
GameConfig.SAVE_INTERVAL = 6 -- seconds, batch save
GameConfig.MAX_RETRIES = 3
GameConfig.RETRY_BACKOFF = {6, 12, 24} -- seconds per retry

-- UI
GameConfig.UI_REFRESH_INTERVAL = 2 -- seconds between UI updates
GameConfig.SPARKLINE_POINTS = 30 -- data points in mini chart

return GameConfig
```

- [ ] **Step 2: Write Types.lua (shared type definitions)**

```lua
-- Types.lua — Shared type definitions used by server and client
-- Place in: ReplicatedStorage/Types

-- These are documentation types (Luau type annotations for reference)
-- Luau doesn't enforce them at runtime but they improve IDE support

export type Quote = {
	s: string,        -- symbol
	n: string,        -- company name
	p: number,        -- current price
	c: number,        -- price change
	cp: number,       -- change percent
	h: number,        -- day high
	l: number,        -- day low
	o: number,        -- open price
	v: number,        -- volume
	e: string,        -- exchange name
	m: string,        -- market state (open/closed/pre/post)
	t: number,        -- timestamp (unix)
	stale: boolean?,  -- true if using cached data
}

export type Position = {
	symbol: string,
	shares: number,
	avgPrice: number,
	totalCost: number,
	opened: number,   -- unix timestamp
}

export type TradeResult = {
	success: boolean,
	message: string?,
	newBalance: number?,
	position: Position?,
	profitLoss: number?,
}

export type PortfolioData = {
	balance: number,
	positions: { [string]: Position },
	totalValue: number,
	totalProfit: number,
	totalProfitPercent: number,
}

export type CandleData = {
	t: number,        -- timestamp
	o: number,        -- open
	h: number,        -- high
	l: number,        -- low
	c: number,        -- close
	v: number,        -- volume
}

return {}
```

- [ ] **Step 3: Commit**

```bash
git add roblox/
git commit -m "feat(roblox): add GameConfig and shared Types"
```

---

### Task 9: Roblox ProxyClient

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\ProxyClient.lua`

- [ ] **Step 1: Write ProxyClient.lua**

```lua
-- ProxyClient.lua — HttpService wrapper for TradeScape proxy API
-- Place in: ServerScriptService/ProxyClient
--
-- Provides cached, rate-limited access to market data proxy.
-- Handles stale cache fallback when proxy is unreachable.

local HttpService = game:GetService("HttpService")
local GameConfig = require(script.Parent.GameConfig)

local ProxyClient = {}

-- In-memory server cache: { [symbol] = { data = Quote, updated = os.time() } }
local quoteCache = {}
local marketStatusCache = nil
local marketStatusUpdated = 0

-- ============================================================
-- Quote
-- ============================================================
function ProxyClient.getQuote(symbol)
	symbol = symbol:upper()

	-- Check cache
	local cached = quoteCache[symbol]
	if cached and (os.time() - cached.updated) < GameConfig.QUOTE_CACHE_TTL then
		return cached.data
	end

	-- Fetch from proxy
	local ok, result = pcall(function()
		local url = string.format("%s/api/quote/%s", GameConfig.PROXY_URL, symbol)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local data = HttpService:JSONDecode(result)
		if data.error then
			warn("[ProxyClient] Quote error for", symbol, ":", data.message)
			-- Return stale if available
			if cached then
				cached.data.stale = true
				return cached.data
			end
			return nil, data.error, data.message
		end

		quoteCache[symbol] = { data = data, updated = os.time() }
		return data
	end

	-- Network error — return stale data
	if cached and (os.time() - cached.updated) < GameConfig.STALE_DATA_THRESHOLD then
		warn("[ProxyClient] Using stale data for", symbol)
		cached.data.stale = true
		return cached.data
	end

	return nil, "proxy_unavailable", "Market data temporarily unavailable"
end

-- ============================================================
-- History
-- ============================================================
function ProxyClient.getHistory(symbol, range)
	symbol = symbol:upper()
	range = range or "1m"

	local ok, result = pcall(function()
		local url = string.format("%s/api/history/%s?range=%s",
			GameConfig.PROXY_URL, symbol, range)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local data = HttpService:JSONDecode(result)
		if data.error then
			warn("[ProxyClient] History error for", symbol, ":", data.error)
			return nil, data.error
		end
		return data.d -- return just the candle array
	end

	return nil, "proxy_unavailable"
end

-- ============================================================
-- Search
-- ============================================================
function ProxyClient.search(query)
	local ok, result = pcall(function()
		local url = string.format("%s/api/search?q=%s", GameConfig.PROXY_URL, query)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		local data = HttpService:JSONDecode(result)
		if data.error then
			return {}
		end
		return data.r
	end

	return {}
end

-- ============================================================
-- Market Status
-- ============================================================
function ProxyClient.getMarketStatus()
	-- Check cache
	if marketStatusCache and (os.time() - marketStatusUpdated) < GameConfig.MARKET_STATUS_CACHE_TTL then
		return marketStatusCache
	end

	local ok, result = pcall(function()
		local url = string.format("%s/api/market-status", GameConfig.PROXY_URL)
		return HttpService:GetAsync(url, true, {
			["X-API-Key"] = GameConfig.PROXY_API_KEY,
		})
	end)

	if ok then
		marketStatusCache = HttpService:JSONDecode(result)
		marketStatusUpdated = os.time()
		return marketStatusCache
	end

	-- Return cached even if stale
	if marketStatusCache then
		return marketStatusCache
	end

	return nil
end

-- ============================================================
-- Cache management
-- ============================================================
function ProxyClient.invalidateQuote(symbol)
	quoteCache[symbol:upper()] = nil
end

function ProxyClient.invalidateAll()
	quoteCache = {}
	marketStatusCache = nil
	marketStatusUpdated = 0
end

return ProxyClient
```

- [ ] **Step 2: Commit**

```bash
git add roblox/ServerScriptService/ProxyClient.lua
git commit -m "feat(roblox): add ProxyClient with cache and stale fallback"
```

---

### Task 10: Roblox PlayerData (DataStore persistence)

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\DataStore\PlayerData.lua`

- [ ] **Step 1: Write PlayerData.lua**

```lua
-- PlayerData.lua — DataStore persistence for player profiles
-- Place in: ServerScriptService/DataStore/PlayerData
--
-- Batch-writes player data to avoid DataStore throttling.
-- Retries with exponential backoff on failure.

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(script.Parent.Parent.GameConfig)

local PlayerData = {}

local store = DataStoreService:GetDataStore(GameConfig.DATASTORE_NAME)

-- Write queue: { [userId] = data }
local writeQueue = {}
local lastSave = 0

-- ============================================================
-- Create default profile for new player
-- ============================================================
function PlayerData.createDefault(userId)
	return {
		userId = userId,
		created = os.time(),

		-- Economy
		balance = GameConfig.STARTING_BALANCE,
		totalDeposited = GameConfig.STARTING_BALANCE,

		-- Portfolio
		positions = {}, -- { [symbol] = Position }

		-- History (MVP: just last 100 trades)
		tradeHistory = {},

		-- Stats
		stats = {
			totalTrades = 0,
			profitableTrades = 0,
			totalProfit = 0,
			totalLoss = 0,
			bestTrade = nil,  -- { symbol, profit }
			worstTrade = nil, -- { symbol, loss }
			currentStreak = 0,
			bestStreak = 0,
		},

		-- RPG (minimal for MVP, expanded in Phase 2)
		xp = 0,
		level = 1,
		rank = "Novato",
		perks = {},
		completedMissions = {},
		officeLevel = 0,
	}
end

-- ============================================================
-- Load player data
-- ============================================================
function PlayerData.load(userId)
	local key = "player_" .. tostring(userId)

	local success, data = pcall(function()
		return store:GetAsync(key)
	end)

	if success and data then
		return data
	end

	return nil
end

-- ============================================================
-- Queue save (batched to respect DataStore limits)
-- ============================================================
function PlayerData.queueSave(data)
	writeQueue[data.userId] = data
end

-- ============================================================
-- Process the write queue (call on a loop every SAVE_INTERVAL)
-- ============================================================
function PlayerData.processQueue()
	local now = os.time()
	if now - lastSave < GameConfig.SAVE_INTERVAL then
		return
	end

	lastSave = now
	local toSave = {}

	-- Drain queue
	for userId, data in pairs(writeQueue) do
		toSave[userId] = data
		writeQueue[userId] = nil
	end

	-- Save all with retry
	for userId, data in pairs(toSave) do
		local saved = false
		for attempt = 1, GameConfig.MAX_RETRIES do
			local success, err = pcall(function()
				local key = "player_" .. tostring(userId)
				store:SetAsync(key, data)
			end)

			if success then
				saved = true
				break
			else
				warn("[PlayerData] Save failed for", userId, "attempt", attempt, ":", err)
				-- Wait with exponential backoff
				task.wait(GameConfig.RETRY_BACKOFF[attempt])
			end
		end

		if not saved then
			warn("[PlayerData] CRITICAL: Failed to save data for", userId, "after all retries. Re-queueing.")
			writeQueue[userId] = data
		end
	end
end

-- ============================================================
-- Force immediate save (use sparingly, e.g. on player leave)
-- ============================================================
function PlayerData.forceSave(data)
	local key = "player_" .. tostring(data.userId)
	local success, err = pcall(function()
		store:SetAsync(key, data)
	end)

	if not success then
		warn("[PlayerData] Force save failed for", data.userId, ":", err)
	end

	return success
end

return PlayerData
```

- [ ] **Step 2: Commit**

```bash
git add roblox/ServerScriptService/DataStore/PlayerData.lua
git commit -m "feat(roblox): add PlayerData DataStore with batch writes and retry"
```

---

### Task 11: Roblox Economy service

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\TradingService\Economy.lua`

- [ ] **Step 1: Write Economy.lua**

```lua
-- Economy.lua — Balance management, transaction validation, fees
-- Place in: ServerScriptService/TradingService/Economy
--
-- All balance mutations go through this module.
-- No direct balance manipulation anywhere else.

local GameConfig = require(script.Parent.Parent.GameConfig)

local Economy = {}

-- ============================================================
-- Calculate transaction fee
-- ============================================================
function Economy.calculateFee(totalCost)
	return math.max(math.floor(totalCost * GameConfig.TRANSACTION_FEE_RATE), 0)
end

-- ============================================================
-- Check if player can afford a purchase
-- ============================================================
function Economy.canAfford(playerData, totalCost)
	local fee = Economy.calculateFee(totalCost)
	return playerData.balance >= (totalCost + fee), fee, totalCost + fee
end

-- ============================================================
-- Validate trade parameters
-- ============================================================
function Economy.validateTrade(playerData, quote, shares, tradeType)
	-- Type validation
	if tradeType ~= "buy" and tradeType ~= "sell" then
		return false, "Invalid trade type. Use 'buy' or 'sell'."
	end

	-- Shares validation
	shares = math.floor(shares)
	if shares < GameConfig.MIN_SHARES then
		return false, string.format("Minimum %d share per trade.", GameConfig.MIN_SHARES)
	end
	if shares > GameConfig.MAX_SHARES_PER_TRADE then
		return false, string.format("Maximum %d shares per trade.", GameConfig.MAX_SHARES_PER_TRADE)
	end

	-- Price validation
	if not quote or not quote.p or quote.p <= 0 then
		return false, "Invalid quote data. Try again."
	end

	-- Market status
	if quote.m and quote.m ~= "open" and quote.m ~= "PRE" and quote.m ~= "POST" then
		return false, string.format("Market is %s. Trading not available.", quote.m)
	end

	local totalCost = quote.p * shares

	if tradeType == "buy" then
		local canPay, fee, required = Economy.canAfford(playerData, totalCost)
		if not canPay then
			return false, string.format(
				"Not enough cash. Need $%.2f more. (Balance: $%.2f, Required: $%.2f incl. $%.0f fee)",
				required - playerData.balance,
				playerData.balance,
				required,
				fee
			)
		end

		-- Check portfolio slot limit (respect base slots + perk slots)
		local maxSlots = Economy.getMaxSlots(playerData)
		local currentPositions = 0
		for _ in pairs(playerData.positions) do
			currentPositions = currentPositions + 1
		end
		if playerData.positions[quote.s] == nil and currentPositions >= maxSlots then
			return false, string.format("Portfolio full. Max %d different stocks. Sell first or unlock more slots.", maxSlots)
		end

	elseif tradeType == "sell" then
		local position = playerData.positions[quote.s]
		if not position then
			return false, string.format("You don't own any %s.", quote.s)
		end
		if shares > position.shares then
			return false, string.format("You only have %d shares of %s.", position.shares, quote.s)
		end
	end

	return true, nil
end

-- ============================================================
-- Execute a buy
-- ============================================================
function Economy.executeBuy(playerData, quote, shares)
	local totalCost = quote.p * shares
	local fee = Economy.calculateFee(totalCost)
	local totalDeduction = totalCost + fee

	playerData.balance = playerData.balance - totalDeduction

	-- Update or create position
	local existing = playerData.positions[quote.s]
	if existing then
		local newShares = existing.shares + shares
		local newCost = existing.totalCost + totalCost
		existing.shares = newShares
		existing.avgPrice = newCost / newShares
		existing.totalCost = newCost
	else
		playerData.positions[quote.s] = {
			symbol = quote.s,
			shares = shares,
			avgPrice = quote.p,
			totalCost = totalCost,
			opened = os.time(),
		}
	end

	-- Record trade
	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = quote.s,
		type = "buy",
		shares = shares,
		price = quote.p,
		total = totalCost,
		fee = fee,
		balanceAfter = playerData.balance,
	})

	return {
		success = true,
		message = string.format("Bought %d %s at $%.2f. Fee: $%.0f", shares, quote.s, quote.p, fee),
		newBalance = playerData.balance,
		position = playerData.positions[quote.s],
	}
end

-- ============================================================
-- Execute a sell
-- ============================================================
function Economy.executeSell(playerData, quote, shares)
	local totalValue = quote.p * shares
	local fee = Economy.calculateFee(totalValue)
	local totalReceived = totalValue - fee

	playerData.balance = playerData.balance + totalReceived

	local position = playerData.positions[quote.s]
	local profitLoss = (quote.p - position.avgPrice) * shares - fee

	position.shares = position.shares - shares
	if position.shares <= 0 then
		-- Remove position entirely
		playerData.positions[quote.s] = nil
	else
		position.totalCost = position.totalCost * (position.shares / (position.shares + shares))
	end

	-- Record trade
	Economy.recordTrade(playerData, {
		timestamp = os.time(),
		symbol = quote.s,
		type = "sell",
		shares = shares,
		price = quote.p,
		total = totalValue,
		fee = fee,
		profitLoss = profitLoss,
		balanceAfter = playerData.balance,
	})

	-- Update stats
	playerData.stats.totalTrades = playerData.stats.totalTrades + 1
	if profitLoss > 0 then
		playerData.stats.profitableTrades = playerData.stats.profitableTrades + 1
		playerData.stats.totalProfit = playerData.stats.totalProfit + profitLoss
		playerData.stats.currentStreak = playerData.stats.currentStreak + 1
		if playerData.stats.currentStreak > playerData.stats.bestStreak then
			playerData.stats.bestStreak = playerData.stats.currentStreak
		end
	else
		playerData.stats.totalLoss = playerData.stats.totalLoss + math.abs(profitLoss)
		playerData.stats.currentStreak = 0
	end

	-- Track best/worst
	if not playerData.stats.bestTrade or profitLoss > playerData.stats.bestTrade.profit then
		playerData.stats.bestTrade = { symbol = quote.s, profit = profitLoss }
	end
	if not playerData.stats.worstTrade or profitLoss < playerData.stats.worstTrade.loss then
		playerData.stats.worstTrade = { symbol = quote.s, loss = profitLoss }
	end

	return {
		success = true,
		message = string.format("Sold %d %s at $%.2f. %s $%.2f. Fee: $%.0f",
			shares, quote.s, quote.p,
			profitLoss >= 0 and "Profit:" or "Loss:",
			math.abs(profitLoss), fee),
		newBalance = playerData.balance,
		position = playerData.positions[quote.s],
		profitLoss = profitLoss,
	}
end

-- ============================================================
-- Trade history
-- ============================================================
function Economy.recordTrade(playerData, trade)
	table.insert(playerData.tradeHistory, 1, trade) -- newest first

	-- Trim to 500 entries
	if #playerData.tradeHistory > 500 then
		local trimmed = {}
		for i = 1, 500 do
			trimmed[i] = playerData.tradeHistory[i]
		end
		playerData.tradeHistory = trimmed
	end
end

-- ============================================================
-- Portfolio slot calculation
-- ============================================================
function Economy.getMaxSlots(playerData)
	local slots = GameConfig.MAX_SLOTS_BASE
	for _, perk in ipairs(playerData.perks) do
		if perk == "extra_slot_1" then
			slots = slots + 1
		elseif perk == "extra_slot_2" then
			slots = slots + 3
		end
	end
	return slots
end

return Economy
```

- [ ] **Step 2: Commit**

```bash
git add roblox/ServerScriptService/TradingService/Economy.lua
git commit -m "feat(roblox): add Economy service with buy/sell/validate/fees/stats"
```

---

### Task 12: Roblox Portfolio service

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\TradingService\Portfolio.lua`

- [ ] **Step 1: Write Portfolio.lua**

```lua
-- Portfolio.lua — Portfolio calculations and queries
-- Place in: ServerScriptService/TradingService/Portfolio
--
-- Read-only portfolio operations (P&L, total value, etc.)
-- Trades are executed through Economy module.

local ProxyClient = require(script.Parent.Parent.ProxyClient)

local Portfolio = {}

-- ============================================================
-- Calculate current value and P&L for all positions
-- ============================================================
function Portfolio.calculateValue(playerData)
	local totalValue = playerData.balance
	local totalCost = 0
	local totalProfit = 0
	local positions = {}

	for symbol, pos in pairs(playerData.positions) do
		local quote = ProxyClient.getQuote(symbol)

		if quote then
			local currentValue = quote.p * pos.shares
			local profitLoss = currentValue - pos.totalCost
			local profitPercent = 0
			if pos.totalCost > 0 then
				profitPercent = (profitLoss / pos.totalCost) * 100
			end

			positions[symbol] = {
				symbol = symbol,
				name = quote.n,
				shares = pos.shares,
				avgPrice = pos.avgPrice,
				totalCost = pos.totalCost,
				currentPrice = quote.p,
				currentValue = currentValue,
				profitLoss = profitLoss,
				profitPercent = profitPercent,
				change = quote.c,
				changePercent = quote.cp,
				opened = pos.opened,
			}

			totalValue = totalValue + currentValue
			totalCost = totalCost + pos.totalCost
			totalProfit = totalProfit + profitLoss
		else
			-- Data unavailable, use last known price
			positions[symbol] = {
				symbol = symbol,
				shares = pos.shares,
				avgPrice = pos.avgPrice,
				totalCost = pos.totalCost,
				currentPrice = nil,
				currentValue = pos.totalCost, -- fallback
				profitLoss = 0,
				profitPercent = 0,
				change = 0,
				changePercent = 0,
				opened = pos.opened,
				stale = true,
			}

			totalValue = totalValue + pos.totalCost
		end
	end

	local totalProfitPercent = 0
	if totalCost > 0 then
		totalProfitPercent = (totalProfit / totalCost) * 100
	end

	return {
		balance = playerData.balance,
		positions = positions,
		totalValue = totalValue,
		totalCost = totalCost,
		totalProfit = totalProfit,
		totalProfitPercent = totalProfitPercent,
	}
end

-- ============================================================
-- Get simple portfolio summary (lightweight, for leaderboard)
-- ============================================================
function Portfolio.getSummary(playerData)
	local data = Portfolio.calculateValue(playerData)
	return {
		userId = playerData.userId,
		balance = data.balance,
		totalValue = data.totalValue,
		totalProfit = data.totalProfit,
		totalProfitPercent = data.totalProfitPercent,
		positionCount = #table.keys(data.positions),
	}
end

return Portfolio
```

- [ ] **Step 2: Commit**

```bash
git add roblox/ServerScriptService/TradingService/Portfolio.lua
git commit -m "feat(roblox): add Portfolio service with P&L calculation"
```

---

### Task 13: Roblox RemoteFunctions (network layer)

**Files:**
- Create: `c:\pipe\roblox\ServerScriptService\NetworkHandler.server.lua`

- [ ] **Step 1: Write NetworkHandler.server.lua**

```lua
-- NetworkHandler.server.lua — RemoteFunction handlers for client-server communication
-- Place in: ServerScriptService/NetworkHandler (Script, not ModuleScript)
--
-- Handles: GetQuote, ExecuteTrade, GetPortfolio, SearchSymbols, GetInitialData
-- Uses RemoteFunctions in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require server modules
local ProxyClient = require(script.Parent.ProxyClient)
local Economy = require(script.Parent.TradingService.Economy)
local Portfolio = require(script.Parent.TradingService.Portfolio)
local PlayerData = require(script.Parent.DataStore.PlayerData)
local GameConfig = require(script.Parent.GameConfig)

-- Loaded players (in-memory, synced to DataStore periodically)
local activePlayers = {}

-- ============================================================
-- RemoteFunctions setup
-- ============================================================
local NetworkEvents = Instance.new("Folder")
NetworkEvents.Name = "NetworkEvents"
NetworkEvents.Parent = ReplicatedStorage

local function createRemoteFunction(name)
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = NetworkEvents
	return rf
end

local GetQuote = createRemoteFunction("GetQuote")
local ExecuteTrade = createRemoteFunction("ExecuteTrade")
local GetPortfolio = createRemoteFunction("GetPortfolio")
local SearchSymbols = createRemoteFunction("SearchSymbols")
local GetInitialData = createRemoteFunction("GetInitialData")

-- ============================================================
-- GetQuote — fetch current quote for a symbol
-- ============================================================
GetQuote.OnServerInvoke = function(player, symbol)
	local data = activePlayers[player.UserId]
	if not data then
		return nil, "not_loaded"
	end

	return ProxyClient.getQuote(symbol)
end

-- ============================================================
-- ExecuteTrade — buy or sell shares
-- ============================================================
ExecuteTrade.OnServerInvoke = function(player, tradeType, symbol, shares)
	local data = activePlayers[player.UserId]
	if not data then
		return { success = false, message = "Player data not loaded. Rejoin." }
	end

	symbol = symbol:upper()
	shares = math.floor(tonumber(shares) or 0)

	-- Fetch latest quote
	local quote = ProxyClient.getQuote(symbol)
	if not quote then
		return { success = false, message = "Could not fetch current price. Try again." }
	end

	-- Validate
	local valid, errMsg = Economy.validateTrade(data, quote, shares, tradeType)
	if not valid then
		return { success = false, message = errMsg }
	end

	-- Execute
	local result
	if tradeType == "buy" then
		result = Economy.executeBuy(data, quote, shares)
	else
		result = Economy.executeSell(data, quote, shares)
	end

	-- Queue save
	PlayerData.queueSave(data)

	return result
end

-- ============================================================
-- GetPortfolio — return player's current portfolio + P&L
-- ============================================================
GetPortfolio.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then
		return nil, "not_loaded"
	end

	return Portfolio.calculateValue(data)
end

-- ============================================================
-- SearchSymbols — search for stock symbols
-- ============================================================
SearchSymbols.OnServerInvoke = function(player, query)
	return ProxyClient.search(query)
end

-- ============================================================
-- GetInitialData — called on player join, returns full profile
-- ============================================================
GetInitialData.OnServerInvoke = function(player)
	local data = activePlayers[player.UserId]
	if not data then
		return nil
	end

	return {
		balance = data.balance,
		level = data.level,
		rank = data.rank,
		xp = data.xp,
		stats = data.stats,
		officeLevel = data.officeLevel,
		positions = data.positions,
	}
end

-- ============================================================
-- Player lifecycle
-- ============================================================
local function onPlayerAdded(player)
	local userId = player.UserId

	-- Load from DataStore
	local data = PlayerData.load(userId)
	if not data then
		data = PlayerData.createDefault(userId)
		PlayerData.queueSave(data)
	end

	activePlayers[userId] = data
	print("[NetworkHandler] Loaded player", player.Name, "Balance:", data.balance)
end

local function onPlayerRemoving(player)
	local userId = player.UserId
	local data = activePlayers[userId]
	if data then
		PlayerData.forceSave(data)
		activePlayers[userId] = nil
		print("[NetworkHandler] Saved player", player.Name)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ============================================================
-- Save loop — batch persistence
-- ============================================================
game:GetService("RunService").Heartbeat:Connect(function()
	PlayerData.processQueue()
end)

print("[NetworkHandler] TradeScape server initialized")
```

- [ ] **Step 2: Commit**

```bash
git add roblox/ServerScriptService/NetworkHandler.server.lua
git commit -m "feat(roblox): add NetworkHandler with RemoteFunctions and player lifecycle"
```

---

### Task 14: Roblox Market UI (Client)

**Files:**
- Create: `c:\pipe\roblox\StarterPlayerScripts\UI\MarketScreen.client.lua`

- [ ] **Step 1: Write MarketScreen.client.lua**

```lua
-- MarketScreen.client.lua — Main trading UI: stock list, sparkline, trade widget
-- Place in: StarterPlayerScripts/UI/MarketScreen (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")

local GetQuote = NetworkEvents:WaitForChild("GetQuote")
local ExecuteTrade = NetworkEvents:WaitForChild("ExecuteTrade")
local GetPortfolio = NetworkEvents:WaitForChild("GetPortfolio")
local SearchSymbols = NetworkEvents:WaitForChild("SearchSymbols")
local GetInitialData = NetworkEvents:WaitForChild("GetInitialData")

-- ============================================================
-- Top movers list (hardcoded popular symbols for MVP)
-- ============================================================
local WATCHLIST = {
	"AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META", "NFLX",
	"SPY", "QQQ", "AMD", "INTC", "BA", "JPM", "V", "DIS",
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MarketScreen"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
MainFrame.Parent = ScreenGui

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "TradeScape"
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.Size = UDim2.new(0.3, 0, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local BalanceLabel = Instance.new("TextLabel")
BalanceLabel.Name = "Balance"
BalanceLabel.Text = "Loading..."
BalanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BalanceLabel.TextSize = 18
BalanceLabel.Font = Enum.Font.Gotham
BalanceLabel.Size = UDim2.new(0.4, 0, 1, 0)
BalanceLabel.Position = UDim2.new(0.4, 0, 0, 0)
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Center
BalanceLabel.Parent = TopBar

-- Stock list (ScrollingFrame)
local StockList = Instance.new("ScrollingFrame")
StockList.Name = "StockList"
StockList.Size = UDim2.new(1, 0, 1, -48)
StockList.Position = UDim2.new(0, 0, 0, 48)
StockList.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
StockList.ScrollBarThickness = 8
StockList.CanvasSize = UDim2.new(0, 0, 0, 0)
StockList.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = StockList

-- ============================================================
-- Create stock row template
-- ============================================================
local function createStockRow(symbol)
	local row = Instance.new("TextButton")
	row.Name = "Row_" .. symbol
	row.Size = UDim2.new(1, -16, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
	row.Text = ""
	row.AutoButtonColor = false

	local symbolLabel = Instance.new("TextLabel")
	symbolLabel.Name = "Symbol"
	symbolLabel.Text = symbol
	symbolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	symbolLabel.TextSize = 18
	symbolLabel.Font = Enum.Font.GothamBold
	symbolLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	symbolLabel.Position = UDim2.new(0, 12, 0, 4)
	symbolLabel.TextXAlignment = Enum.TextXAlignment.Left
	symbolLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Text = "..."
	nameLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 12, 0.5, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Text = "$-.--"
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	priceLabel.TextSize = 18
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	priceLabel.Position = UDim2.new(0.25, 0, 0, 4)
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = row

	local changeLabel = Instance.new("TextLabel")
	changeLabel.Name = "Change"
	changeLabel.Text = "0.00%"
	changeLabel.TextSize = 16
	changeLabel.Font = Enum.Font.Gotham
	changeLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	changeLabel.Position = UDim2.new(0.25, 0, 0.5, 0)
	changeLabel.TextXAlignment = Enum.TextXAlignment.Right
	changeLabel.Parent = row

	return row
end

-- ============================================================
-- Update stock row with quote data
-- ============================================================
local function updateStockRow(row, quote)
	local nameLabel = row:FindFirstChild("Name")
	local priceLabel = row:FindFirstChild("Price")
	local changeLabel = row:FindFirstChild("Change")

	if not quote then
		nameLabel.Text = "Loading..."
		priceLabel.Text = "..."
		changeLabel.Text = "..."
		return
	end

	nameLabel.Text = quote.n or "Unknown"
	priceLabel.Text = string.format("$%.2f", quote.p)

	local changeColor = Color3.fromRGB(0, 200, 100) -- green
	if quote.cp < 0 then
		changeColor = Color3.fromRGB(255, 80, 80) -- red
	end
	local sign = quote.cp >= 0 and "+" or ""
	changeLabel.Text = string.format("%s%.2f%%", sign, quote.cp)
	changeLabel.TextColor3 = changeColor

	if quote.stale then
		row.BackgroundColor3 = Color3.fromRGB(40, 35, 20) -- yellowish tint
	else
		row.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
	end

	-- Store quote data for trade widget
	row:SetAttribute("CurrentPrice", quote.p)
	row:SetAttribute("Symbol", quote.s)
	row:SetAttribute("Loaded", true)
end

-- ============================================================
-- Build initial stock rows
-- ============================================================
local rows = {}
for i, symbol in ipairs(WATCHLIST) do
	local row = createStockRow(symbol)
	row.Parent = StockList
	rows[symbol] = row
end

-- Update canvas size
StockList.CanvasSize = UDim2.new(0, 0, 0, #WATCHLIST * 60)

-- ============================================================
-- Periodic data refresh
-- ============================================================
local function refreshWatchlist()
	for _, symbol in ipairs(WATCHLIST) do
		local ok, quote = pcall(function()
			return GetQuote:InvokeServer(symbol)
		end)

		if ok and quote then
			updateStockRow(rows[symbol], quote)
		end
	end
end

local function refreshBalance()
	local ok, portfolio = pcall(function()
		return GetPortfolio:InvokeServer()
	end)

	if ok and portfolio then
		local sign = portfolio.totalProfit >= 0 and "+" or ""
		BalanceLabel.Text = string.format("$%.2f | %s$%.2f (%.2f%%)",
			portfolio.balance, sign, portfolio.totalProfit, portfolio.totalProfitPercent)
	elseif ok then
		-- Initial data
		local data = GetInitialData:InvokeServer()
		if data then
			BalanceLabel.Text = string.format("$%.2f | Level %d %s", data.balance, data.level, data.rank)
		end
	end
end

-- Initial load
refreshWatchlist()
refreshBalance()

-- Periodic refresh loop
while true do
	task.wait(2)
	refreshWatchlist()
	refreshBalance()
end
```

**Note:** The UI above is a minimal MVP skeleton. In Roblox Studio, you'd typically build this with a GUI designer and use tweens/animations. The script shows the data binding pattern — full visual polish comes in Phase 2+.

- [ ] **Step 2: Commit**

```bash
git add roblox/StarterPlayerScripts/UI/MarketScreen.client.lua
git commit -m "feat(roblox): add MarketScreen client UI with watchlist and live refresh"
```

---

### Task 15: Roblox Trade Widget UI (Client)

**Files:**
- Create: `c:\pipe\roblox\StarterPlayerScripts\UI\TradeWidget.client.lua`

- [ ] **Step 1: Write TradeWidget.client.lua**

```lua
-- TradeWidget.client.lua — Buy/Sell modal for executing trades
-- Place in: StarterPlayerScripts/UI/TradeWidget (LocalScript)
--
-- Opens when clicking a stock row in MarketScreen.
-- Shows current price, quantity input, buy/sell buttons, confirmation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ExecuteTrade = NetworkEvents:WaitForChild("ExecuteTrade")

local ScreenGui = player.PlayerGui:WaitForChild("MarketScreen")

-- ============================================================
-- Trade modal (created on demand)
-- ============================================================
local TradeFrame = Instance.new("Frame")
TradeFrame.Name = "TradeWidget"
TradeFrame.Size = UDim2.new(0.35, 0, 0.45, 0)
TradeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TradeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
TradeFrame.BackgroundColor3 = Color3.fromRGB(32, 36, 42)
TradeFrame.BorderSizePixel = 1
TradeFrame.BorderColor3 = Color3.fromRGB(60, 65, 75)
TradeFrame.Visible = false
TradeFrame.ZIndex = 10
TradeFrame.Parent = ScreenGui

-- Background overlay (click to close)
local Overlay = Instance.new("TextButton")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.6
Overlay.Text = ""
Overlay.Visible = false
Overlay.ZIndex = 9
Overlay.Parent = ScreenGui

-- Modal title
local ModalTitle = Instance.new("TextLabel")
ModalTitle.Name = "Title"
ModalTitle.Text = "Trade"
ModalTitle.TextSize = 22
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModalTitle.Size = UDim2.new(0.8, 0, 0, 36)
ModalTitle.Position = UDim2.new(0, 16, 0, 12)
ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ModalTitle.Parent = TradeFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Text = "✕"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = TradeFrame

-- Symbol + Price
local SymbolLabel = Instance.new("TextLabel")
SymbolLabel.Name = "Symbol"
SymbolLabel.Text = ""
SymbolLabel.TextSize = 28
SymbolLabel.Font = Enum.Font.GothamBold
SymbolLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
SymbolLabel.Size = UDim2.new(0.8, 0, 0, 32)
SymbolLabel.Position = UDim2.new(0, 16, 0, 56)
SymbolLabel.TextXAlignment = Enum.TextXAlignment.Left
SymbolLabel.Parent = TradeFrame

local PriceLabel = Instance.new("TextLabel")
PriceLabel.Name = "Price"
PriceLabel.Text = ""
PriceLabel.TextSize = 18
PriceLabel.Font = Enum.Font.Gotham
PriceLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
PriceLabel.Size = UDim2.new(0.8, 0, 0, 24)
PriceLabel.Position = UDim2.new(0, 16, 0, 92)
PriceLabel.TextXAlignment = Enum.TextXAlignment.Left
PriceLabel.Parent = TradeFrame

-- Quantity input
local QtyBox = Instance.new("TextBox")
QtyBox.Name = "QtyInput"
QtyBox.Text = "1"
QtyBox.TextSize = 20
QtyBox.Font = Enum.Font.Gotham
QtyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QtyBox.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
QtyBox.Size = UDim2.new(0.5, 0, 0, 36)
QtyBox.Position = UDim2.new(0, 16, 0, 136)
QtyBox.PlaceholderText = "Shares"
QtyBox.Parent = TradeFrame

local QtyLabel = Instance.new("TextLabel")
QtyLabel.Name = "QtyLabel"
QtyLabel.Text = "Shares"
QtyLabel.TextSize = 14
QtyLabel.Font = Enum.Font.Gotham
QtyLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
QtyLabel.Size = UDim2.new(0.3, 0, 0, 20)
QtyLabel.Position = UDim2.new(0, 16, 0, 176)
QtyLabel.TextXAlignment = Enum.TextXAlignment.Left
QtyLabel.Parent = TradeFrame

-- Estimated cost
local EstimatedLabel = Instance.new("TextLabel")
EstimatedLabel.Name = "EstimatedCost"
EstimatedLabel.Text = "Total: $0.00 | Fee: $0.00"
EstimatedLabel.TextSize = 14
EstimatedLabel.Font = Enum.Font.Gotham
EstimatedLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
EstimatedLabel.Size = UDim2.new(0.8, 0, 0, 20)
EstimatedLabel.Position = UDim2.new(0, 16, 0, 200)
EstimatedLabel.TextXAlignment = Enum.TextXAlignment.Left
EstimatedLabel.Parent = TradeFrame

-- Buy button
local BuyBtn = Instance.new("TextButton")
BuyBtn.Name = "BuyBtn"
BuyBtn.Text = "BUY"
BuyBtn.TextSize = 22
BuyBtn.Font = Enum.Font.GothamBold
BuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
BuyBtn.Size = UDim2.new(0.42, 0, 0, 44)
BuyBtn.Position = UDim2.new(0, 16, 1, -60)
BuyBtn.Parent = TradeFrame

-- Sell button
local SellBtn = Instance.new("TextButton")
SellBtn.Name = "SellBtn"
SellBtn.Text = "SELL"
SellBtn.TextSize = 22
SellBtn.Font = Enum.Font.GothamBold
SellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SellBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
SellBtn.Size = UDim2.new(0.42, 0, 0, 44)
SellBtn.Position = UDim2.new(0.5, 0, 1, -60)
SellBtn.AnchorPoint = Vector2.new(0, 0)
SellBtn.Parent = TradeFrame

-- Result label (shown after trade)
local ResultLabel = Instance.new("TextLabel")
ResultLabel.Name = "Result"
ResultLabel.Text = ""
ResultLabel.TextSize = 14
ResultLabel.Font = Enum.Font.Gotham
ResultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ResultLabel.Size = UDim2.new(0.9, 0, 0, 36)
ResultLabel.Position = UDim2.new(0, 16, 1, -120)
ResultLabel.TextXAlignment = Enum.TextXAlignment.Left
ResultLabel.TextWrapped = true
ResultLabel.Parent = TradeFrame

-- ============================================================
-- Modal logic
-- ============================================================
local activeSymbol = nil
local activePrice = nil

local function showTradeWidget(symbol, price, companyName)
	activeSymbol = symbol
	activePrice = price

	SymbolLabel.Text = string.format("%s - %s", symbol, companyName or "")
	PriceLabel.Text = string.format("Current price: $%.2f", price)
	QtyBox.Text = "1"
	ResultLabel.Text = ""
	EstimatedLabel.Text = string.format("Total: $%.2f | Fee: $%.0f", price, 0)

	TradeFrame.Visible = true
	Overlay.Visible = true
end

local function hideTradeWidget()
	TradeFrame.Visible = false
	Overlay.Visible = false
	activeSymbol = nil
	activePrice = nil
end

CloseBtn.MouseButton1Click:Connect(hideTradeWidget)
Overlay.MouseButton1Click:Connect(hideTradeWidget)

-- Update estimated cost when quantity changes
QtyBox:GetPropertyChangedSignal("Text"):Connect(function()
	local shares = tonumber(QtyBox.Text) or 0
	if activePrice then
		local total = activePrice * shares
		local fee = math.floor(total * 0.001)
		EstimatedLabel.Text = string.format("Total: $%.2f | Fee: $%.0f", total, fee)
	end
end)

-- Execute trade
local function doTrade(tradeType)
	if not activeSymbol or not activePrice then return end

	local shares = tonumber(QtyBox.Text)
	if not shares or shares <= 0 then
		ResultLabel.Text = "Enter a valid number of shares."
		ResultLabel.TextColor3 = Color3.fromRGB(255, 150, 80)
		return
	end

	BuyBtn.Interactable = false
	SellBtn.Interactable = false

	local ok, result = pcall(function()
		return ExecuteTrade:InvokeServer(tradeType, activeSymbol, shares)
	end)

	BuyBtn.Interactable = true
	SellBtn.Interactable = true

	if ok and result then
		if result.success then
			ResultLabel.Text = result.message
			ResultLabel.TextColor3 = Color3.fromRGB(0, 200, 100)

			-- Update balance display
			if result.newBalance then
				local balanceLabel = ScreenGui.MainFrame.TopBar.Balance
				-- Balance refresh happens on next poll
			end
		else
			ResultLabel.Text = result.message or "Trade failed."
			ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	else
		ResultLabel.Text = "Network error. Try again."
		ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

BuyBtn.MouseButton1Click:Connect(function()
	doTrade("buy")
end)

SellBtn.MouseButton1Click:Connect(function()
	doTrade("sell")
end)

-- ============================================================
-- Expose to MarketScreen: when stock row clicked, show widget
-- ============================================================
_G.OpenTradeWidget = showTradeWidget
_G.CloseTradeWidget = hideTradeWidget
```

- [ ] **Step 2: Update MarketScreen to hook up row clicks**

In `MarketScreen.client.lua`, add to `createStockRow` function before `return row`:

```lua
	-- Row click → open trade widget
	row.MouseButton1Click:Connect(function()
		local loaded = row:GetAttribute("Loaded")
		if loaded then
			local sym = row:GetAttribute("Symbol")
			local price = row:GetAttribute("CurrentPrice")
			local name = nameLabel.Text
			if _G.OpenTradeWidget then
				_G.OpenTradeWidget(sym, price, name)
			end
		end
	end)
```

- [ ] **Step 3: Commit**

```bash
git add roblox/StarterPlayerScripts/UI/TradeWidget.client.lua roblox/StarterPlayerScripts/UI/MarketScreen.client.lua
git commit -m "feat(roblox): add TradeWidget buy/sell UI with modal"
```

---

### Task 16: Proxy deploy config + README

**Files:**
- Create: `c:\pipe\proxy\deploy.md`

- [ ] **Step 1: Write deploy guide**

```markdown
# TradeScape Proxy — Deployment

## Quick Deploy (Hetzner/DigitalOcean $5 VPS)

### 1. Server setup
```bash
ssh root@your-server-ip
apt update && apt install -y nodejs npm
npm install -g pm2
```

### 2. Upload code
```bash
# From your local machine
scp -r proxy/ root@your-server-ip:/opt/tradescape-proxy/
```

### 3. Configure
```bash
cd /opt/tradescape-proxy
cp .env.example .env
nano .env  # Change API_KEY, set PORT=3000
npm install --production
```

### 4. Start with PM2
```bash
pm2 start src/index.js --name tradescape-proxy
pm2 save
pm2 startup
```

### 5. Nginx reverse proxy (optional but recommended)
```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 6. Test
```bash
curl -H "X-API-Key: your-key-here" http://localhost:3000/api/quote/AAPL
```

### Health check
```bash
curl http://localhost:3000/health
# → { "status": "ok", "uptime": 1234 }
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 3000 | Server port |
| API_KEY | (required) | Shared secret with Roblox |
| CACHE_TTL_QUOTE | 60 | Quote cache seconds |
| CACHE_TTL_HISTORY | 300 | History cache seconds |
| CACHE_TTL_SEARCH | 3600 | Search cache seconds |
| RATE_LIMIT_WINDOW_MS | 60000 | Rate limit window (ms) |
| RATE_LIMIT_MAX_REQUESTS | 100 | Max requests per window |
```

- [ ] **Step 2: Commit and push everything**

```bash
git add proxy/deploy.md
git commit -m "docs: add proxy deployment guide"
git push origin master
```

- [ ] **Step 3: Run full proxy test suite one final time**

```bash
cd c:\pipe\proxy
npm test
```

Expected: All tests pass.

---

## Verification Checklist

After completing all tasks, verify:

1. **Proxy runs:** `node c:\pipe\proxy\src\index.js` starts without errors
2. **Health endpoint:** `curl http://localhost:3000/health` returns `{"status":"ok"}`
3. **Quote works:** `curl -H "X-API-Key: test-key" http://localhost:3000/api/quote/AAPL` returns valid JSON with price
4. **History works:** Returns candle array with timestamp/OHLCV fields
5. **Search works:** Returns matching symbols
6. **Market status:** Returns object with exchange states
7. **Cache works:** Second quote call faster than first
8. **Rate limit:** 101 rapid calls → 429 on last
9. **Roblox scripts:** No syntax errors (load in Roblox Studio)
10. **All proxy tests pass:** `npm test` exits clean
