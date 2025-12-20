local LogicModule = {}

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local player = Players.LocalPlayer
local client = player.PlayerScripts.Client
local mouse = player:GetMouse()
local Target = ReplicatedStorage.States.Target

--// Modules
local ClientStates = require(client.ClientStates)
local miscFunctions = require(client.MiscFunctions)
local createEffects = require(client.CreateEffects)
-- local createInstances = require(script.Parent.CreateInstances)

--// Module Functions

LogicModule.createwalkpart = function(position)
	local path = game:GetService("PathfindingService")
		:CreatePath({ AgentCanJump = false, AgentRadius = 1.7, WaypointSpacing = 1, Costs = { Center = 0.1 } }) --
	if (position - Target.Value["Underlay"].Position).magnitude < 999 then
		path:ComputeAsync(Target.Value["Underlay"].Position, position)
		local waypoints = path:GetWaypoints()
		if path.Status == Enum.PathStatus.Success then
			return waypoints[#waypoints].Position
		else
			return false
		end
	else
		miscFunctions.removeObjects()
		return false
	end
end

LogicModule.SetHologram = function()
	if Target.Value and Target.Value:FindFirstChild("Underlay") then
		if ClientStates.whatStepIsItOn > ClientStates.maxSteps then
			miscFunctions.restStep(50)
		end
		local position = mouse.Hit.Position + Vector3.new(ClientStates.stepX, 0, ClientStates.stepY)
		ClientStates.newposition = LogicModule.createwalkpart(position)
		if ClientStates.newposition then
			createEffects.makeHologram(ClientStates.newposition)
			miscFunctions.restStep(50)
		else
			miscFunctions.incrementStep()
		end
	end
end

return LogicModule
