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

router.post('/api/quotes', async (req, res) => {
  const { symbols } = req.body;

  if (!Array.isArray(symbols) || symbols.length === 0) {
    return res.status(400).json({ error: 'invalid_request', message: 'Body must contain symbols array' });
  }

  if (symbols.length > 20) {
    return res.status(400).json({ error: 'invalid_request', message: 'Max 20 symbols per batch' });
  }

  try {
    const results = await Promise.all(
      symbols.map(async (sym) => {
        const upper = sym.toUpperCase();
        try {
          return await withCache('quote', upper, () => getQuote(upper));
        } catch {
          return { s: upper, error: 'fetch_failed' };
        }
      })
    );

    res.json({ quotes: results });
  } catch (err) {
    console.error('[quotes] Batch error:', err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch batch quotes' });
  }
});

export default router;
