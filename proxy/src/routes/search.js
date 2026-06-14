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
