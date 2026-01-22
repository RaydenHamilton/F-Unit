--!strict
--// Services
local ContentProvider = game:GetService("ContentProvider")

--// Module
local soldierAnimation = {
	Animation = {
		IdleStanding = "rbxassetid://10172777333",
		FiringStanding = "rbxassetid://10385765629",
		RunningStanding = "rbxassetid://10394898042",

		IdleCrouching = "rbxassetid://77138088347297",
		FiringCrouching = "rbxassetid://116065686266822",
		RunningCrouching = "rbxassetid://111502810518182",

		IdleCrawling = "rbxassetid://75330057320090",
		FiringCrawling = "rbxassetid://92830411405006",
		RunningCrawling = "rbxassetid://82403020038662",

		Hiding = "rbxassetid://10381835217",
		Reloading = "rbxassetid://93988191304542",
		Hammering = "rbxassetid://81967592746511",
	},
}
soldierAnimation.__index = soldierAnimation
function soldierAnimation.new(soldier)
	local self = setmetatable({}, soldierAnimation)
	self.Soldier = soldier
	return self
end

--// Module Functions
function soldierAnimation:LoadAnimation()
	local animator = self.Soldier.Humanoid:WaitForChild("Animator")

	local anim = {
		-- standing
		soldierAnimation.Animation["IdleStanding"], --1 idle
		soldierAnimation.Animation["FiringStanding"], --2 firing
		soldierAnimation.Animation["RunningStanding"], --3 Walking
		-- crouching
		soldierAnimation.Animation["IdleCrouching"], --1 idle
		soldierAnimation.Animation["FiringCrouching"], --2 firing
		soldierAnimation.Animation["RunningCrouching"], -- 3 crouch walking
		-- crawling
		soldierAnimation.Animation["IdleCrawling"], --1 idle
		soldierAnimation.Animation["FiringCrawling"], --2 firing
		soldierAnimation.Animation["RunningCrawling"], --3 crawling
		-- other
		soldierAnimation.Animation.Hiding, --10 Hiding
		soldierAnimation.Animation.Reloading, --11 Reload
		soldierAnimation.Animation.Hammering, --12 Hammering
	}
	local loaded = {}

	for i, v in pairs(anim) do
		local Animation = Instance.new("Animation")
		Animation.AnimationId = v
		local AnimationTrack = animator:LoadAnimation(Animation)
		AnimationTrack.Priority = Enum.AnimationPriority.Action
		AnimationTrack.Name = v
		if i ~= 11 then
			AnimationTrack.Looped = true
		else
			AnimationTrack.Looped = false
		end
		table.insert(loaded, AnimationTrack)
	end
	ContentProvider:PreloadAsync(loaded)
	return loaded
end

function soldierAnimation:PlayAnim(number: number)
	for _, v in pairs(self.Soldier.Humanoid:GetPlayingAnimationTracks()) do
		if v.Name ~= self.Soldier.Loaded[number].Name then
			v:Stop()
		else
			return self.Soldier.Loaded[number]
		end
	end
	self.Soldier.Loaded[number]:Play()
	return self.Soldier.Loaded[number]
end

function soldierAnimation:SetState(Speed: number)
	local character = self.Soldier.Character
	local rightShoulder = character:WaitForChild("Torso"):WaitForChild("Right Shoulder") :: Motor6D
	local leftShoulder = character:WaitForChild("Torso"):WaitForChild("Left Shoulder") :: Motor6D

	local LiveSpeed = Speed
	local timeStart = tick()

	self.Soldier.StateQueue[#self.Soldier.StateQueue + 1] = LiveSpeed
	repeat
		task.wait()
	until (
			self.Soldier.StateQueue[#self.Soldier.StateQueue] == LiveSpeed
			and tick() * 10 > math.ceil(timeStart * 10)
		) or tick() - timeStart > 3
	if tick() - timeStart > 2 then
		return
	end
	rightShoulder.C1 = self.Soldier.RightShoulder
	leftShoulder.C1 = self.Soldier.LeftShoulder

	local state = 0
	local humanoid: Humanoid = self.Soldier.Humanoid
	if character:GetAttribute("Pose") == "Stand" then
		state += 0
		humanoid.WalkSpeed = 16
	elseif character:GetAttribute("Pose") == "Crawl" then
		state += 6
		humanoid.WalkSpeed = 4
	elseif character:GetAttribute("Pose") == "Crouch" then
		state += 3
		humanoid.WalkSpeed = 5
	end

	if self.Soldier.StateQueue[#self.Soldier.StateQueue] == 0 then
		-- if character:GetAttribute("Covering") then
		-- 	state = 10 -- hiding
		if
			character:GetAttribute("Building")
			or character:GetAttribute("Healing")
			or character:GetAttribute("PlantingBomb")
		then
			state = 12 -- building
		elseif self.Soldier.ClosesEnemy then
			state += 2 -- targeting
		else
			self.Soldier.Humanoid:MoveTo(
				self.Soldier.HumanoidRootPart.Position + self.Soldier.Events:SoldierTooClose(4)
			)
			state += 1 -- idle
		end
	else
		state += 3 -- running
	end

	self.Soldier.State = self.Soldier.Animations:PlayAnim(state)

	if self.Soldier.StateQueue[#self.Soldier.StateQueue] == Speed then
		table.clear(self.Soldier.StateQueue)
		self.Soldier.LaststateChange = tick()
	end
end

function soldierAnimation:isRunning(): boolean
	return self.Soldier.State.Name == soldierAnimation.Animation["RunningCrawling"]
		or self.Soldier.State.Name == soldierAnimation.Animation["RunningStanding"]
		or self.Soldier.State.Name == soldierAnimation.Animation["RunningCrouching"]
end

function soldierAnimation:isFiring(): boolean
	return self.Soldier.State.Name == soldierAnimation.Animation["FiringCrawling"]
		or self.Soldier.State.Name == soldierAnimation.Animation["FiringStanding"]
		or self.Soldier.State.Name == soldierAnimation.Animation["FiringCrouching"]
end

function soldierAnimation:isIdle(): boolean
	return self.Soldier.State.Name == soldierAnimation.Animation["IdleCrawling"]
		or self.Soldier.State.Name == soldierAnimation.Animation["IdleStanding"]
		or self.Soldier.State.Name == soldierAnimation.Animation["IdleCrouching"]
end

return soldierAnimation
