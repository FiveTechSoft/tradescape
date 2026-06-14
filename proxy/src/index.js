import 'dotenv/config';
import express from 'express';
import { authMiddleware } from './middleware/auth.js';
import { rateLimitMiddleware } from './middleware/rateLimit.js';
import quoteRoutes from './routes/quote.js';
import historyRoutes from './routes/history.js';
import searchRoutes from './routes/search.js';
import marketStatusRoutes from './routes/marketStatus.js';
import newsRoutes from './routes/news.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(rateLimitMiddleware);
app.use(authMiddleware);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.use(quoteRoutes);
app.use(historyRoutes);
app.use(searchRoutes);
app.use(marketStatusRoutes);
app.use(newsRoutes);

app.listen(PORT, () => {
  console.log(`TradeScape proxy running on port ${PORT}`);
});

export default app;
