import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import searchRoutes from '../src/routes/search.js';
import { authMiddleware } from '../src/middleware/auth.js';

describe('Search Route', () => {
  let server;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.use(authMiddleware);
    app.use(searchRoutes);
    server = app.listen(9993);
  });

  after(() => {
    server.close();
  });

  it('should return search results', async () => {
    const res = await fetch('http://localhost:9993/api/search?q=Apple', {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();

    assert.strictEqual(res.status, 200);
    assert.strictEqual(body.q, 'Apple');
    assert.ok(Array.isArray(body.r));
    if (body.r.length > 0) {
      assert.ok(body.r[0].s);
      assert.ok(body.r[0].n);
    }
  });

  it('should reject empty query', async () => {
    const res = await fetch('http://localhost:9993/api/search?q=', {
      headers: { 'x-api-key': 'test-key' },
    });
    assert.strictEqual(res.status, 400);
  });
});
