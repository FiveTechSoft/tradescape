-- InitWorld.lua — Creates baseplate and spawn on server start
-- Place in: ServerScriptService/InitWorld (Script)

local function setupWorld()
	local ws = game:GetService("Workspace")

	-- Baseplate
	if not ws:FindFirstChild("Baseplate") then
		local bp = Instance.new("Part")
		bp.Name = "Baseplate"
		bp.Anchored = true
		bp.Size = Vector3.new(512, 1, 512)
		bp.Position = Vector3.new(0, -0.5, 0)
		bp.Color = Color3.fromRGB(55, 55, 55)
		bp.Material = Enum.Material.Slate
		bp.TopSurface = Enum.SurfaceType.Smooth
		bp.BottomSurface = Enum.SurfaceType.Smooth
		bp.Parent = ws
	end

	-- SpawnLocation
	if not ws:FindFirstChild("SpawnLocation") then
		local sp = Instance.new("SpawnLocation")
		sp.Name = "SpawnLocation"
		sp.Anchored = true
		sp.Size = Vector3.new(6, 1, 6)
		sp.Position = Vector3.new(0, 0.5, 0)
		sp.Color = Color3.fromRGB(0, 162, 255)
		sp.Material = Enum.Material.Plastic
		sp.TopSurface = Enum.SurfaceType.Smooth
		sp.BottomSurface = Enum.SurfaceType.Smooth
		sp.Duration = 0
		sp.Neutral = true
		sp.Parent = ws
	end
end

setupWorld()
print("[InitWorld] Baseplate and SpawnLocation created")
