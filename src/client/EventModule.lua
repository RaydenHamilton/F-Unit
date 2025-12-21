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
local Marker = ReplicatedStorage.States.Marker

--// Modules
local ClientStates = require(Client.ClientStates)
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
	setPose:FireServer("Crawl", Target.Value)
end

EventModule.crouch = function()
	setPose:FireServer("Crouch", Target.Value)
end

EventModule.stand = function()
	setPose:FireServer("Stand", Target.Value)
end

EventModule.placeWall = function()
	ClientStates.placeingWall = true
	local Walls = Target.Value:GetAttribute("Walls")
	if not Marker.Value then
		MiscFunctions.removeObjects()
		createInstances.setUpMarker(mouse)
		while ClientStates.placeingWall and task.wait() and Marker.Value do
			Marker.Value.Position = mouse.Hit.Position + Vector3.new(0, Marker.Value.Size.Y / 2, 0)
			if not MiscFunctions.MouseIsInregion() then
				Marker.Value.Color = Color3.new(1, 0, 0)
			else
				Marker.Value.Color = Color3.new(0, 0, 1)
			end
		end
	elseif not MiscFunctions.MouseIsInregion() then
		MiscFunctions.unselect()
	else
		if ClientStates.partStart then
			local size = math.round((Marker.Value.Size.Z / sandbag.Size.Z) / 0.6)
			local partEnd = mouse.Hit.Position
			if Marker.Value.Color == Color3.new(0, 0, 1) then
				placeObject:FireServer(
					size,
					ClientStates.partStart - Vector3.new(0, Marker.Value.Size.Y / 2, 0),
					partEnd,
					Target.Value
				)
			end
			MiscFunctions.unselect()
			return
		end
		local text = createInstances.makeBillboardGui()
		ClientStates.partStart = mouse.Hit.Position + Vector3.new(0, Marker.Value.Size.Y / 2, 0)
		while task.wait() and Marker.Value do
			if ClientStates.partStart then
				Marker.Value.CFrame = CFrame.lookAt(
					(ClientStates.partStart + mouse.Hit.Position) / 2 + Vector3.new(0, Marker.Value.Size.Y / 4, 0),
					mouse.Hit.Position + Vector3.new(0, Marker.Value.Size.Y / 2, 0)
				)
				Marker.Value.Size = Vector3.new(1, 3, (ClientStates.partStart - mouse.Hit.Position).Magnitude)
				text.Text = math.round((Marker.Value.Size.Z / sandbag.Size.Z) / 0.6)
				if
					math.round((Marker.Value.Size.Z / sandbag.Size.Z) / 0.6) > Walls
					or not MiscFunctions.MouseIsInregion()
				then
					Marker.Value.Color = Color3.new(1, 0, 0)
				else
					Marker.Value.Color = Color3.new(0, 0, 1)
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
	ClientStates.HealingTeamate = true
	MiscFunctions.removeObjects()
end

EventModule.clickedPlaceWall = function()
	ClientStates.placeingWall = true
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
		-- Makes them target the new enemy
		NPCEvents.NewTarget:FireServer(highlight.Value.Parent, Target.Value)
		MiscFunctions.removeObjects()
	end
end

EventModule.MoveTo = function()
	if Target.Value and mouse.Target and ClientStates.newposition then
		move:FireServer(ClientStates.newposition, Target.Value, createEffects.makeHologram(ClientStates.newposition))
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
