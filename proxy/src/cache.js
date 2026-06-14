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
