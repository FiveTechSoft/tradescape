-- StockSpawner.server.lua — Spawns collectible stock items around the city
-- Place in: ServerScriptService/StockSpawner (Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Stock definitions
local STOCK_DEFS = {
	{ symbol = "AAPL", name = "Apple Inc.", color = Color3.fromRGB(180, 180, 185) },
	{ symbol = "TSLA", name = "Tesla Inc.", color = Color3.fromRGB(200, 50, 50) },
	{ symbol = "MSFT", name = "Microsoft", color = Color3.fromRGB(0, 120, 215) },
	{ symbol = "GOOGL", name = "Alphabet", color = Color3.fromRGB(66, 133, 244) },
	{ symbol = "AMZN", name = "Amazon", color = Color3.fromRGB(255, 153, 0) },
	{ symbol = "NVDA", name = "NVIDIA", color = Color3.fromRGB(118, 185, 0) },
	{ symbol = "META", name = "Meta", color = Color3.fromRGB(0, 100, 200) },
	{ symbol = "NFLX", name = "Netflix", color = Color3.fromRGB(229, 9, 20) },
	{ symbol = "SPY", name = "S&P 500 ETF", color = Color3.fromRGB(0, 150, 100) },
	{ symbol = "AMD", name = "AMD", color = Color3.fromRGB(0, 155, 116) },
	{ symbol = "DIS", name = "Disney", color = Color3.fromRGB(0, 80, 165) },
	{ symbol = "BA", name = "Boeing", color = Color3.fromRGB(0, 50, 120) },
	{ symbol = "JPM", name = "JPMorgan", color = Color3.fromRGB(0, 70, 140) },
	{ symbol = "V", name = "Visa", color = Color3.fromRGB(26, 35, 126) },
	{ symbol = "INTC", name = "Intel", color = Color3.fromRGB(0, 113, 197) },
	{ symbol = "QQQ", name = "Nasdaq ETF", color = Color3.fromRGB(100, 50, 150) },
}

-- Spawn locations (spread across the massive city)
local SPAWN_POINTS = {
	-- Downtown (center)
	Vector3.new(-50, 2, -50), Vector3.new(30, 2, -30),
	Vector3.new(-20, 2, 40), Vector3.new(60, 2, 50),
	-- Northwest
	Vector3.new(-350, 2, -350), Vector3.new(-250, 2, -280),
	-- Northeast
	Vector3.new(350, 2, -350), Vector3.new(280, 2, -250),
	-- Mid-west
	Vector3.new(-400, 2, 0), Vector3.new(-300, 2, 100),
	-- Mid-east
	Vector3.new(400, 2, 0), Vector3.new(300, 2, 100),
	-- South (near beach)
	Vector3.new(-200, 2, 500), Vector3.new(200, 2, 500),
	-- Far corners
	Vector3.new(-600, 2, -600), Vector3.new(600, 2, -600),
}

-- Track collected stocks per player
local collectedStocks = {}

-- Create RemoteEvent
local StockCollected = Instance.new("RemoteEvent")
StockCollected.Name = "StockCollected"
StockCollected.Parent = ReplicatedStorage

local function collectStock(player, stockModel)
	local symbol = stockModel:GetAttribute("Symbol")
	local stockName = stockModel:GetAttribute("Name")

	if not symbol or collectedStocks[player.UserId][symbol] then return end

	-- Mark collected
	collectedStocks[player.UserId][symbol] = {
		symbol = symbol,
		name = stockName,
		collectedAt = os.time(),
	}
	stockModel:SetAttribute("Collected", true)

	-- Visual: make transparent
	local crystal = stockModel:FindFirstChild("Crystal")
	local ring = stockModel:FindFirstChild("Ring")
	local detection = stockModel:FindFirstChild("Detection")
	if crystal then crystal.Transparency = 0.7 end
	if ring then ring.Transparency = 0.9 end
	if detection then detection:Destroy() end

	-- Notify client
	StockCollected:FireClient(player, symbol, stockName)

	-- Respawn after 45 seconds
	task.delay(45, function()
		if stockModel and stockModel.Parent then
			stockModel:SetAttribute("Collected", false)
			if crystal then crystal.Transparency = 0 end
			if ring then ring.Transparency = 0.3 end
			-- Recreate detection
			local newDet = Instance.new("Part")
			newDet.Name = "Detection"
			newDet.Anchored = true
			newDet.Size = Vector3.new(10, 10, 10)
			newDet.Position = stockModel:GetPivot().Position
			newDet.Transparency = 1
			newDet.CanCollide = false
			newDet.Parent = stockModel
			setupDetection(newDet, stockModel)
		end
	end)

	print("[StockSpawner]", player.Name, "collected", symbol)
end

function setupDetection(detectionPart, stockModel)
	detectionPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if not collectedStocks[player.UserId] then return end
		if stockModel:GetAttribute("Collected") then return end

		collectStock(player, stockModel)
	end)
end

local function createStockItem(stockDef, position)
	local model = Instance.new("Model")
	model.Name = "Stock_" .. stockDef.symbol

	-- Crystal (floating, glowing)
	local crystal = Instance.new("Part")
	crystal.Name = "Crystal"
	crystal.Anchored = true
	crystal.Size = Vector3.new(2.5, 2.5, 2.5)
	crystal.Position = position
	crystal.Color = stockDef.color
	crystal.Material = Enum.Material.Neon
	crystal.Shape = Enum.PartType.Ball
	crystal.TopSurface = Enum.SurfaceType.Smooth
	crystal.CanCollide = false
	crystal.Parent = model

	-- Glow ring
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Anchored = true
	ring.Size = Vector3.new(4, 0.3, 4)
	ring.Position = position - Vector3.new(0, 0.8, 0)
	ring.Color = stockDef.color
	ring.Material = Enum.Material.Neon
	ring.Shape = Enum.PartType.Cylinder
	ring.Orientation = Vector3.new(0, 0, 90)
	ring.Transparency = 0.3
	ring.CanCollide = false
	ring.Parent = model

	-- Billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = crystal

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = stockDef.symbol
	label.TextColor3 = stockDef.color
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	-- Detection part (triggers collection)
	local detection = Instance.new("Part")
	detection.Name = "Detection"
	detection.Anchored = true
	detection.Size = Vector3.new(10, 10, 10)
	detection.Position = position
	detection.Transparency = 1
	detection.CanCollide = false
	detection.Parent = model

	-- Store data
	model:SetAttribute("Symbol", stockDef.symbol)
	model:SetAttribute("Name", stockDef.name)
	model:SetAttribute("Collected", false)

	-- Setup detection
	setupDetection(detection, model)

	return model
end

local function spawnStocks()
	local ws = game:GetService("Workspace")

	-- Remove old stocks
	for _, child in ipairs(ws:GetChildren()) do
		if child.Name:match("^Stock_") then
			child:Destroy()
		end
	end

	-- Spawn
	for i, stockDef in ipairs(STOCK_DEFS) do
		if i <= #SPAWN_POINTS then
			local model = createStockItem(stockDef, SPAWN_POINTS[i])
			model.Parent = ws
		end
	end

	print("[StockSpawner] Spawned", #STOCK_DEFS, "stock collectibles")
end

-- Player setup
local function onPlayerAdded(player)
	collectedStocks[player.UserId] = {}
end

local function onPlayerRemoving(player)
	collectedStocks[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle already-connected players
for _, player in ipairs(Players:GetPlayers()) do
	if not collectedStocks[player.UserId] then
		collectedStocks[player.UserId] = {}
	end
end

spawnStocks()
print("[StockSpawner] Initialized")
