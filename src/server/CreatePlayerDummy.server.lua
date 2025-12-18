--!nocheck
--// Services
local Players = game:GetService("Players")

--// Local Functions
local function playAimation(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local kickAnimation = Instance.new("Animation")
	kickAnimation.AnimationId = "rbxassetid://125777469610384"

	local kickAnimationTrack = animator:LoadAnimation(kickAnimation)

	kickAnimationTrack:Play()
end

local function PlayerTeam(player)
	if player.Team.Name == "TeamOne" then
		local char = game:WaitForChild("Players"):CreateHumanoidModelFromUserId(player.UserId)
		for _, part in pairs(char:GetChildren()) do
			if not part:IsA("BasePart") and part.Name ~= char.Humanoid.Name then
				local leader = workspace.Map.bunkerOne.leader
				part.Parent = leader
				playAimation(leader)
				workspace.Map.bunkerOne:AddTag(player.UserId)
			end
		end
	elseif player.Team.Name == "TeamTwo" then
		local char = game:WaitForChild("Players"):CreateHumanoidModelFromUserId(player.UserId)
		for _, part in pairs(char:GetChildren()) do
			if not part:IsA("BasePart") and part.Name ~= char.Humanoid.Name then
				local leader = workspace.Map.bunkerTwo.leader
				part.Parent = leader
				playAimation(leader)
				workspace.Map.bunkerTwo:AddTag(player.UserId)
			end
		end
	end
end

--//Events
Players.PlayerAdded:Connect(PlayerTeam)
