--!strict
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Variables
local targets = Workspace:WaitForChild("Targets")
local player = Players.LocalPlayer
local UserId = player.UserId
local frameCounter = 0
local ShotRules = RaycastParams.new()
ShotRules.FilterDescendantsInstances = {
	Workspace.Targets,
}
ShotRules.FilterType = Enum.RaycastFilterType.Exclude
ShotRules.IgnoreWater = true

--// Constants
local UNDERLAY_OFFSET = Vector3.new(0, 0.001, 0)
local UNDERLAY_ROTATION = CFrame.Angles(math.rad(-90), 0, 0)
local Ray_length = Vector3.new(0, -1000, 0)
local UPDATE_EVERY = 3 -- update every 2 frames

local Soldiers: { Model } = {}

--// Local Functions
local function SetsoldierUnderlay()
	for _, soldier: Model in pairs(Soldiers) do
		if not soldier.PrimaryPart or not soldier:FindFirstChild("Underlay") then
			continue
		end
		if soldier:FindFirstChild("Head") then
			pcall(function()
				local raycastResult = workspace:Raycast(soldier.PrimaryPart.Position, Ray_length, ShotRules)
				if raycastResult then
					soldier.Underlay.CFrame = CFrame.new(
						raycastResult.Position + UNDERLAY_OFFSET,
						(raycastResult.Position + UNDERLAY_OFFSET) + raycastResult.Normal
					) * UNDERLAY_ROTATION
				end
			end)
		end
	end
end

local function soldierUnderlay(soldier: Model)
	local owner = soldier:GetAttribute("Owner")
	if not owner or owner ~= UserId then
		local underlay = soldier:FindFirstChild("Underlay")
		if underlay then
			underlay:Destroy()
		end
		return
	end

	soldier:WaitForChild("Underlay", 5)
	table.insert(Soldiers, soldier)
end

for _, character in pairs(targets:GetChildren()) do
	soldierUnderlay(character)
end

RunService.Heartbeat:Connect(function()
	frameCounter += 1
	if frameCounter % UPDATE_EVERY == 0 then
		SetsoldierUnderlay()
	end
end)

--// add underlay to new soldiers
targets.ChildAdded:Connect(soldierUnderlay)
