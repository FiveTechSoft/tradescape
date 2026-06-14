-- NewsWidget.client.lua — "Why did this move?" news display
-- Place in: StarterPlayer/StarterPlayerScripts/UI/NewsWidget (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- News widget shown below chart
local ScreenGui = player.PlayerGui:WaitForChild("MarketScreen")

local NewsFrame = Instance.new("Frame")
NewsFrame.Name = "NewsWidget"
NewsFrame.Size = UDim2.new(1, -340, 0, 100)
NewsFrame.Position = UDim2.new(0, 330, 0.5, 10)
NewsFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
NewsFrame.BorderSizePixel = 1
NewsFrame.BorderColor3 = Color3.fromRGB(50, 55, 65)
NewsFrame.Visible = false
NewsFrame.Parent = ScreenGui

local NewsTitle = Instance.new("TextLabel")
NewsTitle.Name = "Title"
NewsTitle.Text = "Why did it move?"
NewsTitle.TextSize = 14
NewsTitle.Font = Enum.Font.GothamBold
NewsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
NewsTitle.Size = UDim2.new(1, -20, 0, 22)
NewsTitle.Position = UDim2.new(0, 10, 0, 4)
NewsTitle.TextXAlignment = Enum.TextXAlignment.Left
NewsTitle.Parent = NewsFrame

local NewsContent = Instance.new("ScrollingFrame")
NewsContent.Name = "Content"
NewsContent.Size = UDim2.new(1, -20, 1, -30)
NewsContent.Position = UDim2.new(0, 10, 0, 26)
NewsContent.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
NewsContent.ScrollBarThickness = 4
NewsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
NewsContent.Parent = NewsFrame

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 4)
ContentList.Parent = NewsContent

-- News items rendered as simple text labels
local function showNews(symbol, changePercent)
	-- For MVP, show educational content based on the move
	-- In production, fetch from /api/news/:symbol
	NewsFrame.Visible = true

	-- Clear old items
	for _, child in ipairs(NewsContent:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end

	local items = {}

	if math.abs(changePercent) > 5 then
		table.insert(items, string.format("%s moved %.1f%% today — significant volatility.", symbol, changePercent))
		table.insert(items, "Check if there's an earnings report, analyst upgrade/downgrade, or sector news.")
	elseif math.abs(changePercent) > 2 then
		table.insert(items, string.format("%s moved %.1f%% — moderate movement.", symbol, changePercent))
		table.insert(items, "Market sentiment or sector rotation may be driving this.")
	else
		table.insert(items, string.format("%s changed %.1f%% — normal market fluctuation.", symbol, changePercent))
	end

	table.insert(items, "Tip: Use limit orders to buy at your target price instead of market orders.")
	table.insert(items, "Tip: Diversify across sectors to reduce risk.")

	for i, text in ipairs(items) do
		local label = Instance.new("TextLabel")
		label.Text = "• " .. text
		label.TextSize = 12
		label.Font = Enum.Font.Gotham
		label.TextColor3 = Color3.fromRGB(180, 185, 195)
		label.Size = UDim2.new(1, 0, 0, 28)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextWrapped = true
		label.BackgroundTransparency = 1
		label.Parent = NewsContent
	end

	NewsContent.CanvasSize = UDim2.new(0, 0, 0, #items * 32)
end

_G.ShowNews = showNews
_G.HideNews = function()
	NewsFrame.Visible = false
end
