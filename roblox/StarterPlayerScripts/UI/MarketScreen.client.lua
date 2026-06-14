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

-- Main frame (dark Bloomberg-style)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
MainFrame.Parent = ScreenGui

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "TradeScape"
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.Size = UDim2.new(0.3, 0, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local BalanceLabel = Instance.new("TextLabel")
BalanceLabel.Name = "Balance"
BalanceLabel.Text = "Loading..."
BalanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BalanceLabel.TextSize = 18
BalanceLabel.Font = Enum.Font.Gotham
BalanceLabel.Size = UDim2.new(0.4, 0, 1, 0)
BalanceLabel.Position = UDim2.new(0.4, 0, 0, 0)
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Center
BalanceLabel.Parent = TopBar

-- Stock list (ScrollingFrame)
local StockList = Instance.new("ScrollingFrame")
StockList.Name = "StockList"
StockList.Size = UDim2.new(1, 0, 1, -48)
StockList.Position = UDim2.new(0, 0, 0, 48)
StockList.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
StockList.ScrollBarThickness = 8
StockList.CanvasSize = UDim2.new(0, 0, 0, 0)
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
	row.Size = UDim2.new(1, -16, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(26, 30, 36)
	row.Text = ""
	row.AutoButtonColor = false

	local symbolLabel = Instance.new("TextLabel")
	symbolLabel.Name = "Symbol"
	symbolLabel.Text = symbol
	symbolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	symbolLabel.TextSize = 18
	symbolLabel.Font = Enum.Font.GothamBold
	symbolLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	symbolLabel.Position = UDim2.new(0, 12, 0, 4)
	symbolLabel.TextXAlignment = Enum.TextXAlignment.Left
	symbolLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Text = "..."
	nameLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 12, 0.5, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Text = "$-.--"
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	priceLabel.TextSize = 18
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	priceLabel.Position = UDim2.new(0.25, 0, 0, 4)
	priceLabel.TextXAlignment = Enum.TextXAlignment.Right
	priceLabel.Parent = row

	local changeLabel = Instance.new("TextLabel")
	changeLabel.Name = "Change"
	changeLabel.Text = "0.00%"
	changeLabel.TextSize = 16
	changeLabel.Font = Enum.Font.Gotham
	changeLabel.Size = UDim2.new(0.15, 0, 0.5, 0)
	changeLabel.Position = UDim2.new(0.25, 0, 0.5, 0)
	changeLabel.TextXAlignment = Enum.TextXAlignment.Right
	changeLabel.Parent = row

	-- Row click → open trade widget
	row.MouseButton1Click:Connect(function()
		local loaded = row:GetAttribute("Loaded")
		if loaded then
			local sym = row:GetAttribute("Symbol")
			local price = row:GetAttribute("CurrentPrice")
			local name = nameLabel.Text
			if _G.OpenTradeWidget then
				_G.OpenTradeWidget(sym, price, name)
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

StockList.CanvasSize = UDim2.new(0, 0, 0, #WATCHLIST * 60)

-- ============================================================
-- Periodic data refresh
-- ============================================================
local function refreshWatchlist()
	for _, symbol in ipairs(WATCHLIST) do
		local ok, quote = pcall(function()
			return GetQuote:InvokeServer(symbol)
		end)

		if ok and quote then
			updateStockRow(rows[symbol], quote)
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
