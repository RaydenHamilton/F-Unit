--!nocheck

local EventModule = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local sandbag = ReplicatedStorage.ReplicatedObjects.Sandbag
local player = Players.LocalPlayer
local NPCEvents = ReplicatedStorage.NPCEvents
local Client = player.PlayerScripts.Client
local highlight = ReplicatedStorage.States.Highlight
local Target = ReplicatedStorage.States.Target

--// Modules
local tempData = require(Client.TempData)
local MiscFunctions = require(Client.MiscFunctions)
local createInstances = require(Client.CreateInstances)
local createEffects = require(Client.CreateEffects)

-- Events
local placeObject = NPCEvents.PlaceObject
local move = NPCEvents.Move
local heal = NPCEvents.Heal
local setPose = ReplicatedStorage.NPCEvents.SetPose

local mouse = player:GetMouse()
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")

--// Module Functions
EventModule.crawl = function()
	setPose:FireServer("crawl", Target.Value)
end

EventModule.crouch = function()
	setPose:FireServer("crouch", Target.Value)
end

EventModule.stand = function()
	setPose:FireServer("stand", Target.Value)
end

EventModule.placeWall = function()
	tempData.placeingWall = true
	local Walls = Target.Value:GetAttribute("Walls")
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
					Target.Value
				)
			end
			MiscFunctions.unselect()
			return
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
	heal:FireServer(Target.Value, Target.Value)
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
	if highlight.Value and highlight.Value.Parent.Name == "Door Closed" then
		NPCEvents.PlantBomb:FireServer(mouse.Hit.Position, Target.Value, highlight.Value.Parent)
		MiscFunctions.unselect()
		return true
	end
	return false
end

EventModule.clickNewEnemy = function()
	if highlight.Value and highlight.Value.Parent.Parent.Name == "Targets" then
		NPCEvents.NewTarget:FireServer(highlight.Value.Parent, Target.Value)
		MiscFunctions.removeObjects()
	end
end

EventModule.MoveTo = function()
	if Target.Value and mouse.Target and tempData.newposition then
		move:FireServer(tempData.newposition, Target.Value, createEffects.makeHologram(tempData.newposition))
		MiscFunctions.unselect()
	end
end

EventModule.hoverHealableWho = function()
	if MiscFunctions.isMyNPC(mouse.Target.Parent) then
		heal:FireServer(Target.Value, mouse.Target.Parent)
		MiscFunctions.unselect()
	end
end

return EventModule
