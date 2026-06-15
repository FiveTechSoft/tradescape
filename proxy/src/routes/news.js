import { Router } from 'express';
import { getNews, getMarketNews } from '../services/yahoo.js';
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

router.get('/api/news', async (req, res) => {
  try {
    const result = await withCache('news', '_market', () => getMarketNews());
    res.json(result);
  } catch (err) {
    console.error('[news] Error fetching market news:', err.message);
    res.status(502).json({ error: 'upstream_error', message: 'Failed to fetch market news' });
  }
});

export default router;
