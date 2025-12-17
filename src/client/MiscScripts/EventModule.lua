--!strict

local EventModule = {}

--// Modules
local tempData = require(script.Parent.TempData)
local MiscFunctions = require(script.Parent.MiscFunctions)
local createInstances = require(script.Parent.CreateInstances)
local createEffects = require(script.Parent.CreateEffects)

--// Services
local Player = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sandbag = ReplicatedStorage.ReplicatedObjects.Sandbag

local player = Player.LocalPlayer
local NPCEvents = ReplicatedStorage.NPCEvents

-- Events
local placeObject = NPCEvents.PlaceObject
local move = NPCEvents.Move
local heal = NPCEvents.Heal
local setPose = ReplicatedStorage.NPCEvents.SetPose

local mouse = player:GetMouse()
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")

--// Module Functions
EventModule.crawl = function()
	setPose:FireServer("cwral", tempData.Target)
end

EventModule.crouch = function()
	setPose:FireServer("crouch", tempData.Target)
end

EventModule.stand = function()
	setPose:FireServer("stand", tempData.Target)
end

EventModule.placeWall = function()
	local remoteFunc = game.ReplicatedStorage.NPCEvents.GetNPCData
	tempData.placeingWall = true
	local Walls = remoteFunc:InvokeServer(tempData.Target, "Walls")
	if not tempData.marker then
		MiscFunctions.removeObjects()
		tempData.marker = createInstances.setUpMarker(mouse)
		while tempData.placeingWall and task.wait() and tempData.marker do
			tempData.marker.Position = mouse.Hit.Position + Vector3.new(0, tempData.marker.Size.Y / 2, 0)
			if not MiscFunctions.MouseIsInregion() then
				tempData.marker.Color = Color3.new(1, 0, 0)
			else
				tempData.marker.Color = Color3.new(0, 0, 1)
			end
		end
	end
	if tempData.marker and not MiscFunctions.MouseIsInregion() then
		MiscFunctions.unselect()
	elseif tempData.marker then
		if tempData.partStart then
			local size = math.round((tempData.marker.Size.Z / sandbag.Size.Z) / 0.6)
			local partEnd = mouse.Hit.Position
			if tempData.marker.Color == Color3.new(0, 0, 1) then
				placeObject:FireServer(
					size,
					tempData.partStart - Vector3.new(0, tempData.marker.Size.Y / 2, 0),
					partEnd,
					tempData.Target
				)
			end
			return MiscFunctions.unselect()
		end
		local text = createInstances.makeBillboardGui(tempData.marker)
		tempData.partStart = mouse.Hit.Position + Vector3.new(0, tempData.marker.Size.Y / 2, 0)
		while task.wait() and tempData.marker do
			if tempData.partStart then
				tempData.marker.CFrame = CFrame.lookAt(
					(tempData.partStart + mouse.Hit.Position) / 2 + Vector3.new(0, tempData.marker.Size.Y / 4, 0),
					mouse.Hit.Position + Vector3.new(0, tempData.marker.Size.Y / 2, 0)
				)
				tempData.marker.Size = Vector3.new(1, 3, (tempData.partStart - mouse.Hit.Position).Magnitude)
				text.Text = math.round((tempData.marker.Size.Z / sandbag.Size.Z) / 0.6)
				if
					math.round((tempData.marker.Size.Z / sandbag.Size.Z) / 0.6) > Walls
					or not MiscFunctions.MouseIsInregion()
				then
					tempData.marker.Color = Color3.new(1, 0, 0)
				else
					tempData.marker.Color = Color3.new(0, 0, 1)
				end
			end
		end
	end
end

EventModule.clickSelfHeal = function()
	heal:FireServer(tempData.Target, tempData.Target)
	MiscFunctions.unselect()
end

EventModule.clickedHeal = function()
	botGui.Enabled = false
	tempData.HealingTeamate = true
	MiscFunctions.removeObjects()
end

EventModule.clickedPlaceWall = function()
	tempData.placeingWall = true
	botGui.Enabled = false
	EventModule.placeWall()
end

EventModule.OpenBunker = function()
	if tempData.characterHighlight and tempData.characterHighlight.Parent.Name == "Door Closed" then
		NPCEvents.PlantBomb:FireServer(mouse.Hit.Position, tempData.Target, tempData.characterHighlight.Parent)
		MiscFunctions.unselect()
		return true
	end
	return false
end

EventModule.clickNewEnemy = function(input)
	if tempData.characterHighlight and tempData.characterHighlight.Parent.Parent.Name == "Targets" then
		NPCEvents.NewTarget:FireServer(tempData.characterHighlight.Parent, tempData.Target)
		MiscFunctions.removeObjects()
	end
end

EventModule.MoveTo = function()
	if tempData.Target and mouse.Target and tempData.newposition then
		move:FireServer(tempData.newposition, tempData.Target, createEffects.makeHologram(tempData.newposition))
		MiscFunctions.unselect()
	end
end

EventModule.hoverHealableWho = function()
	if MiscFunctions.isMyNPC(mouse.Target.Parent) then
		heal:FireServer(tempData.Target, mouse.Target.Parent)
		MiscFunctions.unselect()
	end
end

return EventModule
