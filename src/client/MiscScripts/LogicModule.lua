local LogicModule = {}

local tempData = require(script.Parent.TempData)
local miscFunctions = require(script.Parent.MiscFunctions)
local createInstances = require(script.Parent.CreateInstances)
local createEffects = require(script.Parent.CreateEffects)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

LogicModule.canWalkTo = function(input)
	if
		input.UserInputType == Enum.UserInputType.MouseMovement
		and tempData.Target
		and tempData.Target:FindFirstChild("Underlay")
	then
		if tempData.whatStepIsItOn > tempData.maxSteps then
			miscFunctions.restStep(50)
		end
		local position = mouse.Hit.Position + Vector3.new(tempData.stepX, 0, tempData.stepY)
		tempData.newposition = LogicModule.createwalkpart(position)
		if tempData.newposition then
			createEffects.makeHologram(tempData.newposition)
			miscFunctions.restStep(50)
		else
			miscFunctions.incrementStep()
		end
	end
end

LogicModule.createwalkpart = function(position)
	local path = game:GetService("PathfindingService")
		:CreatePath({ AgentCanJump = false, AgentRadius = 1.7, WaypointSpacing = 1, Costs = { Center = 0.1 } }) --
	if (position - tempData.Target["Underlay"].Position).magnitude < 999 then
		path:ComputeAsync(tempData.Target["Underlay"].Position, position)
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

return LogicModule
