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
