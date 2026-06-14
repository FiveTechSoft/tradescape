# TradeScape Proxy — Deployment

## Quick Deploy (Hetzner/DigitalOcean $5 VPS)

### 1. Server setup
```bash
ssh root@your-server-ip
apt update && apt install -y nodejs npm
npm install -g pm2
```

### 2. Upload code
```bash
# From your local machine
scp -r proxy/ root@your-server-ip:/opt/tradescape-proxy/
```

### 3. Configure
```bash
cd /opt/tradescape-proxy
cp .env.example .env
nano .env  # Change API_KEY to a strong random string, set PORT=3000
npm install --production
```

### 4. Start with PM2
```bash
pm2 start src/index.js --name tradescape-proxy
pm2 save
pm2 startup
```

### 5. Nginx reverse proxy (recommended)
```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 6. Test
```bash
curl -H "X-API-Key: your-key-here" http://localhost:3000/api/quote/AAPL
```

### Health check
```bash
curl http://localhost:3000/health
# -> { "status": "ok", "uptime": 1234 }
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 3000 | Server port |
| API_KEY | (required) | Shared secret with Roblox |
| CACHE_TTL_QUOTE | 60 | Quote cache seconds |
| CACHE_TTL_HISTORY | 300 | History cache seconds |
| CACHE_TTL_SEARCH | 3600 | Search cache seconds |
| RATE_LIMIT_WINDOW_MS | 60000 | Rate limit window (ms) |
| RATE_LIMIT_MAX_REQUESTS | 100 | Max requests per window |
