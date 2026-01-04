--!strict
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Variables
local camera = workspace.CurrentCamera
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

--// Local Functions
local function SetsoldierUnderlay()
	for _, soldier: Model in pairs(targets[player.UserId]:GetChildren()) do
		local underlay = soldier:FindFirstChild("Underlay") :: Part
		local rootpart = soldier:IsA("Model") and soldier.PrimaryPart :: Part
		if not rootpart or not underlay or not soldier:FindFirstChild("Head") then
			continue
		end
		local _, seeUnderlay = camera:WorldToScreenPoint(underlay.Position)
		local _, seeRootpart = camera:WorldToScreenPoint(rootpart.Position)
		if seeRootpart or seeUnderlay then
			pcall(function()
				local raycastResult = workspace:Raycast(rootpart.Position, Ray_length, ShotRules)
				if raycastResult then
					underlay.CFrame = CFrame.new(
						raycastResult.Position + UNDERLAY_OFFSET,
						(raycastResult.Position + UNDERLAY_OFFSET) + raycastResult.Normal
					) * UNDERLAY_ROTATION
				end
			end)
		end
	end
end

local function soldierUnderlay(soldier: Model)
	if soldier:IsA("Model") then
		if soldier.Parent.Name ~= tostring(UserId) then
			soldier:WaitForChild("Underlay"):Destroy()
			return
		end
	end
end

RunService.Heartbeat:Connect(function()
	frameCounter += 1
	if frameCounter % UPDATE_EVERY == 0 then
		SetsoldierUnderlay()
	end
end)

--// add underlay to new soldiers
targets.DescendantAdded:Connect(soldierUnderlay)
