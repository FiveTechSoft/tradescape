import 'dotenv/config';
import express from 'express';
import { authMiddleware } from './middleware/auth.js';
import { rateLimitMiddleware } from './middleware/rateLimit.js';
import quoteRoutes from './routes/quote.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(rateLimitMiddleware);
app.use(authMiddleware);

// Health check (no auth required)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Routes
app.use(quoteRoutes);

app.listen(PORT, () => {
  console.log(`TradeScape proxy running on port ${PORT}`);
});

export default app;
