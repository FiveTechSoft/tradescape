-- NatureBuilder.server.lua — Trees, plants, birds for the city
-- Place in: ServerScriptService/NatureBuilder (Script)

local RunService = game:GetService("RunService")

local birds = {}

-- ============================================================
-- Trees along streets and in parks
-- ============================================================
local function buildTrees(ws)
	local treeCount = 0

	-- Trees along sidewalks
	for x = -800, 800, 240 do
		for _, z in ipairs({-130, -110, 110, 130}) do
			if math.random() > 0.4 then
				local pos = Vector3.new(x + math.random(-10, 10), 0, z)
				CityBuilder_createTree(ws, pos)
				treeCount = treeCount + 1
			end
		end
	end

	-- Park trees
	for i = 1, 20 do
		local pos = Vector3.new(-240 + math.random(0, 80), 0, 680 + math.random(0, 60))
		CityBuilder_createTree(ws, pos)
		treeCount = treeCount + 1
	end

	-- Random trees in empty areas
	for i = 1, 50 do
		local x = math.random(-800, 800)
		local z = math.random(-800, 800)
		local pos = Vector3.new(x, 0, z)
		CityBuilder_createTree(ws, pos)
		treeCount = treeCount + 1
	end

	print("[NatureBuilder] Trees:", treeCount)
end

function CityBuilder_createTree(ws, pos)
	-- Trunk
	local trunkH = math.random(5, 10)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Anchored = true
	trunk.Size = Vector3.new(1.2, trunkH, 1.2)
	trunk.Position = pos + Vector3.new(0, trunkH / 2, 0)
	trunk.Color = Color3.fromRGB(85, 55, 30)
	trunk.Material = Enum.Material.Wood
	trunk.Parent = ws

	-- Leaves (sphere)
	local leavesR = math.random(3, 6)
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Anchored = true
	leaves.Size = Vector3.new(leavesR * 2, leavesR * 2, leavesR * 2)
	leaves.Position = pos + Vector3.new(0, trunkH + leavesR * 0.6, 0)
	leaves.Color = Color3.fromRGB(25 + math.random(0, 30), 90 + math.random(0, 50), 20)
	leaves.Material = Enum.Material.Grass
	leaves.Shape = Enum.PartType.Ball
	leaves.Parent = ws
end

-- ============================================================
-- Bushes and plants
-- ============================================================
local function buildPlants(ws)
	local plantCount = 0

	-- Bushes along sidewalks
	for x = -800, 800, 60 do
		for _, z in ipairs({-115, -105, 105, 115}) do
			if math.random() > 0.6 then
				local bush = Instance.new("Part")
				bush.Name = "Bush"
				bush.Anchored = true
				local s = math.random(2, 4)
				bush.Size = Vector3.new(s, s * 0.6, s)
				bush.Position = Vector3.new(x, s * 0.3, z)
				bush.Color = Color3.fromRGB(30 + math.random(0, 20), 80 + math.random(0, 40), 25)
				bush.Material = Enum.Material.Grass
				bush.Shape = Enum.PartType.Ball
				bush.Parent = ws
				plantCount = plantCount + 1
			end
		end
	end

	-- Flowers in park
	for i = 1, 30 do
		local fx = -240 + math.random(0, 80)
		local fz = 680 + math.random(0, 60)
		local flower = Instance.new("Part")
		flower.Name = "Flower"
		flower.Anchored = true
		flower.Size = Vector3.new(0.8, 0.8, 0.8)
		flower.Position = Vector3.new(fx, 0.4, fz)
		flower.Shape = Enum.PartType.Ball
		flower.Material = Enum.Material.Neon

		local flowerColors = {
			Color3.fromRGB(255, 100, 100),
			Color3.fromRGB(255, 200, 50),
			Color3.fromRGB(200, 100, 255),
			Color3.fromRGB(255, 150, 200),
			Color3.fromRGB(100, 200, 255),
		}
		flower.Color = flowerColors[math.random(#flowerColors)]
		flower.CanCollide = false
		flower.Parent = ws
		plantCount = plantCount + 1
	end

	-- Grass patches
	for i = 1, 40 do
		local gx = math.random(-800, 800)
		local gz = math.random(-800, 800)
		local patch = Instance.new("Part")
		patch.Name = "GrassPatch"
		patch.Anchored = true
		patch.Size = Vector3.new(math.random(4, 12), 0.1, math.random(4, 12))
		patch.Position = Vector3.new(gx, 0.05, gz)
		patch.Color = Color3.fromRGB(40 + math.random(0, 20), 100 + math.random(0, 30), 35)
		patch.Material = Enum.Material.Grass
		patch.TopSurface = Enum.SurfaceType.Smooth
		patch.CanCollide = false
		patch.Parent = ws
		plantCount = plantCount + 1
	end

	print("[NatureBuilder] Plants:", plantCount)
end

-- ============================================================
-- Flying birds
-- ============================================================
local function createBird(ws)
	local model = Instance.new("Model")
	model.Name = "Bird"

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(0.8, 0.4, 1.5)
	body.Color = Color3.fromRGB(50, 50, 55)
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.Anchored = true
	body.Parent = model

	-- Wings
	for _, side in ipairs({-1, 1}) do
		local wing = Instance.new("Part")
		wing.Name = "Wing"
		wing.Size = Vector3.new(2, 0.1, 0.8)
		wing.Color = Color3.fromRGB(60, 60, 65)
		wing.Material = Enum.Material.SmoothPlastic
		wing.CanCollide = false
		wing.Anchored = true
		wing.Parent = model
	end

	-- Beak
	local beak = Instance.new("Part")
	beak.Name = "Beak"
	beak.Size = Vector3.new(0.2, 0.2, 0.5)
	beak.Color = Color3.fromRGB(255, 180, 0)
	beak.Material = Enum.Material.SmoothPlastic
	beak.CanCollide = false
	beak.Anchored = true
	beak.Parent = model

	model.Parent = ws
	return model
end

local function spawnBirds(ws)
	local birdCount = 12

	for i = 1, birdCount do
		local bird = createBird(ws)
		local startX = math.random(-400, 400)
		local startZ = math.random(-400, 400)
		local height = math.random(60, 120)

		table.insert(birds, {
			model = bird,
			centerX = startX,
			centerZ = startZ,
			height = height,
			angle = math.random() * math.pi * 2,
			speed = 0.3 + math.random() * 0.5,
			radius = 30 + math.random(0, 40),
			wingAngle = 0,
		})
	end

	print("[NatureBuilder] Birds:", birdCount)
end

-- Animate birds
RunService.Heartbeat:Connect(function(dt)
	for _, bird in ipairs(birds) do
		bird.angle = bird.angle + bird.speed * dt
		bird.wingAngle = bird.wingAngle + dt * 8

		local x = bird.centerX + math.cos(bird.angle) * bird.radius
		local z = bird.centerZ + math.sin(bird.angle) * bird.radius
		local y = bird.height + math.sin(bird.wingAngle) * 2

		local body = bird.model:FindFirstChild("Body")
		if body then
			body.Position = Vector3.new(x, y, z)
			body.Orientation = Vector3.new(0, math.deg(bird.angle) + 90, 0)
		end

		local wings = bird.model:GetChildren()
		local leftWing = bird.model:FindFirstChild("Wing")
		if leftWing then
			local wingFlap = math.sin(bird.wingAngle) * 30
			leftWing.Position = Vector3.new(x - 1, y + 0.3, z)
			leftWing.Orientation = Vector3.new(wingFlap, math.deg(bird.angle) + 90, 0)
		end

		-- Find second wing by index
		for _, child in ipairs(wings) do
			if child.Name == "Wing" and child ~= leftWing then
				local wingFlap = math.sin(bird.wingAngle) * 30
				child.Position = Vector3.new(x + 1, y + 0.3, z)
				child.Orientation = Vector3.new(-wingFlap, math.deg(bird.angle) + 90, 0)
				break
			end
		end

		local beak = bird.model:FindFirstChild("Beak")
		if beak then
			beak.Position = Vector3.new(x, y, z + 0.9)
		end
	end
end)

-- ============================================================
-- Ambient sounds (wind chimes feel)
-- ============================================================
local function addStreetDetails(ws)
	-- Trash cans
	for x = -600, 600, 240 do
		for _, z in ipairs({-105, 105}) do
			if math.random() > 0.5 then
				local trash = Instance.new("Part")
				trash.Name = "TrashCan"
				trash.Anchored = true
				trash.Size = Vector3.new(1.5, 2, 1.5)
				trash.Position = Vector3.new(x, 1, z)
				trash.Color = Color3.fromRGB(80, 80, 85)
				trash.Material = Enum.Material.Metal
				trash.Parent = ws
			end
		end
	end

	-- Benches
	for x = -600, 600, 300 do
		for _, z in ipairs({-112, 112}) do
			if math.random() > 0.4 then
				local bench = Instance.new("Part")
				bench.Name = "Bench"
				bench.Anchored = true
				bench.Size = Vector3.new(4, 1, 1.5)
				bench.Position = Vector3.new(x, 0.5, z)
				bench.Color = Color3.fromRGB(120, 80, 40)
				bench.Material = Enum.Material.Wood
				bench.Parent = ws
			end
		end
	end
end

-- ============================================================
-- Run
-- ============================================================
buildTrees(workspace)
buildPlants(workspace)
spawnBirds(workspace)
addStreetDetails(workspace)

print("[NatureBuilder] Initialized")
