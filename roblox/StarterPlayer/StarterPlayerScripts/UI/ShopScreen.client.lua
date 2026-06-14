-- ShopScreen.client.lua — Robux shop for cosmetic items
-- Place in: StarterPlayer/StarterPlayerScripts/UI/ShopScreen (LocalScript)

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local GetShopItems = NetworkEvents:WaitForChild("GetShopItems")
local GetTheme = NetworkEvents:WaitForChild("GetTheme")
local SetTheme = NetworkEvents:WaitForChild("SetTheme")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShopScreen"
ScreenGui.Enabled = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Backdrop = Instance.new("Frame")
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 0.5
Backdrop.Parent = ScreenGui

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0.55, 0, 0.75, 0)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
Panel.BorderSizePixel = 1
Panel.BorderColor3 = Color3.fromRGB(50, 55, 65)
Panel.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Shop"
Title.TextSize = 22; Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.Size = UDim2.new(0.5, 0, 0, 36)
Title.Position = UDim2.new(0, 12, 0, 8)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

local Subtitle = Instance.new("TextLabel")
Subtitle.Text = "Cosmetics only — no gameplay advantage"
Subtitle.TextSize = 12; Subtitle.Font = Enum.Font.Gotham
Subtitle.TextColor3 = Color3.fromRGB(150, 155, 165)
Subtitle.Size = UDim2.new(0.5, 0, 0, 20)
Subtitle.Position = UDim2.new(0, 14, 0, 40)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Panel

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -72)
Content.Position = UDim2.new(0, 12, 0, 64)
Content.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
Content.ScrollBarThickness = 6
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Panel

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 8)
ContentList.Parent = Content

-- Refresh shop from server
local function refresh()
	for _, child in ipairs(Content:GetChildren()) do
		if child:IsA("GuiObject") and child ~= ContentList then child:Destroy() end
	end

	local ok, items = pcall(function() return GetShopItems:InvokeServer() end)
	if not ok or not items then
		local lbl = Instance.new("TextLabel")
		lbl.Text = "Shop unavailable"
		lbl.TextSize = 14; lbl.Font = Enum.Font.Gotham
		lbl.TextColor3 = Color3.fromRGB(180, 185, 195)
		lbl.Size = UDim2.new(1, 0, 0, 30)
		lbl.Parent = Content
		return
	end

	for _, item in ipairs(items) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 64)
		card.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
		card.Parent = Content

		local name = Instance.new("TextLabel")
		name.Text = item.name; name.TextSize = 16; name.Font = Enum.Font.GothamBold
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.Size = UDim2.new(0.5, 0, 0, 24)
		name.Position = UDim2.new(0, 10, 0, 6)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Text = item.description; desc.TextSize = 12; desc.Font = Enum.Font.Gotham
		desc.TextColor3 = Color3.fromRGB(150, 155, 165)
		desc.Size = UDim2.new(0.5, 0, 0, 20)
		desc.Position = UDim2.new(0, 10, 0, 32)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = card

		local price = Instance.new("TextLabel")
		price.Text = string.format("R$ %d", item.robux)
		price.TextSize = 20; price.Font = Enum.Font.GothamBold
		price.TextColor3 = Color3.fromRGB(255, 200, 0)
		price.Size = UDim2.new(0.2, 0, 0, 30)
		price.Position = UDim2.new(0.55, 0, 0, 8)
		price.TextXAlignment = Enum.TextXAlignment.Center
		price.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Text = "Buy"
		buyBtn.TextSize = 14; buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
		buyBtn.Size = UDim2.new(0.2, 0, 0, 30)
		buyBtn.Position = UDim2.new(0.55, 0, 0, 38)
		buyBtn.Parent = card

		buyBtn.MouseButton1Click:Connect(function()
			-- Prompt Robux purchase via MarketplaceService
			-- (Product IDs must be set in Roblox dashboard first)
			MarketplaceService:PromptProductPurchase(player, item.id)
		end)
	end

	Content.CanvasSize = UDim2.new(0, 0, 0, #items * 72)
end

-- Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"; CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = Panel
CloseBtn.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)
Backdrop.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)

-- Theme picker
local ThemeLabel = Instance.new("TextLabel")
ThemeLabel.Text = "Theme:"; ThemeLabel.TextSize = 13
ThemeLabel.Font = Enum.Font.Gotham; ThemeLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
ThemeLabel.Size = UDim2.new(0, 50, 0, 20)
ThemeLabel.Position = UDim2.new(0, 14, 0, 44)
ThemeLabel.Parent = Panel

local themes = { "dark", "light", "matrix", "midnight", "terminal" }
local themeNames = { dark = "Dark", light = "Light", matrix = "Matrix", midnight = "Midnight", terminal = "Terminal" }
local themeBtns = {}
for i, tid in ipairs(themes) do
	local tbtn = Instance.new("TextButton")
	tbtn.Text = themeNames[tid]; tbtn.TextSize = 10; tbtn.Font = Enum.Font.Gotham
	tbtn.TextColor3 = Color3.fromRGB(150, 155, 165)
	tbtn.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	tbtn.Size = UDim2.new(0, 50, 0, 20)
	tbtn.Position = UDim2.new(0.15 + (i - 1) * 0.11, 0, 0, 44)
	tbtn.Parent = Panel

	tbtn.MouseButton1Click:Connect(function()
		SetTheme:InvokeServer(tid)
		_G.ApplyTheme(tid)
		for _, b in ipairs(themeBtns) do b.BackgroundColor3 = Color3.fromRGB(35, 40, 50) end
		tbtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	end)
	table.insert(themeBtns, tbtn)
end

-- Open with S key
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.S then
		ScreenGui.Enabled = not ScreenGui.Enabled
		if ScreenGui.Enabled then refresh() end
	end
end)
