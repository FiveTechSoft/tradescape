-- ChartView.client.lua — Candlestick chart rendering with indicators
-- Place in: StarterPlayer/StarterPlayerScripts/UI/ChartView (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local GetQuote = NetworkEvents:WaitForChild("GetQuote")

-- Simple chart using canvas-like Frame rendering
local ScreenGui = player.PlayerGui:WaitForChild("MarketScreen")

local ChartFrame = Instance.new("Frame")
ChartFrame.Name = "ChartView"
ChartFrame.Size = UDim2.new(1, -340, 0.5, -60)
ChartFrame.Position = UDim2.new(0, 330, 0, 50)
ChartFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
ChartFrame.BorderSizePixel = 1
ChartFrame.BorderColor3 = Color3.fromRGB(50, 55, 65)
ChartFrame.Visible = false
ChartFrame.Parent = ScreenGui

local ChartTitle = Instance.new("TextLabel")
ChartTitle.Name = "ChartTitle"
ChartTitle.Text = "Chart"
ChartTitle.TextSize = 16
ChartTitle.Font = Enum.Font.GothamBold
ChartTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ChartTitle.Size = UDim2.new(0.5, 0, 0, 28)
ChartTitle.Position = UDim2.new(0, 10, 0, 4)
ChartTitle.TextXAlignment = Enum.TextXAlignment.Left
ChartTitle.Parent = ChartFrame

-- Timeframe buttons
local timeframes = { "1D", "1W", "1M", "3M", "6M", "1Y" }
local tfButtons = {}
local activeTF = "1M"

for i, tf in ipairs(timeframes) do
	local btn = Instance.new("TextButton")
	btn.Name = "TF_" .. tf
	btn.Text = tf
	btn.TextSize = 11
	btn.Font = Enum.Font.Gotham
	btn.TextColor3 = tf == activeTF and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 155, 165)
	btn.BackgroundTransparency = 1
	btn.Size = UDim2.new(0, 36, 0, 24)
	btn.Position = UDim2.new(0, 60 + (i - 1) * 40, 0, 4)
	btn.Parent = ChartFrame

	btn.MouseButton1Click:Connect(function()
		activeTF = tf
		for _, b in ipairs(tfButtons) do
			b.TextColor3 = Color3.fromRGB(150, 155, 165)
		end
		btn.TextColor3 = Color3.fromRGB(0, 200, 100)
	end)

	table.insert(tfButtons, btn)
end

-- Price label (right axis)
local PriceAxis = Instance.new("TextLabel")
PriceAxis.Name = "PriceAxis"
PriceAxis.Text = ""
PriceAxis.TextSize = 10
PriceAxis.Font = Enum.Font.Gotham
PriceAxis.TextColor3 = Color3.fromRGB(150, 155, 165)
PriceAxis.Size = UDim2.new(0, 60, 1, -40)
PriceAxis.Position = UDim2.new(1, -65, 0, 32)
PriceAxis.TextXAlignment = Enum.TextXAlignment.Right
PriceAxis.TextYAlignment = Enum.TextYAlignment.Top
PriceAxis.Parent = ChartFrame

-- Volume bars container
local VolumeFrame = Instance.new("Frame")
VolumeFrame.Name = "Volume"
VolumeFrame.Size = UDim2.new(1, -80, 0, 40)
VolumeFrame.Position = UDim2.new(0, 10, 1, -45)
VolumeFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
VolumeFrame.Parent = ChartFrame

-- Chart canvas (line drawing via thin Frames)
local ChartCanvas = Instance.new("Frame")
ChartCanvas.Name = "Canvas"
ChartCanvas.Size = UDim2.new(1, -80, 1, -90)
ChartCanvas.Position = UDim2.new(0, 10, 0, 32)
ChartCanvas.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
ChartCanvas.Parent = ChartFrame

-- ============================================================
-- Sparkline renderer (simplified MVP — renders as colored bars)
-- ============================================================
local candles = {} -- { open, high, low, close, volume }

local function clearChart()
	for _, c in ipairs(ChartCanvas:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for _, c in ipairs(VolumeFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function renderChart(data, symbol)
	if not data or #data == 0 then return end

	clearChart()
	candles = data

	local maxPrice = 0
	local minPrice = math.huge
	local maxVol = 0
	for _, c in ipairs(data) do
		if c.h > maxPrice then maxPrice = c.h end
		if c.l < minPrice then minPrice = c.l end
		if c.v > maxVol then maxVol = c.v end
	end

	local priceRange = maxPrice - minPrice
	if priceRange == 0 then priceRange = 1 end

	local canvasWidth = ChartCanvas.AbsoluteSize.X
	local canvasHeight = ChartCanvas.AbsoluteSize.Y
	local barWidth = math.max(2, (canvasWidth / #data) * 0.8)

	for i, c in ipairs(data) do
		local x = ((i - 1) / #data) * canvasWidth
		local isGreen = c.c >= c.o
		local color = isGreen and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 80, 80)

		-- Candle body
		local bodyTop = ((maxPrice - math.max(c.o, c.c)) / priceRange) * canvasHeight
		local bodyHeight = math.max(1, (math.abs(c.c - c.o) / priceRange) * canvasHeight)

		local body = Instance.new("Frame")
		body.Size = UDim2.new(0, barWidth, 0, bodyHeight)
		body.Position = UDim2.new(0, x, 0, bodyTop)
		body.BackgroundColor3 = color
		body.BorderSizePixel = 0
		body.Parent = ChartCanvas

		-- Wick (high-low line)
		local wickTop = ((maxPrice - c.h) / priceRange) * canvasHeight
		local wickHeight = math.max(1, ((c.h - c.l) / priceRange) * canvasHeight)

		local wick = Instance.new("Frame")
		wick.Size = UDim2.new(0, 1, 0, wickHeight)
		wick.Position = UDim2.new(0, x + barWidth / 2, 0, wickTop)
		wick.BackgroundColor3 = color
		wick.BorderSizePixel = 0
		wick.Parent = ChartCanvas

		-- Volume bar
		if maxVol > 0 then
			local volBarHeight = math.max(1, (c.v / maxVol) * 35)
			local vbar = Instance.new("Frame")
			vbar.Size = UDim2.new(0, barWidth, 0, volBarHeight)
			vbar.Position = UDim2.new(0, x, 1, -volBarHeight)
			vbar.BackgroundColor3 = isGreen and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(200, 60, 60)
			vbar.BorderSizePixel = 0
			vbar.BackgroundTransparency = 0.5
			vbar.Parent = VolumeFrame
		end
	end

	ChartTitle.Text = symbol .. " — " .. activeTF
	PriceAxis.Text = string.format("$%.2f\n\n$%.2f", maxPrice, minPrice)
end

-- ============================================================
-- Public API — called from MarketScreen when stock is clicked
-- ============================================================
_G.ShowChart = function(symbol, historyData)
	ChartFrame.Visible = true
	renderChart(historyData, symbol)
end

_G.HideChart = function()
	ChartFrame.Visible = false
end
