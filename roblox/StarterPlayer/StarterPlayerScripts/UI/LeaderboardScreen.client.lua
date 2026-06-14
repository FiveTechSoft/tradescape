-- LeaderboardScreen.client.lua — Global leaderboard: value, profit%, level
-- Place in: StarterPlayer/StarterPlayerScripts/UI/LeaderboardScreen (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local GetGlobalLeaderboard = NetworkEvents:WaitForChild("GetGlobalLeaderboard")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeaderboardScreen"
ScreenGui.Enabled = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Backdrop = Instance.new("Frame")
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 0.5
Backdrop.Parent = ScreenGui

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0.45, 0, 0.7, 0)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
Panel.BorderSizePixel = 1
Panel.BorderColor3 = Color3.fromRGB(50, 55, 65)
Panel.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Leaderboard"
Title.TextSize = 22; Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.Size = UDim2.new(0.5, 0, 0, 36)
Title.Position = UDim2.new(0, 12, 0, 8)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -52)
Content.Position = UDim2.new(0, 12, 0, 48)
Content.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
Content.ScrollBarThickness = 6
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Panel

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 3)
ContentList.Parent = Content

-- Tabs
local tabs = { "Value", "Level" }
local tabBtns = {}
for i, tab in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Text = tab; btn.TextSize = 14; btn.Font = Enum.Font.Gotham
	btn.TextColor3 = i == 1 and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 155, 165)
	btn.Size = UDim2.new(0, 60, 0, 24)
	btn.Position = UDim2.new(0.6 + (i - 1) * 0.15, 0, 0, 8)
	btn.BackgroundTransparency = 1
	btn.Parent = Panel
	table.insert(tabBtns, btn)
end

local activeTab = "value"
tabBtns[1].MouseButton1Click:Connect(function() activeTab = "value"; refresh() end)
tabBtns[2].MouseButton1Click:Connect(function() activeTab = "level"; refresh() end)

local function refresh()
	for _, child in ipairs(Content:GetChildren()) do
		if child:IsA("GuiObject") and child ~= ContentList then child:Destroy() end
	end

	local entries = GetGlobalLeaderboard:InvokeServer(activeTab)
	if not entries then return end

	for i, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(24, 28, 36) or Color3.fromRGB(20, 24, 32)
		row.Parent = Content

		local rank = Instance.new("TextLabel")
		rank.Text = "#" .. tostring(i)
		rank.TextSize = 14; rank.Font = Enum.Font.GothamBold
		rank.TextColor3 = i <= 3 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(180, 185, 195)
		rank.Size = UDim2.new(0, 40, 1, 0)
		rank.Parent = row

		local name = Instance.new("TextLabel")
		name.Text = entry.rank or "Trader"
		name.TextSize = 14; name.Font = Enum.Font.Gotham
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.Size = UDim2.new(0.3, 0, 1, 0)
		name.Position = UDim2.new(0, 44, 0, 0)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local value = Instance.new("TextLabel")
		if activeTab == "value" then
			value.Text = string.format("$%.0f", entry.totalValue or 0)
		else
			value.Text = "Lv" .. tostring(entry.level or 1)
		end
		value.TextSize = 14; value.Font = Enum.Font.Gotham
		value.TextColor3 = Color3.fromRGB(0, 200, 100)
		value.Size = UDim2.new(0.4, 0, 1, 0)
		value.Position = UDim2.new(0.55, 0, 0, 0)
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.Parent = row
	end

	Content.CanvasSize = UDim2.new(0, 0, 0, #entries * 31)
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

-- Open with L key
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.L then
		ScreenGui.Enabled = not ScreenGui.Enabled
		if ScreenGui.Enabled then refresh() end
	end
end)
