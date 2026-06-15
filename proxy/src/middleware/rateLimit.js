const requestLog = new Map();

// Cleanup old IPs every 5 minutes to prevent memory leak
setInterval(() => {
  const now = Date.now();
  const WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000;
  for (const [ip, timestamps] of requestLog) {
    // Remove IPs with no recent requests
    if (timestamps.length === 0 || timestamps[timestamps.length - 1] < now - WINDOW_MS) {
      requestLog.delete(ip);
    }
  }
}, 300000);

export function rateLimitMiddleware(req, res, next) {
  const WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000;
  const MAX_REQUESTS = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100;
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
