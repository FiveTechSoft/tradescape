-- Types.lua — Shared type definitions used by server and client
-- Place in: ReplicatedStorage/Types
--
-- These are Luau type annotations for reference.
-- Luau doesn't enforce them at runtime but they improve IDE support.

export type Quote = {
	s: string,        -- symbol
	n: string,        -- company name
	p: number,        -- current price
	c: number,        -- price change
	cp: number,       -- change percent
	h: number,        -- day high
	l: number,        -- day low
	o: number,        -- open price
	v: number,        -- volume
	e: string,        -- exchange name
	m: string,        -- market state (open/closed/pre/post)
	t: number,        -- timestamp (unix)
	stale: boolean?,  -- true if using cached data
}

export type Position = {
	symbol: string,
	shares: number,
	avgPrice: number,
	totalCost: number,
	opened: number,   -- unix timestamp
}

export type TradeResult = {
	success: boolean,
	message: string?,
	newBalance: number?,
	position: Position?,
	profitLoss: number?,
}

export type PortfolioData = {
	balance: number,
	positions: { [string]: Position },
	totalValue: number,
	totalProfit: number,
	totalProfitPercent: number,
}

export type CandleData = {
	t: number,        -- timestamp
	o: number,        -- open
	h: number,        -- high
	l: number,        -- low
	c: number,        -- close
	v: number,        -- volume
}

return {}
