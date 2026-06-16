-- CarControls.client.lua — Enter/drive/exit cars
-- Place in: StarterPlayerScripts/CarControls (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local EnterCar = ReplicatedStorage:WaitForChild("EnterCar")
local ExitCar = ReplicatedStorage:WaitForChild("ExitCar")
local CarControl = ReplicatedStorage:WaitForChild("CarControl")

local inCar = false
local accelerate = false
local brake = false
local steerLeft = false
local steerRight = false

-- ============================================================
-- Enter car (E key near a car)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if inCar then
			-- Exit car
			ExitCar:FireServer()
			inCar = false
		else
			-- Enter car
			EnterCar:FireServer()
			task.wait(0.5)
			-- Check if we're in a vehicle seat
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
					inCar = true
				end
			end
		end
	end

	-- Exit with F
	if input.KeyCode == Enum.KeyCode.F and inCar then
		ExitCar:FireServer()
		inCar = false
	end
end)

-- ============================================================
-- Driving controls (WASD / Arrow keys)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not inCar then return end

	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		accelerate = true
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		brake = true
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		steerLeft = true
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		steerRight = true
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		accelerate = false
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		brake = false
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		steerLeft = false
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		steerRight = false
	end
end)

-- ============================================================
-- Send controls every frame
-- ============================================================
RunService.Heartbeat:Connect(function()
	if not inCar then return end

	if accelerate then
		CarControl:FireServer("accelerate", 1)
	end
	if brake then
		CarControl:FireServer("brake", 1)
	end
	if steerLeft then
		CarControl:FireServer("steer", -1)
	end
	if steerRight then
		CarControl:FireServer("steer", 1)
	end
end)

-- ============================================================
-- Detect if we're sitting in a car seat
-- ============================================================
player.CharacterAdded:Connect(function(character)
	inCar = false
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
			inCar = true
		else
			inCar = false
			accelerate = false
			brake = false
			steerLeft = false
			steerRight = false
		end
	end)
end)

-- Handle existing character
if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
			if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
				inCar = true
			else
				inCar = false
			end
		end)
	end
end

print("[CarControls] Ready — E to enter, WASD to drive, F to exit")
