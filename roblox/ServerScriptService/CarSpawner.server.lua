-- CarSpawner.server.lua — Drivable cars on streets
-- Place in: ServerScriptService/CarSpawner (Script)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CAR_SPEED_MIN = 30
local CAR_SPEED_MAX = 60

local activeCars = {}
local carOccupants = {} -- [player] = carData

local CAR_COLORS = {
	Color3.fromRGB(200, 30, 30), Color3.fromRGB(30, 30, 200),
	Color3.fromRGB(50, 180, 50), Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(30, 30, 30), Color3.fromRGB(200, 200, 50),
	Color3.fromRGB(200, 100, 50), Color3.fromRGB(100, 50, 150),
	Color3.fromRGB(180, 180, 180), Color3.fromRGB(50, 150, 180),
}

-- RemoteEvents
local EnterCar = Instance.new("RemoteEvent")
EnterCar.Name = "EnterCar"
EnterCar.Parent = ReplicatedStorage

local ExitCar = Instance.new("RemoteEvent")
ExitCar.Name = "ExitCar"
ExitCar.Parent = ReplicatedStorage

local CarControl = Instance.new("RemoteEvent")
CarControl.Name = "CarControl"
CarControl.Parent = ReplicatedStorage

local function createCar(startPos, direction)
	local model = Instance.new("Model")
	model.Name = "DrivableCar"

	local color = CAR_COLORS[math.random(#CAR_COLORS)]

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(5, 1.5, 9)
	body.Position = startPos
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.TopSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	-- Roof
	local roof = Instance.new("Part")
	roof.Size = Vector3.new(4.2, 1, 4)
	roof.Position = startPos + Vector3.new(0, 1.25, -0.5)
	roof.Color = color
	roof.Material = Enum.Material.SmoothPlastic
	roof.Anchored = true
	roof.CanCollide = false
	roof.Parent = model

	-- Windshield
	local ws = Instance.new("Part")
	ws.Size = Vector3.new(4, 1, 0.2)
	ws.Position = startPos + Vector3.new(0, 1, 1.5)
	ws.Color = Color3.fromRGB(150, 200, 255)
	ws.Material = Enum.Material.Glass
	ws.Transparency = 0.5
	ws.Anchored = true
	ws.CanCollide = false
	ws.Parent = model

	-- Rear window
	local rw = Instance.new("Part")
	rw.Size = Vector3.new(4, 1, 0.2)
	rw.Position = startPos + Vector3.new(0, 1, -2.5)
	rw.Color = Color3.fromRGB(150, 200, 255)
	rw.Material = Enum.Material.Glass
	rw.Transparency = 0.5
	rw.Anchored = true
	rw.CanCollide = false
	rw.Parent = model

	-- Headlights
	for _, xOff in ipairs({-1.8, 1.8}) do
		local hl = Instance.new("Part")
		hl.Size = Vector3.new(0.6, 0.4, 0.3)
		hl.Position = startPos + Vector3.new(xOff, -0.2, 4.6)
		hl.Color = Color3.fromRGB(255, 255, 200)
		hl.Material = Enum.Material.Neon
		hl.Anchored = true
		hl.CanCollide = false
		hl.Parent = model
		local light = Instance.new("PointLight")
		light.Brightness = 1
		light.Range = 15
		light.Color = Color3.fromRGB(255, 255, 200)
		light.Parent = hl
	end

	-- Taillights
	for _, xOff in ipairs({-1.8, 1.8}) do
		local tl = Instance.new("Part")
		tl.Size = Vector3.new(0.6, 0.4, 0.3)
		tl.Position = startPos + Vector3.new(xOff, -0.2, -4.6)
		tl.Color = Color3.fromRGB(255, 20, 20)
		tl.Material = Enum.Material.Neon
		tl.Anchored = true
		tl.CanCollide = false
		tl.Parent = model
	end

	-- Wheels
	for _, wPos in ipairs({{-2.5, -0.8, 3}, {2.5, -0.8, 3}, {-2.5, -0.8, -3}, {2.5, -0.8, -3}}) do
		local w = Instance.new("Part")
		w.Size = Vector3.new(0.5, 1.2, 1.2)
		w.Position = startPos + Vector3.new(wPos[1], wPos[2], wPos[3])
		w.Color = Color3.fromRGB(30, 30, 30)
		w.Material = Enum.Material.SmoothPlastic
		w.Shape = Enum.PartType.Cylinder
		w.Orientation = Vector3.new(0, 0, 90)
		w.Anchored = true
		w.CanCollide = false
		w.Parent = model
	end

	-- Seat (ScriptSeat for vehicle behavior)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(4, 0.5, 4)
	seat.Position = startPos + Vector3.new(0, 0.5, 0.5)
	seat.Color = Color3.fromRGB(40, 40, 45)
	seat.Material = Enum.Material.Fabric
	seat.Anchored = true
	seat.CanCollide = false
	seat.MaxSpeed = 0
	seat.TurnSpeed = 0
	seat.Parent = model

	-- "Press E" billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "Prompt"
	bb.Size = UDim2.new(0, 120, 0, 30)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body

	local prompt = Instance.new("TextLabel")
	prompt.Size = UDim2.new(1, 0, 1, 0)
	prompt.BackgroundTransparency = 1
	prompt.Text = "[E] Drive"
	prompt.TextColor3 = Color3.fromRGB(255, 255, 100)
	prompt.TextStrokeTransparency = 0.3
	prompt.TextSize = 16
	prompt.Font = Enum.Font.GothamBold
	prompt.Parent = bb

	model.Parent = workspace

	local carData = {
		model = model,
		body = body,
		seat = seat,
		speed = 0,
		maxSpeed = math.random(CAR_SPEED_MIN, CAR_SPEED_MAX),
		steerSpeed = 80,
		acceleration = 40,
		brakeForce = 60,
		drag = 0.98,
		heading = direction == 1 and 0 or 180,
		occupied = false,
		occupant = nil,
	}

	-- SeatOccupant change
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant then
			local occupantPlayer = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
			if occupantPlayer then
				carData.occupied = true
				carData.occupant = occupantPlayer
				carOccupants[occupantPlayer] = carData
				-- Hide prompt
				bb.Enabled = false
			end
		else
			carData.occupied = false
			carOccupants[carData.occupant] = nil
			carData.occupant = nil
			bb.Enabled = true
		end
	end)

	return carData
end

local function moveCarParts(car, dt)
	local pos = car.body.Position
	local rad = math.rad(car.heading)
	local forward = Vector3.new(math.sin(rad), 0, math.cos(rad))

	-- Move body
	car.body.Position = pos + forward * car.speed * dt

	-- Move all child parts relative to body
	for _, child in ipairs(car.model:GetChildren()) do
		if child ~= car.body and child:IsA("Part") then
			child.Position = car.body.Position + (child.Position - pos)
		end
	end
end

local function spawnCars()
	-- East-West cars
	for _, z in ipairs({-840, -720, -600, -480, -360, -240, -120, 0, 120, 240, 360, 480, 600, 720}) do
		for _, lane in ipairs({-3, 3}) do
			if math.random() > 0.3 then
				local startX = math.random(-900, 900)
				local dir = lane > 0 and 1 or -1
				local car = createCar(Vector3.new(startX, 1.5, z + lane), dir)
				car.heading = dir == 1 and 90 or 270
				table.insert(activeCars, car)
			end
		end
	end

	-- North-South cars
	for _, x in ipairs({-840, -720, -600, -480, -360, -240, -120, 0, 120, 240, 360, 480, 600, 720}) do
		for _, lane in ipairs({-3, 3}) do
			if math.random() > 0.3 then
				local startZ = math.random(-900, 900)
				local dir = lane > 0 and 1 or -1
				local car = createCar(Vector3.new(x + lane, 1.5, startZ), dir)
				car.heading = dir == 1 and 0 or 180
				-- Rotate car model
				car.body.Orientation = Vector3.new(0, car.heading, 0)
				for _, child in ipairs(car.model:GetChildren()) do
					if child ~= car.body and child:IsA("Part") then
						child.Orientation = Vector3.new(child.Orientation.X, car.heading, child.Orientation.Z)
					end
				end
				table.insert(activeCars, car)
			end
		end
	end

	print("[CarSpawner] Spawned", #activeCars, "cars")
end

-- ============================================================
-- Player enters car
-- ============================================================
EnterCar.OnServerEvent:Connect(function(player)
	if carOccupants[player] then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local hrpPos = character.HumanoidRootPart.Position

	-- Find nearest car
	local nearestCar = nil
	local nearestDist = 12

	for _, car in ipairs(activeCars) do
		if not car.occupied then
			local dist = (car.body.Position - hrpPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestCar = car
			end
		end
	end

	if nearestCar then
		-- Teleport player to seat
		character.HumanoidRootPart.CFrame = nearestCar.seat.CFrame + Vector3.new(0, 2, 0)
		task.wait(0.2)
		nearestCar.seat.Occupant = character.Humanoid
	end
end)

-- ============================================================
-- Player exits car
-- ============================================================
ExitCar.OnServerEvent:Connect(function(player)
	local car = carOccupants[player]
	if not car then return end

	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- Teleport player next to car
		local exitPos = car.body.Position + Vector3.new(4, 2, 0)
		character.HumanoidRootPart.CFrame = CFrame.new(exitPos)
	end

	car.seat.Occupant = nil
	car.speed = 0
end)

-- ============================================================
-- Car control from client
-- ============================================================
CarControl.OnServerEvent:Connect(function(player, action, value)
	local car = carOccupants[player]
	if not car then return end

	if action == "accelerate" then
		car.speed = math.min(car.speed + car.acceleration * value, car.maxSpeed)
	elseif action == "brake" then
		car.speed = math.max(car.speed - car.brakeForce * value, -car.maxSpeed * 0.3)
	elseif action == "steer" then
		car.heading = car.heading + car.steerSpeed * value
		-- Update visual rotation
		car.body.Orientation = Vector3.new(0, car.heading, 0)
		for _, child in ipairs(car.model:GetChildren()) do
			if child ~= car.body and child:IsA("Part") and child.Name ~= "Seat" then
				child.Orientation = Vector3.new(child.Orientation.X, car.heading, child.Orientation.Z)
			end
		end
	elseif action == "stop" then
		car.speed = 0
	end
end)

-- ============================================================
-- Physics loop
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
	for _, car in ipairs(activeCars) do
		if car.occupied then
			-- Controlled car — apply drag
			car.speed = car.speed * car.drag
			if math.abs(car.speed) < 0.5 then car.speed = 0 end
		else
			-- AI car — cruise
			if car.speed == 0 then
				car.speed = car.maxSpeed * 0.7
			end
		end

		if car.speed ~= 0 then
			moveCarParts(car, dt)

			-- Wrap around city
			local pos = car.body.Position
			if pos.X > 1000 then car.body.Position = pos - Vector3.new(2000, 0, 0) end
			if pos.X < -1000 then car.body.Position = pos + Vector3.new(2000, 0, 0) end
			if pos.Z > 1000 then car.body.Position = pos - Vector3.new(0, 0, 2000) end
			if pos.Z < -1000 then car.body.Position = pos + Vector3.new(0, 0, 2000) end
		end
	end
end)

spawnCars()
print("[CarSpawner] Initialized")
