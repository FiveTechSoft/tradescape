import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import express from 'express';
import { authMiddleware } from '../src/middleware/auth.js';
import { rateLimitMiddleware } from '../src/middleware/rateLimit.js';

describe('Auth Middleware', () => {
  let server;
  let port = 9999;

  before(() => {
    process.env.API_KEY = 'test-key';
    const app = express();
    app.get('/test', authMiddleware, (req, res) => res.json({ ok: true }));
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should reject requests without API key', async () => {
    const res = await fetch(`http://localhost:${port}/test`);
    const body = await res.json();
    assert.strictEqual(res.status, 401);
    assert.strictEqual(body.error, 'missing_api_key');
  });

  it('should reject wrong API key', async () => {
    const res = await fetch(`http://localhost:${port}/test`, {
      headers: { 'x-api-key': 'wrong-key' },
    });
    const body = await res.json();
    assert.strictEqual(res.status, 403);
    assert.strictEqual(body.error, 'invalid_api_key');
  });

  it('should pass with correct API key', async () => {
    const res = await fetch(`http://localhost:${port}/test`, {
      headers: { 'x-api-key': 'test-key' },
    });
    const body = await res.json();
    assert.strictEqual(res.status, 200);
    assert.deepStrictEqual(body, { ok: true });
  });
});

describe('Rate Limit Middleware', () => {
  let server;
  let port = 9998;

  before(() => {
    process.env.RATE_LIMIT_MAX_REQUESTS = '5';
    process.env.RATE_LIMIT_WINDOW_MS = '60000';
    const app = express();
    app.get('/test', rateLimitMiddleware, (req, res) => res.json({ ok: true }));
    server = app.listen(port);
  });

  after(() => {
    server.close();
  });

  it('should allow requests under limit', async () => {
    const res = await fetch(`http://localhost:${port}/test`);
    assert.strictEqual(res.status, 200);
  });

  it('should block requests over limit', async () => {
    // requestLog is module-shared; first test already sent 1 request
    // So we have 4 slots left before hitting the limit of 5
    for (let i = 0; i < 4; i++) {
      const res = await fetch(`http://localhost:${port}/test`);
      assert.strictEqual(res.status, 200, `Request ${i} should pass (used ${i + 2} of 5)`);
    }
    // 6th request overall should be blocked
    const res = await fetch(`http://localhost:${port}/test`);
    const body = await res.json();
    assert.strictEqual(res.status, 429);
    assert.strictEqual(body.error, 'rate_limited');
  });
});
