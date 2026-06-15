-- InventoryUI.client.lua — Shows collected stocks and collection notifications
-- Place in: StarterPlayerScripts/InventoryUI (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local StockCollected = ReplicatedStorage:WaitForChild("StockCollected")

-- ============================================================
-- ScreenGui
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InventoryUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- ============================================================
-- Collected counter (top right)
-- ============================================================
local CounterFrame = Instance.new("Frame")
CounterFrame.Name = "Counter"
CounterFrame.Size = UDim2.new(0, 200, 0, 40)
CounterFrame.Position = UDim2.new(1, -220, 0, 10)
CounterFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
CounterFrame.BackgroundTransparency = 0.2
CounterFrame.BorderSizePixel = 0
CounterFrame.Parent = ScreenGui

local CounterCorner = Instance.new("UICorner")
CounterCorner.CornerRadius = UDim.new(0, 8)
CounterCorner.Parent = CounterFrame

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Name = "Text"
CounterLabel.Size = UDim2.new(1, -16, 1, 0)
CounterLabel.Position = UDim2.new(0, 8, 0, 0)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "Collected: 0 / 16"
CounterLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
CounterLabel.TextSize = 16
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
CounterLabel.Parent = CounterFrame

-- ============================================================
-- Collection notification (center, fades in/out)
-- ============================================================
local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "Notification"
NotifFrame.Size = UDim2.new(0, 350, 0, 80)
NotifFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
NotifFrame.AnchorPoint = Vector2.new(0.5, 0.5)
NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
NotifFrame.BackgroundTransparency = 0.1
NotifFrame.BorderSizePixel = 0
NotifFrame.Visible = false
NotifFrame.ZIndex = 100
NotifFrame.Parent = ScreenGui

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 12)
NotifCorner.Parent = NotifFrame

local NotifTitle = Instance.new("TextLabel")
NotifTitle.Name = "Title"
NotifTitle.Size = UDim2.new(1, -20, 0, 30)
NotifTitle.Position = UDim2.new(0, 10, 0, 8)
NotifTitle.BackgroundTransparency = 1
NotifTitle.Text = "STOCK COLLECTED!"
NotifTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
NotifTitle.TextSize = 18
NotifTitle.Font = Enum.Font.GothamBold
NotifTitle.ZIndex = 101
NotifTitle.Parent = NotifFrame

local NotifSymbol = Instance.new("TextLabel")
NotifSymbol.Name = "Symbol"
NotifSymbol.Size = UDim2.new(1, -20, 0, 28)
NotifSymbol.Position = UDim2.new(0, 10, 0, 38)
NotifSymbol.BackgroundTransparency = 1
NotifSymbol.Text = ""
NotifSymbol.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifSymbol.TextSize = 22
NotifSymbol.Font = Enum.Font.GothamBold
NotifSymbol.ZIndex = 101
NotifSymbol.Parent = NotifFrame

-- ============================================================
-- Inventory panel (toggle with I key)
-- ============================================================
local InvFrame = Instance.new("Frame")
InvFrame.Name = "Inventory"
InvFrame.Size = UDim2.new(0, 400, 0, 500)
InvFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InvFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InvFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
InvFrame.BackgroundTransparency = 0.05
InvFrame.BorderSizePixel = 0
InvFrame.Visible = false
InvFrame.ZIndex = 200
InvFrame.Parent = ScreenGui

local InvCorner = Instance.new("UICorner")
InvCorner.CornerRadius = UDim.new(0, 12)
InvCorner.Parent = InvFrame

local InvTitle = Instance.new("TextLabel")
InvTitle.Name = "Title"
InvTitle.Size = UDim2.new(1, -20, 0, 40)
InvTitle.Position = UDim2.new(0, 10, 0, 10)
InvTitle.BackgroundTransparency = 1
InvTitle.Text = "My Stocks"
InvTitle.TextColor3 = Color3.fromRGB(0, 200, 100)
InvTitle.TextSize = 24
InvTitle.Font = Enum.Font.GothamBold
InvTitle.TextXAlignment = Enum.TextXAlignment.Left
InvTitle.ZIndex = 201
InvTitle.Parent = InvFrame

local InvCloseBtn = Instance.new("TextButton")
InvCloseBtn.Name = "CloseBtn"
InvCloseBtn.Size = UDim2.new(0, 32, 0, 32)
InvCloseBtn.Position = UDim2.new(1, -42, 0, 10)
InvCloseBtn.BackgroundTransparency = 1
InvCloseBtn.Text = "X"
InvCloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
InvCloseBtn.TextSize = 20
InvCloseBtn.ZIndex = 201
InvCloseBtn.Parent = InvFrame

local InvScroll = Instance.new("ScrollingFrame")
InvScroll.Name = "List"
InvScroll.Size = UDim2.new(1, -20, 1, -60)
InvScroll.Position = UDim2.new(0, 10, 0, 55)
InvScroll.BackgroundTransparency = 1
InvScroll.ScrollBarThickness = 6
InvScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
InvScroll.ZIndex = 201
InvScroll.Parent = InvFrame

local InvLayout = Instance.new("UIListLayout")
InvLayout.SortOrder = Enum.SortOrder.LayoutOrder
InvLayout.Padding = UDim.new(0, 4)
InvLayout.Parent = InvScroll

-- ============================================================
-- State
-- ============================================================
local collected = {}
local invOpen = false

local function updateCounter()
	CounterLabel.Text = string.format("Collected: %d / 16", #collected)
end

local function showNotification(symbol, stockName)
	NotifSymbol.Text = symbol .. " — " .. stockName
	NotifFrame.Visible = true
	NotifFrame.BackgroundTransparency = 0.1

	task.delay(2, function()
		for i = 0, 10 do
			NotifFrame.BackgroundTransparency = 0.1 + (i / 10) * 0.9
			NotifTitle.TextTransparency = i / 10
			NotifSymbol.TextTransparency = i / 10
			task.wait(0.05)
		end
		NotifFrame.Visible = false
	end)
end

local function refreshInventory()
	for _, child in ipairs(InvScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, stock in ipairs(collected) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. stock.symbol
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
		row.BorderSizePixel = 0
		row.ZIndex = 202
		row.Parent = InvScroll

		local sym = Instance.new("TextLabel")
		sym.Size = UDim2.new(0, 80, 1, 0)
		sym.Position = UDim2.new(0, 8, 0, 0)
		sym.BackgroundTransparency = 1
		sym.Text = stock.symbol
		sym.TextColor3 = Color3.fromRGB(0, 200, 100)
		sym.TextSize = 16
		sym.Font = Enum.Font.GothamBold
		sym.TextXAlignment = Enum.TextXAlignment.Left
		sym.ZIndex = 203
		sym.Parent = row

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -100, 1, 0)
		name.Position = UDim2.new(0, 90, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = stock.name
		name.TextColor3 = Color3.fromRGB(180, 185, 195)
		name.TextSize = 14
		name.Font = Enum.Font.Gotham
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 203
		name.Parent = row

		local num = Instance.new("TextLabel")
		num.Size = UDim2.new(0, 30, 1, 0)
		num.Position = UDim2.new(1, -38, 0, 0)
		num.BackgroundTransparency = 1
		num.Text = "#" .. i
		num.TextColor3 = Color3.fromRGB(100, 105, 115)
		num.TextSize = 14
		num.Font = Enum.Font.Gotham
		num.ZIndex = 203
		num.Parent = row
	end

	InvScroll.CanvasSize = UDim2.new(0, 0, 0, #collected * 52)
end

-- ============================================================
-- Listen for collections
-- ============================================================
StockCollected.OnClientEvent:Connect(function(symbol, stockName)
	table.insert(collected, { symbol = symbol, name = stockName })
	updateCounter()
	showNotification(symbol, stockName)
	refreshInventory()
end)

-- ============================================================
-- Toggle inventory with I key
-- ============================================================
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then
		invOpen = not invOpen
		InvFrame.Visible = invOpen
		if invOpen then
			refreshInventory()
		end
	end
end)

InvCloseBtn.MouseButton1Click:Connect(function()
	invOpen = false
	InvFrame.Visible = false
end)

print("[InventoryUI] Ready — Press I to open inventory")
