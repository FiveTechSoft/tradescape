export function authMiddleware(req, res, next) {
  const API_KEY = process.env.API_KEY || 'tradescape-dev-key-change-me';
  const key = req.headers['x-api-key'];

  if (!key) {
    return res.status(401).json({ error: 'missing_api_key', message: 'X-API-Key header required' });
  }

  if (key !== API_KEY) {
    return res.status(403).json({ error: 'invalid_api_key', message: 'Invalid API key' });
  }

  next();
}
