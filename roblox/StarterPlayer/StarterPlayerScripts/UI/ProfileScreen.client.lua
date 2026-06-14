-- ProfileScreen.client.lua — Player profile: XP bar, level, rank, perks, missions, office
-- Place in: StarterPlayer/StarterPlayerScripts/UI/ProfileScreen (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")

local GetXPProgress = NetworkEvents:WaitForChild("GetXPProgress")
local GetAvailablePerks = NetworkEvents:WaitForChild("GetAvailablePerks")
local UnlockPerk = NetworkEvents:WaitForChild("UnlockPerk")
local GetDailyMissions = NetworkEvents:WaitForChild("GetDailyMissions")
local ClaimMission = NetworkEvents:WaitForChild("ClaimMission")
local GetOfficeInfo = NetworkEvents:WaitForChild("GetOfficeInfo")

-- Create screen container (hidden by default, toggle with Tab or button)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProfileScreen"
ScreenGui.Enabled = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Semi-transparent backdrop
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Backdrop.BackgroundTransparency = 0.5
Backdrop.Parent = ScreenGui

-- Main panel (centered)
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0.6, 0, 0.8, 0)
Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
Panel.BorderSizePixel = 1
Panel.BorderColor3 = Color3.fromRGB(50, 55, 65)
Panel.Parent = ScreenGui

-- Top bar: Level + Rank
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
TitleBar.Parent = Panel

local LevelLabel = Instance.new("TextLabel")
LevelLabel.Name = "Level"
LevelLabel.Text = "Level 1"
LevelLabel.TextSize = 28
LevelLabel.Font = Enum.Font.GothamBold
LevelLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
LevelLabel.Size = UDim2.new(0.5, 0, 1, 0)
LevelLabel.Position = UDim2.new(0, 16, 0, 0)
LevelLabel.TextXAlignment = Enum.TextXAlignment.Left
LevelLabel.Parent = TitleBar

local RankLabel = Instance.new("TextLabel")
RankLabel.Name = "Rank"
RankLabel.Text = "Novato"
RankLabel.TextSize = 20
RankLabel.Font = Enum.Font.Gotham
RankLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
RankLabel.Size = UDim2.new(0.5, -16, 1, 0)
RankLabel.Position = UDim2.new(0.5, 0, 0, 0)
RankLabel.TextXAlignment = Enum.TextXAlignment.Right
RankLabel.Parent = TitleBar

-- XP Bar
local XPBarFrame = Instance.new("Frame")
XPBarFrame.Name = "XPBarFrame"
XPBarFrame.Size = UDim2.new(1, -32, 0, 24)
XPBarFrame.Position = UDim2.new(0, 16, 0, 68)
XPBarFrame.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
XPBarFrame.BorderSizePixel = 0
XPBarFrame.Parent = Panel

local XPBarFill = Instance.new("Frame")
XPBarFill.Name = "Fill"
XPBarFill.Size = UDim2.new(0, 0, 1, 0)
XPBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
XPBarFill.BorderSizePixel = 0
XPBarFill.Parent = XPBarFrame

local XPText = Instance.new("TextLabel")
XPText.Name = "XPText"
XPText.Text = "0 / 100 XP"
XPText.TextSize = 12
XPText.Font = Enum.Font.Gotham
XPText.TextColor3 = Color3.fromRGB(255, 255, 255)
XPText.Size = UDim2.new(1, 0, 1, 0)
XPText.BackgroundTransparency = 1
XPText.Parent = XPBarFrame

-- Office display
local OfficeLabel = Instance.new("TextLabel")
OfficeLabel.Name = "Office"
OfficeLabel.Text = "Office: Phone 📱"
OfficeLabel.TextSize = 14
OfficeLabel.Font = Enum.Font.Gotham
OfficeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
OfficeLabel.Size = UDim2.new(1, -32, 0, 22)
OfficeLabel.Position = UDim2.new(0, 16, 0, 100)
OfficeLabel.TextXAlignment = Enum.TextXAlignment.Left
OfficeLabel.Parent = Panel

-- Tab selector: Perks | Missions
local TabFrame = Instance.new("Frame")
TabFrame.Name = "TabFrame"
TabFrame.Size = UDim2.new(1, -32, 0, 30)
TabFrame.Position = UDim2.new(0, 16, 0, 130)
TabFrame.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
TabFrame.Parent = Panel

local PerksTab = Instance.new("TextButton")
PerksTab.Name = "PerksTab"
PerksTab.Text = "Perks"
PerksTab.TextSize = 16
PerksTab.Font = Enum.Font.GothamBold
PerksTab.TextColor3 = Color3.fromRGB(0, 200, 100)
PerksTab.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
PerksTab.Size = UDim2.new(0.5, 0, 1, 0)
PerksTab.Parent = TabFrame

local MissionsTab = Instance.new("TextButton")
MissionsTab.Name = "MissionsTab"
MissionsTab.Text = "Missions"
MissionsTab.TextSize = 16
MissionsTab.Font = Enum.Font.Gotham
MissionsTab.TextColor3 = Color3.fromRGB(150, 155, 165)
MissionsTab.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
MissionsTab.Size = UDim2.new(0.5, 0, 1, 0)
MissionsTab.Position = UDim2.new(0.5, 0, 0, 0)
MissionsTab.Parent = TabFrame

-- Content area (scrollable)
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -32, 1, -175)
ContentFrame.Position = UDim2.new(0, 16, 0, 165)
ContentFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
ContentFrame.ScrollBarThickness = 6
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = Panel

local ContentList = Instance.new("UIListLayout")
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Padding = UDim.new(0, 6)
ContentList.Parent = ContentFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Text = "X"
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = Panel

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = false
end)

Backdrop.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = false
end)

-- ============================================================
-- Rendering helpers
-- ============================================================
local activeTab = "perks"

local function clearContent()
	for _, child in ipairs(ContentFrame:GetChildren()) do
		if child:IsA("GuiObject") and child ~= ContentList then
			child:Destroy()
		end
	end
end

-- ============================================================
-- XP + Level refresh
-- ============================================================
local function refreshProfile()
	local ok, data = pcall(function()
		return GetXPProgress:InvokeServer()
	end)
	if ok and data then
		LevelLabel.Text = string.format("Level %d", data.currentLevel)
		RankLabel.Text = data.rank

		local barPercent = math.clamp(data.progress, 0, 1)
		XPBarFill.Size = UDim2.new(barPercent, 0, 1, 0)
		XPText.Text = string.format("%d / %d XP", data.totalXP, data.nextLevelXP)
	end

	local ok2, office = pcall(function()
		return GetOfficeInfo:InvokeServer()
	end)
	if ok2 and office then
		local icons = { "📱", "💻", "🖥️", "📊", "🏢" }
		local icon = icons[office.level + 1] or "📱"
		OfficeLabel.Text = string.format("Office: %s %s", office.name, icon)
		if office.nextLevel then
			OfficeLabel.Text = OfficeLabel.Text .. string.format(" | Next: %s (%.0f%%)",
				office.nextLevel.name, office.progress * 100)
		end
	end
end

-- ============================================================
-- Perks tab
-- ============================================================
local function renderPerks()
	clearContent()

	local ok, perks = pcall(function()
		return GetAvailablePerks:InvokeServer()
	end)
	if not ok or not perks then return end

	for _, perk in ipairs(perks) do
		local card = Instance.new("Frame")
		card.Name = "Perk_" .. perk.id
		card.Size = UDim2.new(1, 0, 0, 48)
		card.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
		card.Parent = ContentFrame

		local name = Instance.new("TextLabel")
		name.Text = perk.name
		name.TextSize = 16
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.Size = UDim2.new(0.5, 0, 0.5, 0)
		name.Position = UDim2.new(0, 10, 0, 4)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Text = perk.description
		desc.TextSize = 12
		desc.Font = Enum.Font.Gotham
		desc.TextColor3 = Color3.fromRGB(150, 155, 165)
		desc.Size = UDim2.new(0.5, 0, 0.5, 0)
		desc.Position = UDim2.new(0, 10, 0.5, 0)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = card

		local cost = Instance.new("TextLabel")
		cost.Text = string.format("%d pts", perk.cost)
		cost.TextSize = 14
		cost.Font = Enum.Font.Gotham
		cost.TextColor3 = Color3.fromRGB(200, 200, 200)
		cost.Size = UDim2.new(0.2, 0, 0.5, 0)
		cost.Position = UDim2.new(0.6, 0, 0, 4)
		cost.TextXAlignment = Enum.TextXAlignment.Right
		cost.Parent = card

		local unlockBtn = Instance.new("TextButton")
		unlockBtn.Text = perk.canUnlock and "Unlock" or (perk.blockedReason or "Locked")
		unlockBtn.TextSize = 12
		unlockBtn.Font = Enum.Font.Gotham
		unlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		unlockBtn.BackgroundColor3 = perk.canUnlock and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(80, 80, 80)
		unlockBtn.Size = UDim2.new(0.25, 0, 0, 30)
		unlockBtn.Position = UDim2.new(0.7, 0, 0.5, -8)
		unlockBtn.AutoButtonColor = false
		unlockBtn.Parent = card

		if perk.canUnlock then
			unlockBtn.MouseButton1Click:Connect(function()
				local ok2, result = pcall(function()
					return UnlockPerk:InvokeServer(perk.id)
				end)
				if ok2 and result and result.success then
					renderPerks()
					refreshProfile()
				end
			end)
		end
	end

	ContentFrame.CanvasSize = UDim2.new(0, 0, 0, #perks * 54)
end

-- ============================================================
-- Missions tab
-- ============================================================
local function renderMissions()
	clearContent()

	local ok, missions = pcall(function()
		return GetDailyMissions:InvokeServer()
	end)
	if not ok or not missions then return end

	for _, mission in ipairs(missions) do
		local card = Instance.new("Frame")
		card.Name = "Mission_" .. mission.id
		card.Size = UDim2.new(1, 0, 0, 52)
		card.BackgroundColor3 = mission.done and Color3.fromRGB(20, 50, 30) or Color3.fromRGB(28, 32, 40)
		card.Parent = ContentFrame

		local name = Instance.new("TextLabel")
		name.Text = mission.name
		name.TextSize = 15
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = mission.done and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 255, 255)
		name.Size = UDim2.new(0.5, 0, 0.5, 0)
		name.Position = UDim2.new(0, 10, 0, 3)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Text = mission.description
		desc.TextSize = 12
		desc.Font = Enum.Font.Gotham
		desc.TextColor3 = Color3.fromRGB(150, 155, 165)
		desc.Size = UDim2.new(0.5, 0, 0.5, 0)
		desc.Position = UDim2.new(0, 10, 0.5, 0)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = card

		local progress = Instance.new("TextLabel")
		if mission.progress >= mission.target then
			progress.Text = "Done!"
			progress.TextColor3 = Color3.fromRGB(0, 200, 100)
		else
			progress.Text = string.format("%d/%d", mission.progress, mission.target)
			progress.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
		progress.TextSize = 13
		progress.Font = Enum.Font.Gotham
		progress.Size = UDim2.new(0.2, 0, 0.5, 0)
		progress.Position = UDim2.new(0.6, 0, 0, 3)
		progress.TextXAlignment = Enum.TextXAlignment.Right
		progress.Parent = card

		local reward = Instance.new("TextLabel")
		reward.Text = string.format("+%d XP", mission.rewardXP)
		reward.TextSize = 12
		reward.Font = Enum.Font.Gotham
		reward.TextColor3 = Color3.fromRGB(180, 185, 195)
		reward.Size = UDim2.new(0.2, 0, 0.5, 0)
		reward.Position = UDim2.new(0.6, 0, 0.5, 0)
		reward.TextXAlignment = Enum.TextXAlignment.Right
		reward.Parent = card

		if mission.progress >= mission.target and not mission.oneTime then
			local claimBtn = Instance.new("TextButton")
			claimBtn.Text = "Claim"
			claimBtn.TextSize = 12
			claimBtn.Font = Enum.Font.Gotham
			claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			claimBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
			claimBtn.Size = UDim2.new(0.15, 0, 0, 28)
			claimBtn.Position = UDim2.new(0.82, 0, 0.5, -6)
			claimBtn.Parent = card

			claimBtn.MouseButton1Click:Connect(function()
				local ok2, result = pcall(function()
					return ClaimMission:InvokeServer(mission.id)
				end)
				if ok2 and result and result.success then
					renderMissions()
					refreshProfile()
				end
			end)
		end
	end

	ContentFrame.CanvasSize = UDim2.new(0, 0, 0, #missions * 58)
end

-- ============================================================
-- Tab switching
-- ============================================================
PerksTab.MouseButton1Click:Connect(function()
	activeTab = "perks"
	PerksTab.TextColor3 = Color3.fromRGB(0, 200, 100)
	PerksTab.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	PerksTab.Font = Enum.Font.GothamBold
	MissionsTab.TextColor3 = Color3.fromRGB(150, 155, 165)
	MissionsTab.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
	MissionsTab.Font = Enum.Font.Gotham
	renderPerks()
end)

MissionsTab.MouseButton1Click:Connect(function()
	activeTab = "missions"
	MissionsTab.TextColor3 = Color3.fromRGB(0, 200, 100)
	MissionsTab.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	MissionsTab.Font = Enum.Font.GothamBold
	PerksTab.TextColor3 = Color3.fromRGB(150, 155, 165)
	PerksTab.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
	PerksTab.Font = Enum.Font.Gotham
	renderMissions()
end)

-- ============================================================
-- Open/close with key
-- ============================================================
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		local isOpen = ScreenGui.Enabled
		ScreenGui.Enabled = not isOpen
		if not isOpen then
			refreshProfile()
			if activeTab == "perks" then
				renderPerks()
			else
				renderMissions()
			end
		end
	end
end)
