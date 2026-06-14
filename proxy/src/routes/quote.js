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
