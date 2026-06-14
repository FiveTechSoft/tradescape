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
