--!nocheck
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// Variables
local targets = Workspace.Targets
local player = Players.LocalPlayer.UserId

function CharterAdded(soldier: Model)
	local owner = soldier:GetAttribute("Owner")
	if owner ~= player then
		soldier:WaitForChild("Underlay"):Destroy()
		return
	end
	local ShotRules = RaycastParams.new()
	ShotRules.FilterDescendantsInstances = {
		soldier,
	}
	ShotRules.FilterType = Enum.RaycastFilterType.Exclude
	ShotRules.IgnoreWater = true

	repeat
		task.wait()
	until soldier:FindFirstChild("Underlay")
	local setUnderlay
	setUnderlay = game:GetService("RunService").RenderStepped:Connect(function()
		if soldier:FindFirstChild("Head") then
			local pass = pcall(function()
				local raycastResult =
					workspace:Raycast(soldier.PrimaryPart.Position, Vector3.new(0, -9999999, 0), ShotRules)
				if raycastResult then
					soldier.Underlay.CFrame = CFrame.new(
						raycastResult.Position + Vector3.new(0.001),
						(raycastResult.Position + Vector3.new(0.001)) + raycastResult.Normal
					) * CFrame.Angles(math.rad(-90), 0, math.rad(-0))
				end
			end)

			if not pass then
				setUnderlay:Disconnect()
			end
		end
	end)
	local OnDeath
	OnDeath = soldier.Humanoid.Died:Connect(function()
		setUnderlay:Disconnect()
		OnDeath:Disconnect()
	end)
end

for _, character in pairs(targets:GetChildren()) do
	CharterAdded(character)
end

targets.ChildAdded:Connect(CharterAdded)

for _, v in pairs(game.StarterGui:GetChildren()) do
	v.Parent = game.Players.LocalPlayer.PlayerGui
end
