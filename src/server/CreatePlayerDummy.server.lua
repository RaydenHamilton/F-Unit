--!nocheck
--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
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
	local char = Players:CreateHumanoidModelFromUserId(player.UserId) or nil
	local bunker
	if player.Team.Name == "TeamOne" then
		bunker = Workspace.Map.bunkerOne
	elseif player.Team.Name == "TeamTwo" then
		bunker = Workspace.Map.bunkerTwo
	end

	local leader = bunker.leader
	bunker:SetAttribute("Owner", player.UserId)
	for _, part in pairs(char:GetChildren()) do
		if not part:IsA("BasePart") and part.Name ~= "Humanoid" then
			part.Parent = leader
			playAimation(leader)
		end
	end
end

--//Events
Players.PlayerAdded:Connect(PlayerTeam)
