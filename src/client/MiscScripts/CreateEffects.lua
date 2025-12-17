--!strict

local CreateEffects = {}

local remoteFunc = game.ReplicatedStorage.NPCEvents.GetNPCData

--// Modules
local tempData = require(script.Parent.TempData)
local MiscFunctions = require(script.Parent.MiscFunctions)
local createInstances = require(script.Parent.CreateInstances)

--// Services
local TweenService = game:GetService("TweenService")

--// Varubles
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

--// Module Functions
CreateEffects.ShowRange = function(Target: Model, soldierRange: number)
	local rootPart = Target.PrimaryPart :: BasePart
	local numRays = 200 -- Number of rays in the circle
	local last
	for i = 0, numRays do
		local ShotRules = RaycastParams.new()
		ShotRules.FilterDescendantsInstances = {
			Target,
			game.Workspace.Targets,
			game.Workspace.ClientParts,
			game.Workspace.walls,
		}
		ShotRules.FilterType = Enum.RaycastFilterType.Exclude
		ShotRules.IgnoreWater = true

		local angle = (i / numRays) * math.pi * 2 -- Convert index to radians
		local localDirection = Vector3.new(math.cos(angle), 0, math.sin(angle)) -- Direction in rootPart's local space
		local direction = rootPart.CFrame:VectorToWorldSpace(localDirection) -- Convert to world space relative to rootPart
		local raycastResult = workspace:Raycast(rootPart.Position, direction * 200, ShotRules) -- Cast the ray
		local attachment = Instance.new("Attachment", rootPart)

		attachment.Visible = false

		if not raycastResult then
			attachment.WorldPosition = rootPart.Position + direction * soldierRange
		else
			attachment.WorldPosition = raycastResult.Position + (rootPart.Position - raycastResult.Position).Unit * 5
		end

		task.delay(0, function()
			attachment:Destroy()
		end)

		if last then
			local beam = Instance.new("Beam", attachment)
			beam.Attachment0 = attachment
			beam.Attachment1 = last
		end

		last = attachment
	end
end

CreateEffects.makeHologram = function(start: Vector3)
	MiscFunctions.restStep(25)
	for count = 0, tempData.maxSteps, 1 do
		MiscFunctions.incrementStep()
		local raycastHit =
			MiscFunctions.raycast(start + Vector3.new(tempData.stepX, 2, tempData.stepY), start + Vector3.new(0, 4, 0))
		if raycastHit and raycastHit ~= true and tempData.Target then
			if not tempData.hologram then
				tempData.hologram = game.ReplicatedStorage.ReplicatedObjects.hologram:Clone()
				tempData.hologram.Parent = game.Workspace.ClientParts
			end
			local floor = MiscFunctions.raycast(start + Vector3.new(0, -9999, 0), start + Vector3.new(0, 4, 0))
			local lookAt = CFrame.lookAt(floor, raycastHit)

			lookAt = lookAt * CFrame.new(0, 1.5, 0) * CFrame.fromEulerAngles(-lookAt.Rotation.X, 0, -lookAt.Rotation.Z)
			local _, y = lookAt:ToOrientation()
			local newCFrame = CFrame.fromOrientation(0, y, 0)
				+ Vector3.new(math.round(lookAt.Position.X), lookAt.Position.Y, math.round(lookAt.Position.Z))
				+ Vector3.new(0, 1, 0)
			if tempData.hologram and tempData.hologram.PrimaryPart then
				tempData.hologram:SetPrimaryPartCFrame(newCFrame)
			end
			return true
		end
	end
	tempData.hologram = MiscFunctions.removeObject(tempData.hologram)
	return false
end

CreateEffects.animateUnderlay = function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local list = require(game.ReplicatedStorage.LocalClientStorage)
		local char = mouse.Target and mouse.Target.Parent

		if char and char:FindFirstChild("Underlay") then
			if char.Underlay.Color == Color3.fromRGB(255, 29, 33) then
				char.Underlay.Color = Color3.fromRGB(88, 88, 88)
			end
			TweenService:Create(char.Underlay, TweenInfo.new(0.1), { Size = Vector3.new(4.5, 0.031, 4.5) }):Play()
			table.insert(list, char.Underlay)
		end

		for i, underlay in pairs(list) do
			if underlay.Size.X > 4 and mouse.Target and mouse.Target.Parent ~= underlay.Parent then
				if underlay.Color == Color3.fromRGB(88, 88, 88) then
					underlay.Color = Color3.fromRGB(255, 29, 33)
				end
				TweenService:Create(underlay, TweenInfo.new(0.1), { Size = Vector3.new(4, 0.031, 4) }):Play()
				table.remove(list, i)
			end
		end
	end
end

CreateEffects.highlightCharacter = function(input)
	repeat
		task.wait()
	until tempData.erroFlash ~= true
	if input.UserInputType == Enum.UserInputType.MouseMovement and tempData.Target and not tempData.placeingWall then
		if not mouse.Target or not mouse.Target.Parent then
			return
		end
		local hoverOver = mouse.Target.Parent
		if hoverOver and hoverOver:GetTags()[1] and hoverOver.Parent then
			local owner = remoteFunc:InvokeServer(hoverOver:GetTags()[1], "owner")
			if not owner then
				return
			end
			if owner ~= player.UserId and not tempData.HealingTeamate then
				createInstances.SetHighlight(hoverOver, Color3.new(1, 0, 0), false, false)
			elseif owner == player.UserId and hoverOver ~= tempData.Target and tempData.HealingTeamate then
				createInstances.SetHighlight(hoverOver, Color3.new(0, 1, 0), false, false)
			end
		elseif
			hoverOver
			and hoverOver.Name == "Door Closed"
			and tonumber(hoverOver.Parent:GetTags()[1]) ~= player.UserId
		then
			createInstances.SetHighlight(hoverOver, false, Color3.new(0, 0, 0), true)
			tempData.hologram = MiscFunctions.removeObject(tempData.hologram)
		else
			tempData.characterHighlight = MiscFunctions.removeObject(tempData.characterHighlight)
		end
	elseif
		mouse.Target
		and mouse.Target.Parent
		and mouse.Target.Parent.Parent.Name == "Spawn"
		and tonumber(mouse.Target.Parent.Parent.Parent:GetTags()[1]) == player.UserId
		and not mouse.Target.Parent.Parent:FindFirstChildOfClass("Highlight")
	then
		createInstances.SetHighlight(mouse.Target.Parent.Parent, false, Color3.new(0, 0, 0), true)
	elseif
		mouse.Target
			and mouse.Target.Parent.Parent.Name ~= "Spawn"
			and tempData.characterHighlight
			and tempData.characterHighlight.Parent.Name ~= "Spawn"
		or tempData.characterHighlight
			and tempData.characterHighlight.OutlineColor == Color3.fromRGB(0, 0, 0)
			and mouse.Target
			and mouse.Target.Parent.Parent.Name ~= "Spawn"
	then
		tempData.characterHighlight = MiscFunctions.removeObject(tempData.characterHighlight)
	end
end

CreateEffects.makeHologram = function(start)
	MiscFunctions.restStep(25)
	for count = 0, tempData.maxSteps, 1 do
		MiscFunctions.incrementStep()
		local raycastHit =
			MiscFunctions.raycast(start + Vector3.new(tempData.stepX, 2, tempData.stepY), start + Vector3.new(0, 4, 0))
		if raycastHit and raycastHit ~= true and tempData.Target then
			if not tempData.hologram then
				tempData.hologram = game.ReplicatedStorage.ReplicatedObjects.hologram:Clone()
				tempData.hologram.Parent = game.Workspace.ClientParts
			end
			local floor = MiscFunctions.raycast(start + Vector3.new(0, -9999, 0), start + Vector3.new(0, 4, 0))
			local lookAt = CFrame.lookAt(floor, raycastHit)

			lookAt = lookAt * CFrame.new(0, 1.5, 0) * CFrame.fromEulerAngles(-lookAt.Rotation.X, 0, -lookAt.Rotation.Z)
			local _, y, _ = lookAt:ToOrientation()
			local newCFrame = CFrame.fromOrientation(0, y, 0)
				+ Vector3.new(math.round(lookAt.Position.X), lookAt.Position.Y, math.round(lookAt.Position.Z))
				+ Vector3.new(0, 1, 0)
			if tempData.hologram and tempData.hologram.PrimaryPart then
				tempData.hologram:SetPrimaryPartCFrame(newCFrame)
			end
			return true
		end --
	end
	tempData.hologram = MiscFunctions.removeObject(tempData.hologram)
	return false
end

return CreateEffects
