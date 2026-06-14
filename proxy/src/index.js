import 'dotenv/config';
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Routes will be mounted in later tasks
// app.use(quoteRoutes);
// app.use(historyRoutes);
// etc.

app.listen(PORT, () => {
  console.log(`TradeScape proxy running on port ${PORT}`);
});

export default app;
