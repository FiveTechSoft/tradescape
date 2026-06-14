-- ClubScreen.client.lua — Club panel: create, join, chat, members
-- Place in: StarterPlayer/StarterPlayerScripts/UI/ClubScreen (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local CreateClub = NetworkEvents:WaitForChild("CreateClub")
local GetClubInfo = NetworkEvents:WaitForChild("GetClubInfo")
local InviteToClub = NetworkEvents:WaitForChild("InviteToClub")
local JoinClub = NetworkEvents:WaitForChild("JoinClub")
local LeaveClub = NetworkEvents:WaitForChild("LeaveClub")
local SendClubChat = NetworkEvents:WaitForChild("SendClubChat")
local KickFromClub = NetworkEvents:WaitForChild("KickFromClub")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ClubScreen"
ScreenGui.Enabled = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Backdrop = Instance.new("Frame")
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 0.5
Backdrop.Parent = ScreenGui

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0.5, 0, 0.7, 0)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
Panel.BorderSizePixel = 1
Panel.BorderColor3 = Color3.fromRGB(50, 55, 65)
Panel.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Text = "Trading Club"
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(0, 200, 100)
Title.Size = UDim2.new(0.5, 0, 0, 36)
Title.Position = UDim2.new(0, 12, 0, 8)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

-- Content area
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -100)
Content.Position = UDim2.new(0, 12, 0, 48)
Content.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
Content.ScrollBarThickness = 6
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Panel

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 6)
ContentList.Parent = Content

-- Chat input
local ChatBox = Instance.new("TextBox")
ChatBox.Size = UDim2.new(0.7, 0, 0, 30)
ChatBox.Position = UDim2.new(0, 12, 1, -42)
ChatBox.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
ChatBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatBox.Font = Enum.Font.Gotham
ChatBox.TextSize = 14
ChatBox.PlaceholderText = "Type a message..."
ChatBox.Parent = Panel

local SendBtn = Instance.new("TextButton")
SendBtn.Text = "Send"
SendBtn.TextSize = 14
SendBtn.Font = Enum.Font.Gotham
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
SendBtn.Size = UDim2.new(0.2, 0, 0, 30)
SendBtn.Position = UDim2.new(0.75, 0, 1, -42)
SendBtn.Parent = Panel

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = Panel

CloseBtn.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)
Backdrop.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)

-- Refresh club info
local function refreshClub()
	for _, child in ipairs(Content:GetChildren()) do
		if child:IsA("GuiObject") and child ~= ContentList then child:Destroy() end
	end

	local club = GetClubInfo:InvokeServer()
	if not club then
		-- Show create/join form
		local lbl = Instance.new("TextLabel")
		lbl.Text = "You're not in a club. Press C to create or ask for an invite."
		lbl.TextSize = 14; lbl.Font = Enum.Font.Gotham
		lbl.TextColor3 = Color3.fromRGB(180, 185, 195)
		lbl.Size = UDim2.new(1, 0, 0, 40)
		lbl.TextWrapped = true; lbl.BackgroundTransparency = 1
		lbl.Parent = Content
		ChatBox.Visible = false; SendBtn.Visible = false
		return
	end

	ChatBox.Visible = true; SendBtn.Visible = true
	Title.Text = club.name or "Club"

	-- Members
	local membersLabel = Instance.new("TextLabel")
	membersLabel.Text = string.format("Members (%d/20)", #(club.members or {}))
	membersLabel.TextSize = 16; membersLabel.Font = Enum.Font.GothamBold
	membersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	membersLabel.Size = UDim2.new(1, 0, 0, 24)
	membersLabel.Parent = Content

	for _, memberId in ipairs(club.members or {}) do
		local role = memberId == club.ownerId and " 👑" or ""
		local m = Instance.new("TextLabel")
		m.Text = "• Player " .. tostring(memberId) .. role
		m.TextSize = 13; m.Font = Enum.Font.Gotham
		m.TextColor3 = Color3.fromRGB(200, 200, 200)
		m.Size = UDim2.new(1, 0, 0, 20)
		m.Parent = Content
	end

	-- Chat messages
	local chatLabel = Instance.new("TextLabel")
	chatLabel.Text = "Chat"
	chatLabel.TextSize = 16; chatLabel.Font = Enum.Font.GothamBold
	chatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	chatLabel.Size = UDim2.new(1, 0, 0, 24)
	chatLabel.Parent = Content

	for _, msg in ipairs(club.chat or {}) do
		local m = Instance.new("TextLabel")
		m.Text = string.format("[%s] %s", msg.username or "?", msg.message or "")
		m.TextSize = 12; m.Font = Enum.Font.Gotham
		m.TextColor3 = Color3.fromRGB(180, 185, 195)
		m.Size = UDim2.new(1, 0, 0, 20)
		m.Parent = Content
	end

	-- Stats
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Text = string.format("Club Value: $%.0f | Weekly Profit: $%.0f",
		club.stats and club.stats.totalValue or 0,
		club.stats and club.stats.weeklyProfit or 0)
	statsLabel.TextSize = 13; statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
	statsLabel.Size = UDim2.new(1, 0, 0, 24)
	statsLabel.Parent = Content

	local itemCount = (#(club.members or {}) + #(club.chat or {}) + 5)
	Content.CanvasSize = UDim2.new(0, 0, 0, itemCount * 24)
end

SendBtn.MouseButton1Click:Connect(function()
	local msg = ChatBox.Text
	if #msg > 0 then
		SendClubChat:InvokeServer(msg)
		ChatBox.Text = ""
		refreshClub()
	end
end)

-- Open with C key
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.C then
		ScreenGui.Enabled = not ScreenGui.Enabled
		if ScreenGui.Enabled then refreshClub() end
	end
end)
