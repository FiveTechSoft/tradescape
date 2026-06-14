import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import historyRoutes from '../src/routes/history.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('History Route', () => {
  let server;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(historyRoutes);
    server = app.listen(9994);
  });

  after(() => {
    server.close();
  });

  it('should return history for valid symbol with default range', async () => {
    const res = await fetch('http://localhost:9994/api/history/AAPL', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.s, 'AAPL');
    assert.strictEqual(body.r, '1m');
    assert.ok(Array.isArray(body.d));
    assert.ok(body.d.length > 0, 'should have at least one data point');
    assert.ok(body.d[0].t, 'should have timestamp');
    assert.ok(typeof body.d[0].c === 'number', 'should have close price');
  });

  it('should respect range parameter', async () => {
    const res = await fetch('http://localhost:9994/api/history/AAPL?range=3m', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.r, '3m');
    assert.ok(body.d.length > 0);
  });

  it('should reject invalid range', async () => {
    const res = await fetch('http://localhost:9994/api/history/AAPL?range=5y', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 400);
    assert.strictEqual(body.error, 'invalid_range');
  });
});
