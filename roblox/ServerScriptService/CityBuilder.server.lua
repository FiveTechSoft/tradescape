-- CityBuilder.server.lua — Massive labyrinth city with explorable buildings
-- Place in: ServerScriptService/CityBuilder (Script)

local CityBuilder = {}

function CityBuilder.build()
	local ws = game:GetService("Workspace")

	local oldBP = ws:FindFirstChild("Baseplate")
	if oldBP then oldBP:Destroy() end

	-- Ground
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(2000, 1, 2000)
	ground.Position = Vector3.new(0, -0.5, 0)
	ground.Color = Color3.fromRGB(50, 50, 55)
	ground.Material = Enum.Material.Concrete
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = ws

	-- Beach + Water
	local beach = Instance.new("Part")
	beach.Anchored = true
	beach.Size = Vector3.new(2000, 1.5, 150)
	beach.Position = Vector3.new(0, -0.2, 900)
	beach.Color = Color3.fromRGB(210, 190, 140)
	beach.Material = Enum.Material.Sand
	beach.TopSurface = Enum.SurfaceType.Smooth
	beach.Parent = ws

	local water = Instance.new("Part")
	water.Anchored = true
	water.Size = Vector3.new(2400, 1, 250)
	water.Position = Vector3.new(0, -1, 1050)
	water.Color = Color3.fromRGB(30, 100, 180)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.3
	water.TopSurface = Enum.SurfaceType.Smooth
	water.Parent = ws

	-- Streets
	for z = -800, 800, 120 do
		local s = Instance.new("Part")
		s.Anchored = true
		s.Size = Vector3.new(2000, 0.1, 16)
		s.Position = Vector3.new(0, 0.02, z)
		s.Color = Color3.fromRGB(35, 35, 40)
		s.Material = Enum.Material.Asphalt
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = ws

		local line = Instance.new("Part")
		line.Anchored = true
		line.Size = Vector3.new(2000, 0.15, 0.4)
		line.Position = Vector3.new(0, 0.08, z)
		line.Color = Color3.fromRGB(200, 200, 80)
		line.Material = Enum.Material.Neon
		line.Parent = ws
	end

	for x = -800, 800, 120 do
		local s = Instance.new("Part")
		s.Anchored = true
		s.Size = Vector3.new(16, 0.1, 2000)
		s.Position = Vector3.new(x, 0.02, 0)
		s.Color = Color3.fromRGB(35, 35, 40)
		s.Material = Enum.Material.Asphalt
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = ws
	end

	-- Sidewalks
	for z = -800, 800, 120 do
		for _, side in ipairs({-10, 10}) do
			local sw = Instance.new("Part")
			sw.Anchored = true
			sw.Size = Vector3.new(2000, 0.15, 4)
			sw.Position = Vector3.new(0, 0.06, z + side)
			sw.Color = Color3.fromRGB(125, 125, 130)
			sw.Material = Enum.Material.Concrete
			sw.TopSurface = Enum.SurfaceType.Smooth
			sw.Parent = ws
		end
	end

	-- Buildings with interiors
	local buildingCount = 0
	local blockSpacing = 120

	for bx = -6, 6 do
		for bz = -6, 6 do
			local blockX = bx * blockSpacing
			local blockZ = bz * blockSpacing

			-- 3-5 buildings per block
			local numBuildings = math.random(3, 5)
			for b = 1, numBuildings do
				local offsetX = (b - 1) * 22 - (numBuildings * 11)
				local offsetZ = math.random(-25, 25)

				local distFromCenter = math.sqrt(blockX * blockX + blockZ * blockZ)
				local height = distFromCenter < 300 and math.random(25, 60) or math.random(10, 30)
				local width = math.random(18, 32)
				local depth = math.random(18, 32)

				-- Building sits on ground (center.y = height/2 so bottom is at y=0)
				local pos = Vector3.new(blockX + offsetX, height / 2, blockZ + offsetZ)

				CityBuilder.createExplorableBuilding(ws, pos, width, height, depth)
				buildingCount = buildingCount + 1
			end
		end
	end

	-- Catwalks between nearby buildings
	CityBuilder.buildCatwalks(ws)

	-- Park
	local park = Instance.new("Part")
	park.Anchored = true
	park.Size = Vector3.new(80, 0.2, 60)
	park.Position = Vector3.new(-200, 0.1, 700)
	park.Color = Color3.fromRGB(45, 115, 40)
	park.Material = Enum.Material.Grass
	park.TopSurface = Enum.SurfaceType.Smooth
	park.Parent = ws

	for i = 1, 15 do
		local tx = -240 + math.random(0, 80)
		local tz = 680 + math.random(0, 60)
		local trunk = Instance.new("Part")
		trunk.Anchored = true
		trunk.Size = Vector3.new(1.2, 6, 1.2)
		trunk.Position = Vector3.new(tx, 3, tz)
		trunk.Color = Color3.fromRGB(85, 55, 30)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = ws
		local leaves = Instance.new("Part")
		leaves.Anchored = true
		leaves.Size = Vector3.new(6, 6, 6)
		leaves.Position = Vector3.new(tx, 7, tz)
		leaves.Color = Color3.fromRGB(30 + math.random(0, 25), 100 + math.random(0, 40), 25)
		leaves.Material = Enum.Material.Grass
		leaves.Shape = Enum.PartType.Ball
		leaves.Parent = ws
	end

	-- Lampposts
	for x = -800, 800, 120 do
		for _, z in ipairs({-120, 120}) do
			local pole = Instance.new("Part")
			pole.Anchored = true
			pole.Size = Vector3.new(0.3, 8, 0.3)
			pole.Position = Vector3.new(x, 4, z - 10)
			pole.Color = Color3.fromRGB(75, 75, 80)
			pole.Material = Enum.Material.Metal
			pole.Parent = ws
			local lamp = Instance.new("Part")
			lamp.Anchored = true
			lamp.Size = Vector3.new(1.5, 1, 1.5)
			lamp.Position = Vector3.new(x, 8.5, z - 10)
			lamp.Color = Color3.fromRGB(255, 240, 180)
			lamp.Material = Enum.Material.Neon
			lamp.Shape = Enum.PartType.Ball
			lamp.Parent = ws
			local pl = Instance.new("PointLight")
			pl.Brightness = 1.5
			pl.Range = 25
			pl.Color = Color3.fromRGB(255, 240, 180)
			pl.Parent = lamp
		end
	end

	-- Spawn
	local spawn = ws:FindFirstChild("SpawnLocation")
	if spawn then spawn.Position = Vector3.new(0, 0.5, 0) end

	print("[CityBuilder] Labyrinth city built:", buildingCount, "buildings")
end

function CityBuilder.createExplorableBuilding(ws, center, width, height, depth)
	local colors = {
		Color3.fromRGB(75, 80, 90), Color3.fromRGB(85, 75, 70),
		Color3.fromRGB(70, 75, 85), Color3.fromRGB(90, 85, 80),
	}
	local wallColor = colors[math.random(#colors)]
	local floorColor = Color3.fromRGB(90, 90, 95)

	local wallThick = 2
	local floorThick = 1.5
	local floorH = 6
	local numFloors = math.max(1, math.floor(height / floorH))
	local doorW = 4
	local doorH = 5

	-- Ground floor at y=0, building goes UP from there
	local groundY = 0.75

	-- Floors: ground at 0.75, then every floorH above
	for f = 0, numFloors do
		local yPos = groundY + f * floorH
		local fl = Instance.new("Part")
		fl.Name = "Floor"
		fl.Anchored = true
		fl.Size = Vector3.new(width, floorThick, depth)
		fl.Position = Vector3.new(center.X, yPos, center.Z)
		fl.Color = floorColor
		fl.Material = Enum.Material.Concrete
		fl.TopSurface = Enum.SurfaceType.Smooth
		fl.BottomSurface = Enum.SurfaceType.Smooth
		fl.Parent = ws
	end

	-- Walls (4 sides, from ground up)
	local halfW = width / 2
	local halfD = depth / 2

	-- Front wall (z+)
	local fw = Instance.new("Part")
	fw.Anchored = true
	fw.Size = Vector3.new(width, height, wallThick)
	fw.Position = Vector3.new(center.X, height / 2, center.Z + halfD)
	fw.Color = wallColor
	fw.Material = Enum.Material.SmoothPlastic
	fw.TopSurface = Enum.SurfaceType.Smooth
	fw.Parent = ws

	-- Back wall (z-)
	local bw = Instance.new("Part")
	bw.Anchored = true
	bw.Size = Vector3.new(width, height, wallThick)
	bw.Position = Vector3.new(center.X, height / 2, center.Z - halfD)
	bw.Color = wallColor
	bw.Material = Enum.Material.SmoothPlastic
	bw.TopSurface = Enum.SurfaceType.Smooth
	bw.Parent = ws

	-- Left wall (x-)
	local lw = Instance.new("Part")
	lw.Anchored = true
	lw.Size = Vector3.new(wallThick, height, depth)
	lw.Position = Vector3.new(center.X - halfW, height / 2, center.Z)
	lw.Color = wallColor
	lw.Material = Enum.Material.SmoothPlastic
	lw.TopSurface = Enum.SurfaceType.Smooth
	lw.Parent = ws

	-- Right wall (x+)
	local rw = Instance.new("Part")
	rw.Anchored = true
	rw.Size = Vector3.new(wallThick, height, depth)
	rw.Position = Vector3.new(center.X + halfW, height / 2, center.Z)
	rw.Color = wallColor
	rw.Material = Enum.Material.SmoothPlastic
	rw.TopSurface = Enum.SurfaceType.Smooth
	rw.Parent = ws

	-- Door openings (as transparent cutout on front wall)
	local doorFrame = Instance.new("Part")
	doorFrame.Anchored = true
	doorFrame.Size = Vector3.new(doorW, doorH, wallThick + 1)
	doorFrame.Position = Vector3.new(center.X, doorH / 2, center.Z + halfD)
	doorFrame.Color = Color3.fromRGB(50, 35, 20)
	doorFrame.Material = Enum.Material.Wood
	doorFrame.Transparency = 0.9
	doorFrame.CanCollide = false
	doorFrame.Parent = ws

	-- Door on back wall
	local doorFrame2 = Instance.new("Part")
	doorFrame2.Anchored = true
	doorFrame2.Size = Vector3.new(doorW, doorH, wallThick + 1)
	doorFrame2.Position = Vector3.new(center.X, doorH / 2, center.Z - halfD)
	doorFrame2.Color = Color3.fromRGB(50, 35, 20)
	doorFrame2.Material = Enum.Material.Wood
	doorFrame2.Transparency = 0.9
	doorFrame2.CanCollide = false
	doorFrame2.Parent = ws

	-- Windows on side walls
	for row = 1, math.min(numFloors, 6) do
		for col = 1, 3 do
			-- Left wall windows
			local wl = Instance.new("Part")
			wl.Anchored = true
			wl.Size = Vector3.new(0.4, 3, 2.5)
			wl.Position = Vector3.new(center.X - halfW, groundY + row * floorH - 1, center.Z - col * 5 + depth / 2 - 2)
			wl.Color = math.random() > 0.35 and Color3.fromRGB(255, 240, 180) or Color3.fromRGB(40, 50, 60)
			wl.Material = wl.Color.R > 0.9 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			wl.Parent = ws

			-- Right wall windows
			local wr = Instance.new("Part")
			wr.Anchored = true
			wr.Size = Vector3.new(0.4, 3, 2.5)
			wr.Position = Vector3.new(center.X + halfW, groundY + row * floorH - 1, center.Z - col * 5 + depth / 2 - 2)
			wr.Color = wl.Color
			wr.Material = wl.Material
			wr.Parent = ws
		end
	end

	-- Interior: desk, chair, shelf
	local desk = Instance.new("Part")
	desk.Anchored = true
	desk.Size = Vector3.new(4, 0.5, 2)
	desk.Position = Vector3.new(center.X + 3, groundY + 1.5, center.Z)
	desk.Color = Color3.fromRGB(100, 65, 35)
	desk.Material = Enum.Material.Wood
	desk.Parent = ws

	local chair = Instance.new("Part")
	chair.Anchored = true
	chair.Size = Vector3.new(1.5, 0.3, 1.5)
	chair.Position = Vector3.new(center.X + 3, groundY + 1.3, center.Z + 3)
	chair.Color = Color3.fromRGB(60, 60, 65)
	chair.Material = Enum.Material.SmoothPlastic
	chair.Parent = ws

	-- Stairs (walkable: small steps, 1 stud tall each)
	for f = 1, numFloors do
		local baseY = groundY + (f - 1) * floorH
		for step = 1, 5 do
			local s = Instance.new("Part")
			s.Anchored = true
			s.Size = Vector3.new(3, 1, 1.5)
			s.Position = Vector3.new(
				center.X - halfW + 4 + (step - 1) * 1.5,
				baseY + (step - 1) * 1 + 0.5,
				center.Z - halfD + 4
			)
			s.Color = Color3.fromRGB(100, 100, 105)
			s.Material = Enum.Material.Metal
			s.TopSurface = Enum.SurfaceType.Smooth
			s.Parent = ws
		end
	end

	-- Interior lights
	for f = 0, numFloors do
		local ly = groundY + f * floorH + 4
		local lp = Instance.new("Part")
		lp.Anchored = true
		lp.Size = Vector3.new(1, 0.3, 1)
		lp.Position = Vector3.new(center.X, ly, center.Z)
		lp.Color = Color3.fromRGB(255, 240, 180)
		lp.Material = Enum.Material.Neon
		lp.CanCollide = false
		lp.Parent = ws
		local pl = Instance.new("PointLight")
		pl.Brightness = 2
		pl.Range = 25
		pl.Color = Color3.fromRGB(255, 240, 180)
		pl.Parent = lp
	end

	-- Rooftop detail
	if math.random() > 0.5 then
		local tank = Instance.new("Part")
		tank.Anchored = true
		tank.Size = Vector3.new(3, 3, 3)
		tank.Position = Vector3.new(center.X + math.random(-5, 5), height + 1.5, center.Z + math.random(-5, 5))
		tank.Color = Color3.fromRGB(100, 100, 105)
		tank.Material = Enum.Material.Metal
		tank.Shape = Enum.PartType.Cylinder
		tank.Orientation = Vector3.new(0, 0, 90)
		tank.Parent = ws
	else
		local ant = Instance.new("Part")
		ant.Anchored = true
		ant.Size = Vector3.new(0.4, 8, 0.4)
		ant.Position = Vector3.new(center.X, height + 4, center.Z)
		ant.Color = Color3.fromRGB(140, 140, 145)
		ant.Material = Enum.Material.Metal
		ant.Parent = ws
		local light = Instance.new("Part")
		light.Anchored = true
		light.Size = Vector3.new(1, 1, 1)
		light.Position = Vector3.new(center.X, height + 8, center.Z)
		light.Color = Color3.fromRGB(255, 0, 0)
		light.Material = Enum.Material.Neon
		light.Shape = Enum.PartType.Ball
		light.Parent = ws
	end
end

function CityBuilder.buildCatwalks(ws)
	-- Find all building floors and create catwalks between nearby rooftops
	local floors = {}
	for _, obj in ipairs(ws:GetChildren()) do
		if obj.Name == "Floor" and obj:IsA("Part") then
			table.insert(floors, obj)
		end
	end

	-- Sort by height (top floors first)
	table.sort(floors, function(a, b) return a.Position.Y > b.Position.Y end)

	-- Take top floors of buildings
	local topFloors = {}
	local seen = {}
	for _, f in ipairs(floors) do
		local key = math.floor(f.Position.X / 10) .. "_" .. math.floor(f.Position.Z / 10)
		if not seen[key] then
			seen[key] = true
			table.insert(topFloors, f)
		end
		if #topFloors >= 80 then break end
	end

	-- Create catwalks between close buildings
	local catwalkCount = 0
	for i = 1, #topFloors do
		for j = i + 1, math.min(i + 5, #topFloors) do
			local f1 = topFloors[i]
			local f2 = topFloors[j]
			local dist = (f1.Position - f2.Position).Magnitude

			if dist > 10 and dist < 50 then
				local mid = (f1.Position + f2.Position) / 2
				local dir = (f2.Position - f1.Position).Unit
				local length = dist

				-- Catwalk platform
				local catwalk = Instance.new("Part")
				catwalk.Anchored = true
				catwalk.Size = Vector3.new(length, 0.5, 3)
				catwalk.Position = mid + Vector3.new(0, 0.5, 0)
				catwalk.Color = Color3.fromRGB(100, 100, 105)
				catwalk.Material = Enum.Material.DiamondPlate
				catwalk.TopSurface = Enum.SurfaceType.Smooth
				catwalk.Parent = ws

				-- Railing (left)
				local rail1 = Instance.new("Part")
				rail1.Anchored = true
				rail1.Size = Vector3.new(length, 2, 0.3)
				rail1.Position = mid + Vector3.new(0, 1.5, -1.5)
				rail1.Color = Color3.fromRGB(120, 120, 125)
				rail1.Material = Enum.Material.Metal
				rail1.CanCollide = false
				rail1.Transparency = 0.5
				rail1.Parent = ws

				-- Railing (right)
				local rail2 = Instance.new("Part")
				rail2.Anchored = true
				rail2.Size = Vector3.new(length, 2, 0.3)
				rail2.Position = mid + Vector3.new(0, 1.5, 1.5)
				rail2.Color = Color3.fromRGB(120, 120, 125)
				rail2.Material = Enum.Material.Metal
				rail2.CanCollide = false
				rail2.Transparency = 0.5
				rail2.Parent = ws

				catwalkCount = catwalkCount + 1
			end
		end
	end

	print("[CityBuilder] Created", catwalkCount, "catwalks")
end

CityBuilder.build()
return CityBuilder
