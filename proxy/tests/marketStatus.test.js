import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import marketStatusRoutes from '../src/routes/marketStatus.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Market Status Route', () => {
  let server;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(marketStatusRoutes);
    server = app.listen(9992);
  });

  after(() => {
    server.close();
  });

  it('should return market status object', async () => {
    const res = await fetch('http://localhost:9992/api/market-status', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.ok(typeof body.us === 'string');
    assert.ok(['open', 'closed', 'pre', 'post', 'unknown'].includes(body.us),
      `Market state '${body.us}' should be valid`);
  });
});
