-- EnemySpawner.server.lua — Patrolling enemies on rooftops
-- Place in: ServerScriptService/EnemySpawner (Script)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ENEMY_SPEED = 16
local PATROL_RANGE = 40
local DETECTION_RANGE = 20
local CHASE_SPEED = 24

local activeEnemies = {}

local function createEnemy(position, buildingName)
	local model = Instance.new("Model")
	model.Name = "Enemy"

	-- Body
	local body = Instance.new("Part")
	body.Name = "HumanoidRootPart"
	body.Size = Vector3.new(2, 5, 2)
	body.Position = position + Vector3.new(0, 3, 0)
	body.Color = Color3.fromRGB(180, 40, 40)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = false
	body.CanCollide = true
	body.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Shape = Enum.PartType.Ball
	head.Position = body.Position + Vector3.new(0, 3.5, 0)
	head.Color = Color3.fromRGB(200, 60, 60)
	head.Material = Enum.Material.Neon
	head.Parent = model

	-- Eyes (glowing)
	for _, xOff in ipairs({-0.4, 0.4}) do
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.4, 0.4, 0.2)
		eye.Position = head.Position + Vector3.new(xOff, 0.2, 0.8)
		eye.Color = Color3.fromRGB(255, 255, 0)
		eye.Material = Enum.Material.Neon
		eye.CanCollide = false
		eye.Parent = model
	end

	-- Billboard warning
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 80, 0, 20)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local warn = Instance.new("TextLabel")
	warn.Size = UDim2.new(1, 0, 1, 0)
	warn.BackgroundTransparency = 1
	warn.Text = "PATROL"
	warn.TextColor3 = Color3.fromRGB(255, 80, 80)
	warn.TextStrokeTransparency = 0.3
	warn.TextSize = 14
	warn.Font = Enum.Font.GothamBold
	warn.Parent = bb

	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = 100
	hum.Health = 100
	hum.WalkSpeed = ENEMY_SPEED
	hum.Parent = model

	model.PrimaryPart = body
	model.Parent = workspace

	-- Patrol state
	local enemyData = {
		model = model,
		humanoid = hum,
		origin = position,
		state = "patrol", -- patrol, chase, return
		target = nil,
		patrolTarget = position + Vector3.new(math.random(-PATROL_RANGE, PATROL_RANGE), 0, math.random(-PATROL_RANGE, PATROL_RANGE)),
	}

	table.insert(activeEnemies, enemyData)
	return enemyData
end

local function findRooftopPositions()
	local positions = {}
	local seen = {}

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Floor" and obj:IsA("Part") and obj.Size.Y <= 1.5 then
			-- This is likely a roof (top floor)
			local key = math.floor(obj.Position.X / 20) .. "_" .. math.floor(obj.Position.Z / 20)
			if not seen[key] then
				seen[key] = true
				-- Place enemy on top of this floor
				local pos = obj.Position + Vector3.new(
					math.random(-5, 5),
					obj.Size.Y / 2 + 3,
					math.random(-5, 5)
				)
				table.insert(positions, pos)
			end
		end
	end

	return positions
end

local function spawnEnemies()
	local positions = findRooftopPositions()
	local maxEnemies = math.min(#positions, 30)

	-- Shuffle positions
	for i = #positions, 2, -1 do
		local j = math.random(i)
		positions[i], positions[j] = positions[j], positions[i]
	end

	for i = 1, maxEnemies do
		createEnemy(positions[i], "Building")
	end

	print("[EnemySpawner] Spawned", maxEnemies, "enemies")
end

-- AI loop
RunService.Heartbeat:Connect(function(dt)
	for _, enemy in ipairs(activeEnemies) do
		if not enemy.model or not enemy.model.Parent then continue end
		local hrp = enemy.model:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		-- Find nearest player
		local nearestPlayer = nil
		local nearestDist = DETECTION_RANGE
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestPlayer = player
				end
			end
		end

		if nearestPlayer and enemy.state ~= "chase" then
			enemy.state = "chase"
			enemy.humanoid.WalkSpeed = CHASE_SPEED
			local warnLabel = enemy.model.Head:FindFirstChildOfClass("BillboardGui"):FindFirstChildOfClass("TextLabel")
			if warnLabel then warnLabel.Text = "CHASE!" end
		end

		if enemy.state == "chase" then
			if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
				enemy.humanoid:MoveTo(nearestPlayer.Character.HumanoidRootPart.Position)
			else
				enemy.state = "return"
				enemy.humanoid.WalkSpeed = ENEMY_SPEED
				local warnLabel = enemy.model.Head:FindFirstChildOfClass("BillboardGui"):FindFirstChildOfClass("TextLabel")
				if warnLabel then warnLabel.Text = "PATROL" end
			end
		elseif enemy.state == "patrol" then
			-- Move to patrol target
			local distToTarget = (hrp.Position - enemy.patrolTarget).Magnitude
			if distToTarget < 5 then
				-- New random target near origin
				enemy.patrolTarget = enemy.origin + Vector3.new(
					math.random(-PATROL_RANGE, PATROL_RANGE),
					0,
					math.random(-PATROL_RANGE, PATROL_RANGE)
				)
			end
			enemy.humanoid:MoveTo(enemy.patrolTarget)
		end
	end
end)

-- Spawn on start
spawnEnemies()

print("[EnemySpawner] Initialized")
