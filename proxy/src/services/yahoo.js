import YahooFinance from 'yahoo-finance2';

const yahooFinance = new YahooFinance({ suppressNotices: ['yahooSurvey'] });

export async function getQuote(symbol) {
  try {
    const quote = await yahooFinance.quote(symbol);
    return {
      s: quote.symbol,
      n: quote.shortName || quote.longName || quote.symbol,
      p: quote.regularMarketPrice || 0,
      c: quote.regularMarketChange || 0,
      cp: quote.regularMarketChangePercent || 0,
      h: quote.regularMarketDayHigh || 0,
      l: quote.regularMarketDayLow || 0,
      o: quote.regularMarketOpen || 0,
      v: quote.regularMarketVolume || 0,
      e: quote.fullExchangeName || quote.exchange || 'Unknown',
      m: (quote.marketState || 'CLOSED').toLowerCase(),
      t: Math.floor(Date.now() / 1000),
    };
  } catch (err) {
    if (err.message?.includes('Not Found') || err.message?.includes('symbol') || err.message?.includes('Quote not found')) {
      return { error: 'symbol_not_found', message: `Symbol "${symbol}" not found` };
    }
    throw err;
  }
}

export async function getHistory(symbol, range = '1mo') {
  const rangeMap = {
    '1m': { monthsAgo: 1, interval: '1d' },
    '3m': { monthsAgo: 3, interval: '1d' },
    '6m': { monthsAgo: 6, interval: '1d' },
    '1y': { monthsAgo: 12, interval: '1wk' },
  };

  const config = rangeMap[range] || rangeMap['1m'];

  // Build date string for period1
  const d = new Date();
  d.setMonth(d.getMonth() - config.monthsAgo);
  const period1 = d.toISOString().split('T')[0]; // yyyy-mm-dd

  try {
    const result = await yahooFinance.chart(symbol, {
      period1: period1,
      interval: config.interval,
    });

    if (!result || !result.quotes || result.quotes.length === 0) {
      return { s: symbol, r: range, d: [] };
    }

    const data = result.quotes
      .filter(q => q.open !== null && q.close !== null)
      .map(q => ({
        t: Math.floor(new Date(q.date).getTime() / 1000),
        o: Number(q.open.toFixed(2)),
        h: Number(q.high.toFixed(2)),
        l: Number(q.low.toFixed(2)),
        c: Number(q.close.toFixed(2)),
        v: q.volume || 0,
      }));

    return { s: symbol, r: range, d: data };
  } catch (err) {
    if (err.message?.includes('Not Found') || err.message?.includes('symbol')) {
      return { s: symbol, r: range, d: [], error: 'symbol_not_found' };
    }
    throw err;
  }
}

export async function searchSymbols(query) {
  try {
    const results = await yahooFinance.search(query);
    if (!results || !results.quotes || results.quotes.length === 0) {
      return { q: query, r: [] };
    }

    const items = results.quotes
      .filter(q => q.symbol && q.shortname)
      .slice(0, 10)
      .map(q => ({
        s: q.symbol,
        n: q.shortname || q.longname || q.symbol,
        e: q.exchange || 'Unknown',
        t: (q.quoteType || 'stock').toLowerCase(),
      }));

    return { q: query, r: items };
  } catch (err) {
    return { q: query, r: [], error: 'search_failed' };
  }
}

export async function getMarketStatus() {
  const indices = [
    { key: 'us', symbol: '^GSPC' },
    { key: 'de', symbol: '^GDAXI' },
    { key: 'uk', symbol: '^FTSE' },
    { key: 'fr', symbol: '^FCHI' },
    { key: 'jp', symbol: '^N225' },
    { key: 'hk', symbol: '^HSI' },
    { key: 'cn', symbol: '000001.SS' },
    { key: 'au', symbol: '^AXJO' },
    { key: 'br', symbol: '^BVSP' },
  ];

  const status = {};

  await Promise.all(
    indices.map(async ({ key, symbol }) => {
      try {
        const q = await yahooFinance.quote(symbol);
        status[key] = (q.marketState || 'unknown').toLowerCase();
      } catch {
        status[key] = 'unknown';
      }
    })
  );

  return status;
}

export async function getNews(symbol) {
  try {
    const results = await yahooFinance.search(symbol);
    if (!results || !results.news || results.news.length === 0) {
      return { s: symbol, n: [] };
    }

    const items = results.news
      .filter(article => article.title && article.link)
      .slice(0, 10)
      .map(article => ({
        t: article.title,
        p: article.publisher || 'Unknown',
        l: article.link,
        d: article.providerPublishTime || null,
        img: article.thumbnail?.resolutions?.[0]?.url || null,
        tickers: article.relatedTickers || [],
      }));

    return { s: symbol, n: items };
  } catch (err) {
    console.error(`[news] Yahoo search failed for ${symbol}:`, err.message);
    return { s: symbol, n: [], error: 'news_fetch_failed' };
  }
}

export async function getMarketNews() {
  try {
    const queries = ['stocks', 'S&P 500', 'market'];
    const allNews = [];

    for (const q of queries) {
      const results = await yahooFinance.search(q);
      if (results && results.news) {
        for (const article of results.news) {
          if (article.title && article.link && !allNews.find(n => n.t === article.title)) {
            allNews.push({
              t: article.title,
              p: article.publisher || 'Unknown',
              l: article.link,
              d: article.providerPublishTime || null,
              img: article.thumbnail?.resolutions?.[0]?.url || null,
              tickers: article.relatedTickers || [],
            });
          }
        }
      }
    }

    return { s: 'MARKET', n: allNews.slice(0, 15) };
  } catch (err) {
    console.error('[news] Market news fetch failed:', err.message);
    return { s: 'MARKET', n: [], error: 'news_fetch_failed' };
  }
}
