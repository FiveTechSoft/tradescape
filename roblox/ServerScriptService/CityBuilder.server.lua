-- CityBuilder.server.lua — Massive coastal city
-- Place in: ServerScriptService/CityBuilder (Script)

local CityBuilder = {}

function CityBuilder.build()
	local ws = game:GetService("Workspace")

	local oldBP = ws:FindFirstChild("Baseplate")
	if oldBP then oldBP:Destroy() end

	-- Ground 2000x2000
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(2000, 1, 2000)
	ground.Position = Vector3.new(0, -0.5, 0)
	ground.Color = Color3.fromRGB(50, 50, 55)
	ground.Material = Enum.Material.Concrete
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = ws

	-- Beach
	local beach = Instance.new("Part")
	beach.Name = "Beach"
	beach.Anchored = true
	beach.Size = Vector3.new(2000, 1.5, 150)
	beach.Position = Vector3.new(0, -0.2, 900)
	beach.Color = Color3.fromRGB(210, 190, 140)
	beach.Material = Enum.Material.Sand
	beach.TopSurface = Enum.SurfaceType.Smooth
	beach.Parent = ws

	-- Water
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Anchored = true
	water.Size = Vector3.new(2400, 1, 250)
	water.Position = Vector3.new(0, -1, 1050)
	water.Color = Color3.fromRGB(30, 100, 180)
	water.Material = Enum.Material.Glass
	water.Transparency = 0.3
	water.TopSurface = Enum.SurfaceType.Smooth
	water.Parent = ws

	-- Grid of streets
	local streetPositionsEW = {}
	local streetPositionsNS = {}

	for z = -800, 800, 100 do
		table.insert(streetPositionsEW, z)
	end
	for x = -800, 800, 100 do
		table.insert(streetPositionsNS, x)
	end

	-- East-West streets
	for _, z in ipairs(streetPositionsEW) do
		local s = Instance.new("Part")
		s.Name = "Street"
		s.Anchored = true
		s.Size = Vector3.new(2000, 0.1, 14)
		s.Position = Vector3.new(0, 0.02, z)
		s.Color = Color3.fromRGB(35, 35, 40)
		s.Material = Enum.Material.Asphalt
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = ws

		-- Center line
		local line = Instance.new("Part")
		line.Anchored = true
		line.Size = Vector3.new(2000, 0.15, 0.4)
		line.Position = Vector3.new(0, 0.08, z)
		line.Color = Color3.fromRGB(200, 200, 80)
		line.Material = Enum.Material.Neon
		line.Parent = ws
	end

	-- North-South streets
	for _, x in ipairs(streetPositionsNS) do
		local s = Instance.new("Part")
		s.Name = "Street"
		s.Anchored = true
		s.Size = Vector3.new(14, 0.1, 2000)
		s.Position = Vector3.new(x, 0.02, 0)
		s.Color = Color3.fromRGB(35, 35, 40)
		s.Material = Enum.Material.Asphalt
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = ws
	end

	-- Sidewalks along main streets
	for _, z in ipairs(streetPositionsEW) do
		for _, side in ipairs({-9, 9}) do
			local sw = Instance.new("Part")
			sw.Anchored = true
			sw.Size = Vector3.new(2000, 0.15, 3)
			sw.Position = Vector3.new(0, 0.06, z + side)
			sw.Color = Color3.fromRGB(125, 125, 130)
			sw.Material = Enum.Material.Concrete
			sw.TopSurface = Enum.SurfaceType.Smooth
			sw.Parent = ws
		end
	end

	-- Buildings: 10x10 grid of city blocks, 4-6 buildings per block
	local buildingCount = 0
	local blockStartX = -750
	local blockStartZ = -750
	local blockSpacing = 100

	for bx = 0, 15 do
		for bz = 0, 15 do
			local blockX = blockStartX + bx * blockSpacing
			local blockZ = blockStartZ + bz * blockSpacing

			-- 4-6 buildings per block
			local numBuildings = math.random(4, 6)
			for b = 1, numBuildings do
				local offsetX = (b - 1) * 18 - (numBuildings * 9)
				local offsetZ = math.random(-20, 20)

				local height = math.random(8, 50)
				local width = math.random(14, 28)
				local depth = math.random(14, 28)

				-- Taller buildings near center
				local distFromCenter = math.sqrt(blockX * blockX + blockZ * blockZ)
				if distFromCenter < 300 then
					height = math.random(30, 80)
					width = math.random(18, 30)
					depth = math.random(18, 30)
				end

				local pos = Vector3.new(
					blockX + offsetX,
					height / 2,
					blockZ + offsetZ
				)

				-- Building colors
				local colors = {
					Color3.fromRGB(75, 80, 90),
					Color3.fromRGB(85, 75, 70),
					Color3.fromRGB(70, 75, 85),
					Color3.fromRGB(90, 85, 80),
					Color3.fromRGB(80, 80, 90),
					Color3.fromRGB(95, 85, 75),
					Color3.fromRGB(75, 85, 80),
					Color3.fromRGB(85, 80, 85),
				}

				local bPart = Instance.new("Part")
				bPart.Name = "B"
				bPart.Anchored = true
				bPart.Size = Vector3.new(width, height, depth)
				bPart.Position = pos
				bPart.Color = colors[math.random(#colors)]
				bPart.Material = Enum.Material.SmoothPlastic
				bPart.TopSurface = Enum.SurfaceType.Smooth
				bPart.Parent = ws

				-- Windows on front
				local wRows = math.floor(height / 4)
				local wCols = math.floor(width / 4.5)
				for row = 1, math.min(wRows, 15) do
					for col = 1, math.min(wCols, 6) do
						if math.random() > 0.25 then
							local win = Instance.new("Part")
							win.Anchored = true
							win.Size = Vector3.new(2, 2.5, 0.15)
							win.Position = pos + Vector3.new(
								-col * 4 + width / 2 + 2,
								row * 4 - height / 2 + 1,
								depth / 2 + 0.1
							)
							win.Color = math.random() > 0.4
								and Color3.fromRGB(255, 240, 180)
								or Color3.fromRGB(35, 45, 55)
							win.Material = win.Color.R > 0.9 and Enum.Material.Neon or Enum.Material.SmoothPlastic
							win.Parent = ws
						end
					end
				end

				-- Windows on side
				local wColsZ = math.floor(depth / 4.5)
				for row = 1, math.min(wRows, 15) do
					for col = 1, math.min(wColsZ, 6) do
						if math.random() > 0.25 then
							local win = Instance.new("Part")
							win.Anchored = true
							win.Size = Vector3.new(0.15, 2.5, 2)
							win.Position = pos + Vector3.new(
								width / 2 + 0.1,
								row * 4 - height / 2 + 1,
								-col * 4 + depth / 2 + 2
							)
							win.Color = math.random() > 0.4
								and Color3.fromRGB(255, 240, 180)
								or Color3.fromRGB(35, 45, 55)
							win.Material = win.Color.R > 0.9 and Enum.Material.Neon or Enum.Material.SmoothPlastic
							win.Parent = ws
						end
					end
				end

				-- Rooftop antenna for tall buildings
				if height > 40 and math.random() > 0.5 then
					local ant = Instance.new("Part")
					ant.Anchored = true
					ant.Size = Vector3.new(0.4, 8, 0.4)
					ant.Position = pos + Vector3.new(0, height / 2 + 4, 0)
					ant.Color = Color3.fromRGB(140, 140, 145)
					ant.Material = Enum.Material.Metal
					ant.Parent = ws

					local light = Instance.new("Part")
					light.Anchored = true
					light.Size = Vector3.new(1, 1, 1)
					light.Position = pos + Vector3.new(0, height / 2 + 8, 0)
					light.Color = Color3.fromRGB(255, 0, 0)
					light.Material = Enum.Material.Neon
					light.Shape = Enum.PartType.Ball
					light.Parent = ws
				end

				buildingCount = buildingCount + 1
			end
		end
	end

	-- Park (large, near beach)
	local park = Instance.new("Part")
	park.Name = "Park"
	park.Anchored = true
	park.Size = Vector3.new(80, 0.2, 60)
	park.Position = Vector3.new(-200, 0.1, 700)
	park.Color = Color3.fromRGB(45, 115, 40)
	park.Material = Enum.Material.Grass
	park.TopSurface = Enum.SurfaceType.Smooth
	park.Parent = ws

	-- Trees in park
	for i = 1, 20 do
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

	-- Lampposts (every 100 studs along main streets)
	for x = -800, 800, 100 do
		for _, z in ipairs({-100, 100}) do
			local pole = Instance.new("Part")
			pole.Anchored = true
			pole.Size = Vector3.new(0.3, 8, 0.3)
			pole.Position = Vector3.new(x, 4, z - 9)
			pole.Color = Color3.fromRGB(75, 75, 80)
			pole.Material = Enum.Material.Metal
			pole.Parent = ws

			local lamp = Instance.new("Part")
			lamp.Anchored = true
			lamp.Size = Vector3.new(1.5, 1, 1.5)
			lamp.Position = Vector3.new(x, 8.5, z - 9)
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

	print("[CityBuilder] City built:", buildingCount, "buildings")
end

CityBuilder.build()
return CityBuilder
