-- TradeWidget.client.lua — Buy/Sell modal for executing trades
-- Place in: StarterPlayerScripts/UI/TradeWidget (LocalScript)
--
-- Opens when clicking a stock row in MarketScreen.
-- Shows current price, quantity input, buy/sell buttons, confirmation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ExecuteTrade = NetworkEvents:WaitForChild("ExecuteTrade")

local ScreenGui = player.PlayerGui:WaitForChild("MarketScreen")

-- ============================================================
-- Trade modal (created on demand)
-- ============================================================
local TradeFrame = Instance.new("Frame")
TradeFrame.Name = "TradeWidget"
TradeFrame.Size = UDim2.new(0.35, 0, 0.45, 0)
TradeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TradeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
TradeFrame.BackgroundColor3 = Color3.fromRGB(32, 36, 42)
TradeFrame.BorderSizePixel = 1
TradeFrame.BorderColor3 = Color3.fromRGB(60, 65, 75)
TradeFrame.Visible = false
TradeFrame.ZIndex = 10
TradeFrame.Parent = ScreenGui

-- Background overlay (click to close)
local Overlay = Instance.new("TextButton")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.6
Overlay.Text = ""
Overlay.Visible = false
Overlay.ZIndex = 9
Overlay.Parent = ScreenGui

-- Modal title
local ModalTitle = Instance.new("TextLabel")
ModalTitle.Name = "Title"
ModalTitle.Text = "Trade"
ModalTitle.TextSize = 22
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModalTitle.Size = UDim2.new(0.8, 0, 0, 36)
ModalTitle.Position = UDim2.new(0, 16, 0, 12)
ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ModalTitle.Parent = TradeFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Text = "X"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = TradeFrame

-- Symbol + Price
local SymbolLabel = Instance.new("TextLabel")
SymbolLabel.Name = "Symbol"
SymbolLabel.Text = ""
SymbolLabel.TextSize = 28
SymbolLabel.Font = Enum.Font.GothamBold
SymbolLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
SymbolLabel.Size = UDim2.new(0.8, 0, 0, 32)
SymbolLabel.Position = UDim2.new(0, 16, 0, 56)
SymbolLabel.TextXAlignment = Enum.TextXAlignment.Left
SymbolLabel.Parent = TradeFrame

local PriceLabel = Instance.new("TextLabel")
PriceLabel.Name = "Price"
PriceLabel.Text = ""
PriceLabel.TextSize = 18
PriceLabel.Font = Enum.Font.Gotham
PriceLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
PriceLabel.Size = UDim2.new(0.8, 0, 0, 24)
PriceLabel.Position = UDim2.new(0, 16, 0, 92)
PriceLabel.TextXAlignment = Enum.TextXAlignment.Left
PriceLabel.Parent = TradeFrame

-- Quantity input
local QtyBox = Instance.new("TextBox")
QtyBox.Name = "QtyInput"
QtyBox.Text = "1"
QtyBox.TextSize = 20
QtyBox.Font = Enum.Font.Gotham
QtyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QtyBox.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
QtyBox.Size = UDim2.new(0.5, 0, 0, 36)
QtyBox.Position = UDim2.new(0, 16, 0, 136)
QtyBox.PlaceholderText = "Shares"
QtyBox.Parent = TradeFrame

local QtyLabel = Instance.new("TextLabel")
QtyLabel.Name = "QtyLabel"
QtyLabel.Text = "Shares"
QtyLabel.TextSize = 14
QtyLabel.Font = Enum.Font.Gotham
QtyLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
QtyLabel.Size = UDim2.new(0.3, 0, 0, 20)
QtyLabel.Position = UDim2.new(0, 16, 0, 176)
QtyLabel.TextXAlignment = Enum.TextXAlignment.Left
QtyLabel.Parent = TradeFrame

-- Estimated cost
local EstimatedLabel = Instance.new("TextLabel")
EstimatedLabel.Name = "EstimatedCost"
EstimatedLabel.Text = "Total: $0.00 | Fee: $0.00"
EstimatedLabel.TextSize = 14
EstimatedLabel.Font = Enum.Font.Gotham
EstimatedLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
EstimatedLabel.Size = UDim2.new(0.8, 0, 0, 20)
EstimatedLabel.Position = UDim2.new(0, 16, 0, 200)
EstimatedLabel.TextXAlignment = Enum.TextXAlignment.Left
EstimatedLabel.Parent = TradeFrame

-- Buy button
local BuyBtn = Instance.new("TextButton")
BuyBtn.Name = "BuyBtn"
BuyBtn.Text = "BUY"
BuyBtn.TextSize = 22
BuyBtn.Font = Enum.Font.GothamBold
BuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BuyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
BuyBtn.Size = UDim2.new(0.42, 0, 0, 44)
BuyBtn.Position = UDim2.new(0, 16, 1, -60)
BuyBtn.Parent = TradeFrame

-- Sell button
local SellBtn = Instance.new("TextButton")
SellBtn.Name = "SellBtn"
SellBtn.Text = "SELL"
SellBtn.TextSize = 22
SellBtn.Font = Enum.Font.GothamBold
SellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SellBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
SellBtn.Size = UDim2.new(0.42, 0, 0, 44)
SellBtn.Position = UDim2.new(0.5, 0, 1, -60)
SellBtn.Parent = TradeFrame

-- Result label (shown after trade)
local ResultLabel = Instance.new("TextLabel")
ResultLabel.Name = "Result"
ResultLabel.Text = ""
ResultLabel.TextSize = 14
ResultLabel.Font = Enum.Font.Gotham
ResultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ResultLabel.Size = UDim2.new(0.9, 0, 0, 36)
ResultLabel.Position = UDim2.new(0, 16, 1, -120)
ResultLabel.TextXAlignment = Enum.TextXAlignment.Left
ResultLabel.TextWrapped = true
ResultLabel.Parent = TradeFrame

-- ============================================================
-- Modal logic
-- ============================================================
local activeSymbol = nil
local activePrice = nil

local function showTradeWidget(symbol, price, companyName)
	activeSymbol = symbol
	activePrice = price

	SymbolLabel.Text = string.format("%s - %s", symbol, companyName or "")
	PriceLabel.Text = string.format("Current price: $%.2f", price)
	QtyBox.Text = "1"
	ResultLabel.Text = ""
	EstimatedLabel.Text = string.format("Total: $%.2f | Fee: $%.0f", price, 0)

	TradeFrame.Visible = true
	Overlay.Visible = true
end

local function hideTradeWidget()
	TradeFrame.Visible = false
	Overlay.Visible = false
	activeSymbol = nil
	activePrice = nil
end

CloseBtn.MouseButton1Click:Connect(hideTradeWidget)
Overlay.MouseButton1Click:Connect(hideTradeWidget)

-- Update estimated cost when quantity changes
QtyBox:GetPropertyChangedSignal("Text"):Connect(function()
	local shares = tonumber(QtyBox.Text) or 0
	if activePrice then
		local total = activePrice * shares
		local fee = math.floor(total * 0.001)
		EstimatedLabel.Text = string.format("Total: $%.2f | Fee: $%.0f", total, fee)
	end
end)

-- Execute trade
local function doTrade(tradeType)
	if not activeSymbol or not activePrice then return end

	local shares = tonumber(QtyBox.Text)
	if not shares or shares <= 0 then
		ResultLabel.Text = "Enter a valid number of shares."
		ResultLabel.TextColor3 = Color3.fromRGB(255, 150, 80)
		return
	end

	BuyBtn.Interactable = false
	SellBtn.Interactable = false

	local ok, result = pcall(function()
		return ExecuteTrade:InvokeServer(tradeType, activeSymbol, shares)
	end)

	BuyBtn.Interactable = true
	SellBtn.Interactable = true

	if ok and result then
		if result.success then
			ResultLabel.Text = result.message
			ResultLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
		else
			ResultLabel.Text = result.message or "Trade failed."
			ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	else
		ResultLabel.Text = "Network error. Try again."
		ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

BuyBtn.MouseButton1Click:Connect(function()
	doTrade("buy")
end)

SellBtn.MouseButton1Click:Connect(function()
	doTrade("sell")
end)

-- ============================================================
-- Expose to MarketScreen
-- ============================================================
shared.OpenTradeWidget = showTradeWidget
shared.CloseTradeWidget = hideTradeWidget
