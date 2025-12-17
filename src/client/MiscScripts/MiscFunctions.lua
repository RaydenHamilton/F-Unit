local MiscFunctions = {}
local remoteFunc = game.ReplicatedStorage.NPCEvents.GetNPCData
local tempData = require(script.Parent.TempData)

local player = game.Players.LocalPlayer
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local mouse = player:GetMouse()

--// Module Functions
MiscFunctions.restStep = function(max)
	tempData.stepX, tempData.stepY = 0, 0
	tempData.whatStepIsItOn = 1
	tempData.stepSpacing = 1
	tempData.stepLength = 1
	tempData.stepDirection = 0
	tempData.turnCounter = 1
	tempData.maxSteps = max
end

MiscFunctions.incrementStep = function()
	local directionAdjustments = {
		{ tempData.stepSpacing, 0 }, -- stepDirection 0: move right
		{ 0, -tempData.stepSpacing }, -- stepDirection 1: move up
		{ -tempData.stepSpacing, 0 }, -- stepDirection 2: move left
		{ 0, tempData.stepSpacing }, -- stepDirection 3: move down
	}

	tempData.stepX += directionAdjustments[tempData.stepDirection + 1][1]
	tempData.stepY += directionAdjustments[tempData.stepDirection + 1][2]

	if tempData.whatStepIsItOn % tempData.stepLength == 0 then
		tempData.stepDirection = (tempData.stepDirection + 1) % 4
		tempData.turnCounter += 1
		if tempData.turnCounter % 2 == 0 then
			tempData.stepLength += 1
		end
	end
	tempData.whatStepIsItOn += 1
end

MiscFunctions.unselect = function()
	if MiscFunctions.isMyNPC(tempData.Target) and tempData.Target then
		if tempData.Target:FindFirstChild("Underlay") then
			tempData.Target.Underlay.Color = Color3.fromRGB(255, 29, 33)
		end
		if tempData.selceted then
			tempData.selceted:Disconnect()
		end
		botGui.Enabled = false
		-- Clear all relevant variables at once
		tempData.Target, tempData.HealingTeamate, tempData.partStart, tempData.placeingWall = false, false, false, false
	end
	MiscFunctions.removeObjects()
end

MiscFunctions.removeObjects = function()
	tempData.characterHighlight = MiscFunctions.removeObject(tempData.characterHighlight)
	tempData.marker = MiscFunctions.removeObject(tempData.marker)
	tempData.hologram = MiscFunctions.removeObject(tempData.hologram)
end

MiscFunctions.raycast = function(length, center)
	local raycastParams = RaycastParams.new()

	raycastParams.FilterDescendantsInstances = { game.Workspace.ClientParts, game.Workspace.Targets }
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
		math.min(tempData.region[1].X, tempData.region[2].X),
		math.min(tempData.region[1].Y, tempData.region[2].Y),
		math.min(tempData.region[1].Z, tempData.region[2].Z)
	)
	local maxCorner = Vector3.new(
		math.max(tempData.region[1].X, tempData.region[2].X),
		math.max(tempData.region[1].Y, tempData.region[2].Y),
		math.max(tempData.region[1].Z, tempData.region[2].Z)
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

MiscFunctions.isMyNPC = function(soldier: Model)
	if soldier and soldier then
		local owner = remoteFunc:InvokeServer(soldier, "owner")
		return owner == player.UserId
	else
		return false
	end
end

MiscFunctions.ifNot = function()
	return not tempData.HealingTeamate and not tempData.placeingWall
end

MiscFunctions.removeObject = function(object)
	if object then
		object:Destroy()
	end
	return nil
end

return MiscFunctions
