local CreateEffects = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Variables
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Highlight = ReplicatedStorage.States.Highlight
local Hologram = ReplicatedStorage.States.Hologram
local ClientStorage = {}

--// Modules
local ClientStates = require(script.Parent.ClientStates)
local MiscFunctions = require(script.Parent.MiscFunctions)
local createInstances = require(script.Parent.CreateInstances)

--// Module Functions
CreateEffects.ShowRange = function(target, soldierRange, frameCounter)
	local rootPart = target.PrimaryPart
	local numRays = 200 -- Number of rays in the circle
	local lastAttachment
	for i = 0, numRays do
		local ShotRules = RaycastParams.new()
		ShotRules.FilterDescendantsInstances = {
			target,
			Workspace.Targets,
			Workspace.ClientParts,
			Workspace.Walls,
		}
		ShotRules.FilterType = Enum.RaycastFilterType.Exclude
		ShotRules.IgnoreWater = true

		local angle = (i / numRays) * math.pi * 2 -- Convert index to radians
		local localDirection = Vector3.new(math.cos(angle), 0, math.sin(angle)) -- Direction in rootPart's local space
		local direction = rootPart.CFrame:VectorToWorldSpace(localDirection) -- Convert to world space relative to rootPart
		local raycastResult = workspace:Raycast(rootPart.Position, direction * 200, ShotRules) -- Cast the ray
		local attachment = Instance.new("Attachment")
		attachment.Parent = rootPart

		attachment.Visible = false

		if not raycastResult then
			attachment.WorldPosition = rootPart.Position + direction * soldierRange
		else
			attachment.WorldPosition = raycastResult.Position + (rootPart.Position - raycastResult.Position).Unit * 5
		end

		task.delay(0, function()
			for _ = 1, frameCounter do
				RunService.RenderStepped:Wait()
			end
			attachment:Destroy()
		end)

		if lastAttachment then
			local beam = Instance.new("Beam")
			beam.Parent = attachment
			beam.Attachment0 = attachment
			beam.Attachment1 = lastAttachment
		end

		lastAttachment = attachment
	end
end

CreateEffects.makeHologram = function(start)
	MiscFunctions.restStep(25)
	for _ = 0, ClientStates.maxSteps, 1 do
		MiscFunctions.incrementStep()
		local raycastHit = MiscFunctions.raycast(
			start + Vector3.new(ClientStates.stepX, 2, ClientStates.stepY),
			start + Vector3.new(0, 4, 0)
		)
		if raycastHit and raycastHit ~= true and ClientStates.squad then
			if not Hologram.Value then
				Hologram.Value = ReplicatedStorage.ReplicatedObjects.hologram:Clone()
				Hologram.Value.Parent = Workspace.ClientParts
			end
			local floor = MiscFunctions.raycast(start + Vector3.new(0, -9999, 0), start + Vector3.new(0, 4, 0))
			local lookAt = CFrame.lookAt(floor, raycastHit)

			lookAt = lookAt * CFrame.new(0, 1.5, 0) * CFrame.fromEulerAngles(-lookAt.Rotation.X, 0, -lookAt.Rotation.Z)
			local _, y = lookAt:ToOrientation()
			local newCFrame = CFrame.fromOrientation(0, y, 0)
				+ Vector3.new(math.round(lookAt.Position.X), lookAt.Position.Y, math.round(lookAt.Position.Z))
				+ Vector3.new(0, 1, 0)
			if Hologram.Value and Hologram.Value.PrimaryPart then
				Hologram.Value:SetPrimaryPartCFrame(newCFrame)
			end
			return true
		end
	end
	Hologram.Value = MiscFunctions.removeObject(Hologram.Value)
	return false
end

CreateEffects.animateUnderlay = function(squadSelected)
	local squad = squadSelected --or mouse.Target and { mouse.Target:findFirstAncestorOfClass("Model") }
	for _, char in squad do
		task.spawn(function()
			if char and char:FindFirstChild("Underlay") then
				if char.Underlay.Color == Color3.fromRGB(255, 29, 33) then
					char.Underlay.Color = Color3.fromRGB(88, 88, 88)
				end
				TweenService:Create(char.Underlay, TweenInfo.new(0.1), { Size = Vector3.new(4.5, 0.031, 4.5) }):Play()
				table.insert(ClientStorage, char.Underlay)
			end
		end)
	end
	for i, underlay in ClientStorage do
		if underlay.Size.X > 4 and not table.find(squadSelected, underlay.Parent) then
			if underlay.Color == Color3.fromRGB(88, 88, 88) then
				underlay.Color = Color3.fromRGB(255, 29, 33)
			end
			TweenService:Create(underlay, TweenInfo.new(0.1), { Size = Vector3.new(4, 0.031, 4) }):Play()
			table.remove(ClientStorage, i)
		end
	end
end

CreateEffects.highlightObject = function()
	local soldierSpawn = mouse.Target and mouse.Target:FindFirstAncestor("Spawn")
	-- if
	-- 	input.UserInputType == Enum.UserInputType.MouseMovement
	-- 	and ClientStates.squad
	-- 	and not ClientStates.PlacingWall
	-- then
	-- 	if not mouse.Target or not mouse.Target.Parent then
	-- 		return
	-- 	end
	-- 	local hoverOver = mouse.Target.Parent
	-- 	if
	-- 		hoverOver
	-- 		and hoverOver.Name == "Door Closed"
	-- 		and hoverOver.Parent:GetAttribute("Owner") ~= player.UserId
	-- 	then
	-- 		createInstances.SetHighlight(hoverOver, false, Color3.new(0, 0, 0), true)
	-- 	else
	-- 		Highlight.Value = MiscFunctions.removeObject(Highlight.Value)
	-- 	end
	-- end
	if
		soldierSpawn
		and soldierSpawn.Parent:GetAttribute("Owner") == player.UserId
		and not soldierSpawn:FindFirstChildOfClass("Highlight")
	then
		createInstances.SetHighlight(soldierSpawn, false, Color3.new(0, 0, 0), true)
	elseif not soldierSpawn and Highlight.Value and Highlight.Value.OutlineColor == Color3.fromRGB(0, 0, 0) then
		Highlight.Value = MiscFunctions.removeObject(Highlight.Value)
	end
end

--// TODO Make Better
CreateEffects.makeHologram = function(start)
	MiscFunctions.restStep(25)
	for _ = 0, ClientStates.maxSteps, 1 do
		MiscFunctions.incrementStep()
		local raycastHit = MiscFunctions.raycast(
			start + Vector3.new(ClientStates.stepX, 2, ClientStates.stepY),
			start + Vector3.new(0, 4, 0)
		)
		if raycastHit and raycastHit ~= true and ClientStates.squad then
			if not Hologram.Value then
				Hologram.Value = ReplicatedStorage.ReplicatedObjects.hologram:Clone()
				Hologram.Value.Parent = Workspace.ClientParts
			end
			local floor = MiscFunctions.raycast(start + Vector3.new(0, -9999, 0), start + Vector3.new(0, 4, 0))
			local lookAt = CFrame.lookAt(floor, raycastHit)

			lookAt = lookAt * CFrame.new(0, 1.5, 0) * CFrame.fromEulerAngles(-lookAt.Rotation.X, 0, -lookAt.Rotation.Z)
			local _, y, _ = lookAt:ToOrientation()
			local newCFrame = CFrame.fromOrientation(0, y, 0)
				+ Vector3.new(math.round(lookAt.Position.X), lookAt.Position.Y, math.round(lookAt.Position.Z))
				+ Vector3.new(0, 1, 0)
			if Hologram.Value and Hologram.Value.PrimaryPart then
				Hologram.Value:SetPrimaryPartCFrame(newCFrame)
			end
			return true
		end
	end
	Hologram.Value = MiscFunctions.removeObject(Hologram.Value)
	return false
end

function CreateEffects.CreateselectionBox()
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 0.9
	frame.BorderSizePixel = 1
	frame.Size = UDim2.fromOffset(0, 0)
	frame.Parent = player.PlayerGui.ScreenSelection
	frame.Position = UDim2.fromOffset(mouse.X, mouse.Y)
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	return frame, mouse.X, mouse.Y
end

return CreateEffects
