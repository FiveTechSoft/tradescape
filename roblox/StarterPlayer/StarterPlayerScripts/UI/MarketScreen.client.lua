-- MarketScreen.client.lua — Main trading UI: stock list with live data
-- Place in: StarterPlayerScripts/UI/MarketScreen (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")

local GetQuote = NetworkEvents:WaitForChild("GetQuote")
local GetPortfolio = NetworkEvents:WaitForChild("GetPortfolio")
local GetInitialData = NetworkEvents:WaitForChild("GetInitialData")

-- Popular symbols watchlist for MVP
local WATCHLIST = {
	"AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META", "NFLX",
	"SPY", "QQQ", "AMD", "INTC", "BA", "JPM", "V", "DIS",
}

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MarketScreen"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame (dark Bloomberg-style, left side panel)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 1, 0)
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "TradeScape"
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Size = UDim2.new(0, 100, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar

local BalanceLabel = Instance.new("TextLabel")
BalanceLabel.Name = "Balance"
BalanceLabel.Text = "Loading..."
BalanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BalanceLabel.TextSize = 14
BalanceLabel.Font = Enum.Font.Gotham
BalanceLabel.Size = UDim2.new(1, -160, 1, 0)
BalanceLabel.Position = UDim2.new(0, 110, 0, 0)
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Left
BalanceLabel.BackgroundTransparency = 1
BalanceLabel.Parent = TopBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -44, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar

local minimized = false
CloseBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	StockList.Visible = not minimized
	if minimized then
		MainFrame.Size = UDim2.new(0, 380, 0, 48)
		CloseBtn.Text = "+"
	else
		MainFrame.Size = UDim2.new(0, 380, 1, 0)
		CloseBtn.Text = "X"
	end
end)

-- Stock list (ScrollingFrame)
local StockList = Instance.new("ScrollingFrame")
StockList.Name = "StockList"
StockList.Size = UDim2.new(1, 0, 1, -48)
StockList.Position = UDim2.new(0, 0, 0, 48)
StockList.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
StockList.BackgroundTransparency = 0.1
StockList.ScrollBarThickness = 6
StockList.CanvasSize = UDim2.new(0, 0, 0, 0)
StockList.BorderSizePixel = 0
StockList.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = StockList

-- ============================================================
-- Create stock row template
-- ============================================================
local function createStockRow(symbol)
	local row = Instance.new("TextButton")
	row.Name = "Row_" .. symbol
	row.Size = UDim2.new(1, -8, 0, 48)
	row.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
	row.BorderSizePixel = 0
	row.Text = ""
	row.AutoButtonColor = false

	local symbolLabel = Instance.new("TextLabel")
	symbolLabel.Name = "Symbol"
	symbolLabel.Text = symbol
	symbolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	symbolLabel.TextSize = 14
	symbolLabel.Font = Enum.Font.GothamBold
	symbolLabel.Size = UDim2.new(0, 60, 0.5, 0)
	symbolLabel.Position = UDim2.new(0, 8, 0, 2)
	symbolLabel.TextXAlignment = Enum.TextXAlignment.Left
	symbolLabel.BackgroundTransparency = 1
	symbolLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Text = "..."
	nameLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Size = UDim2.new(0, 60, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 8, 0.5, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.BackgroundTransparency = 1
	nameLabel.Parent = row

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Text = "$-.--"
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	priceLabel.TextSize = 14
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Size = UDim2.new(0, 80, 0.5, 0)
	priceLabel.Position = UDim2.new(0, 80, 0, 2)
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.BackgroundTransparency = 1
	priceLabel.Parent = row

	local changeLabel = Instance.new("TextLabel")
	changeLabel.Name = "Change"
	changeLabel.Text = "0.00%"
	changeLabel.TextSize = 12
	changeLabel.Font = Enum.Font.Gotham
	changeLabel.Size = UDim2.new(0, 80, 0.5, 0)
	changeLabel.Position = UDim2.new(0, 80, 0.5, 0)
	changeLabel.TextXAlignment = Enum.TextXAlignment.Right
	changeLabel.BackgroundTransparency = 1
	changeLabel.Parent = row

	-- Row click → open trade widget
	row.MouseButton1Click:Connect(function()
		local loaded = row:GetAttribute("Loaded")
		if loaded then
			local sym = row:GetAttribute("Symbol")
			local price = row:GetAttribute("CurrentPrice")
			local name = nameLabel.Text
			if shared.OpenTradeWidget then
				shared.OpenTradeWidget(sym, price, name)
			end
		end
	end)

	return row
end

-- ============================================================
-- Update stock row with quote data
-- ============================================================
local function updateStockRow(row, quote)
	local nameLabel = row:FindFirstChild("Name")
	local priceLabel = row:FindFirstChild("Price")
	local changeLabel = row:FindFirstChild("Change")

	if not quote then
		nameLabel.Text = "Loading..."
		priceLabel.Text = "..."
		changeLabel.Text = "..."
		return
	end

	nameLabel.Text = quote.n or "Unknown"
	priceLabel.Text = string.format("$%.2f", quote.p)

	local changeColor = Color3.fromRGB(0, 200, 100)
	if quote.cp < 0 then
		changeColor = Color3.fromRGB(255, 80, 80)
	end
	local sign = quote.cp >= 0 and "+" or ""
	changeLabel.Text = string.format("%s%.2f%%", sign, quote.cp)
	changeLabel.TextColor3 = changeColor

	if quote.stale then
		row.BackgroundColor3 = Color3.fromRGB(40, 35, 20)
	else
		row.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
	end

	row:SetAttribute("CurrentPrice", quote.p)
	row:SetAttribute("Symbol", quote.s)
	row:SetAttribute("Loaded", true)
end

-- ============================================================
-- Build initial stock rows
-- ============================================================
local rows = {}
for i, symbol in ipairs(WATCHLIST) do
	local row = createStockRow(symbol)
	row.Parent = StockList
	rows[symbol] = row
end

StockList.CanvasSize = UDim2.new(0, 0, 0, #WATCHLIST * 52)

-- ============================================================
-- Periodic data refresh (batch)
-- ============================================================
local GetQuotes = NetworkEvents:WaitForChild("GetQuotes")

local function refreshWatchlist()
	local ok, quotesMap = pcall(function()
		return GetQuotes:InvokeServer(WATCHLIST)
	end)

	if ok and quotesMap then
		for symbol, quote in pairs(quotesMap) do
			if rows[symbol] and quote then
				updateStockRow(rows[symbol], quote)
			end
		end
	end
end

local function refreshBalance()
	local ok, portfolio = pcall(function()
		return GetPortfolio:InvokeServer()
	end)

	if ok and portfolio then
		local sign = portfolio.totalProfit >= 0 and "+" or ""
		BalanceLabel.Text = string.format("$%.2f | %s$%.2f (%.2f%%)",
			portfolio.balance, sign, portfolio.totalProfit, portfolio.totalProfitPercent)
	else
		-- Fallback: use GetInitialData
		local ok2, data = pcall(function()
			return GetInitialData:InvokeServer()
		end)
		if ok2 and data then
			BalanceLabel.Text = string.format("$%.2f | Level %d %s", data.balance, data.level, data.rank)
		end
	end
end

-- Initial load
refreshWatchlist()
refreshBalance()

-- Periodic refresh loop (every 2 seconds)
while true do
	task.wait(2)
	refreshWatchlist()
	refreshBalance()
end
