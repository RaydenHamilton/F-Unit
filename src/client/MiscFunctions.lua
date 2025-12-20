--!nocheck

local MiscFunctions = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Variables
local player = Players.LocalPlayer
local Client = player.PlayerScripts.Client
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local mouse = player:GetMouse()
local Highlight = ReplicatedStorage.States.Highlight
local Target = ReplicatedStorage.States.Target
local Hologram = ReplicatedStorage.States.Hologram
local Marker = ReplicatedStorage.States.Marker

--// Modules
local ClientStates = require(Client.ClientStates)

--// Module Functions
MiscFunctions.restStep = function(max)
	ClientStates.stepX, ClientStates.stepY = 0, 0
	ClientStates.whatStepIsItOn = 1
	ClientStates.stepSpacing = 1
	ClientStates.stepLength = 1
	ClientStates.stepDirection = 0
	ClientStates.turnCounter = 1
	ClientStates.maxSteps = max
end

MiscFunctions.incrementStep = function()
	local directionAdjustments = {
		{ ClientStates.stepSpacing, 0 }, -- stepDirection 0: move right
		{ 0, -ClientStates.stepSpacing }, -- stepDirection 1: move up
		{ -ClientStates.stepSpacing, 0 }, -- stepDirection 2: move left
		{ 0, ClientStates.stepSpacing }, -- stepDirection 3: move down
	}

	ClientStates.stepX += directionAdjustments[ClientStates.stepDirection + 1][1]
	ClientStates.stepY += directionAdjustments[ClientStates.stepDirection + 1][2]

	if ClientStates.whatStepIsItOn % ClientStates.stepLength == 0 then
		ClientStates.stepDirection = (ClientStates.stepDirection + 1) % 4
		ClientStates.turnCounter += 1
		if ClientStates.turnCounter % 2 == 0 then
			ClientStates.stepLength += 1
		end
	end
	ClientStates.whatStepIsItOn += 1
end

MiscFunctions.removeObject = function(object)
	if object then
		object:Destroy()
	end
	return nil
end

MiscFunctions.removeObjects = function()
	Highlight.Value = MiscFunctions.removeObject(Highlight.Value)
	Marker.Value = MiscFunctions.removeObject(Marker.Value)
	Hologram.Value = MiscFunctions.removeObject(Hologram.Value)
end

MiscFunctions.isMyNPC = function(soldier: Model)
	if soldier then
		return soldier:GetAttribute("Owner") == player.UserId
	else
		return false
	end
end

MiscFunctions.unselect = function()
	if MiscFunctions.isMyNPC(Target.Value) then
		if Target.Value:FindFirstChild("Underlay") then
			Target.Value.Underlay.Color = Color3.fromRGB(255, 29, 33)
		end
		if ClientStates.selceted then
			ClientStates.selceted:Disconnect()
		end
		botGui.Enabled = false
		-- Clear all relevant variables at once
		Target.Value, ClientStates.HealingTeamate, ClientStates.partStart, ClientStates.placeingWall =
			nil, nil, nil, nil
	end
	MiscFunctions.removeObjects()
end

MiscFunctions.raycast = function(length, center)
	local raycastParams = RaycastParams.new()

	raycastParams.FilterDescendantsInstances = { Workspace.ClientParts, Workspace.Targets }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local direction = (length - center).Unit * (length - center).Magnitude * 0.99
	local raycastResult = workspace:Raycast(center, direction, raycastParams)

	if raycastResult then
		return raycastResult.Position
	end

	return true
end

MiscFunctions.MouseIsInregion = function()
	local pos = mouse.Hit.Position -- Get updated mouse position
	-- Get the min and max corners of the region
	local minCorner = Vector3.new(
		math.min(ClientStates.region[1].X, ClientStates.region[2].X),
		math.min(ClientStates.region[1].Y, ClientStates.region[2].Y),
		math.min(ClientStates.region[1].Z, ClientStates.region[2].Z)
	)
	local maxCorner = Vector3.new(
		math.max(ClientStates.region[1].X, ClientStates.region[2].X),
		math.max(ClientStates.region[1].Y, ClientStates.region[2].Y),
		math.max(ClientStates.region[1].Z, ClientStates.region[2].Z)
	)
	-- Check if the position is inside the region
	if
		pos.X >= minCorner.X
		and pos.X <= maxCorner.X
		and pos.Y >= minCorner.Y
		and pos.Y <= maxCorner.Y
		and pos.Z >= minCorner.Z
		and pos.Z <= maxCorner.Z
	then
		return true
	else
		return false
	end
end

MiscFunctions.SoldierNotDoingAnything = function()
	return not ClientStates.HealingTeamate and not ClientStates.placeingWall
end

return MiscFunctions
