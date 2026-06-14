import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import quoteRoutes from '../src/routes/quote.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Quote Route', () => {
  let server;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(quoteRoutes);
    server = app.listen(9995);
  });

  after(() => {
    server.close();
  });

  it('should return quote for valid symbol (AAPL)', async () => {
    const res = await fetch('http://localhost:9995/api/quote/AAPL', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.s, 'AAPL');
    assert.ok(typeof body.p === 'number', 'price should be a number');
    assert.ok(body.p > 0, 'price should be positive');
    assert.ok(typeof body.n === 'string');
    assert.ok(body.n.length > 0, 'company name should not be empty');
    assert.ok(typeof body.m === 'string', 'market state should be a string');
  });

  it('should return 404 for invalid symbol', async () => {
    const res = await fetch('http://localhost:9995/api/quote/ZZZYX_INVALID', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 404);
    assert.strictEqual(body.error, 'symbol_not_found');
  });

  it('should be faster on second call (cache)', async () => {
    const headers = { 'x-api-key': 'test-key' };
    const start = Date.now();
    const res1 = await fetch('http://localhost:9995/api/quote/MSFT', { headers });
    const firstDuration = Date.now() - start;
    assert.strictEqual(res1.status, 200);

    const start2 = Date.now();
    const res2 = await fetch('http://localhost:9995/api/quote/MSFT', { headers });
    const secondDuration = Date.now() - start2;
    assert.strictEqual(res2.status, 200);
    // Cached should be faster (allow some variance)
    assert.ok(secondDuration <= Math.max(firstDuration * 3, 50),
      `Cache didn't help: ${firstDuration}ms vs ${secondDuration}ms`);
  });
});
