--!strict
--// Services
local ServerStorage = game:GetService("ServerStorage")

--// Modules
local SoldierClass = require(ServerStorage.SoldierClass)

--// Types
type SoldierData = SoldierClass.SoldierData

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
		Reloading = "rbxassetid://10444669194",
		Hammering = "rbxassetid://81967592746511",
	},
}

--// Module Functions
soldierAnimation.LoadAnimation = function(humaniod: Humanoid): {}
	local animator = humaniod:WaitForChild("Animator") :: Animator

	local CP = game:GetService("ContentProvider")
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
		end
		table.insert(loaded, AnimationTrack)
	end
	CP:PreloadAsync(loaded)
	return loaded
end

soldierAnimation.PlayAnim = function(number, NPChumanoid, loaded)
	for i, v in pairs(NPChumanoid:GetPlayingAnimationTracks()) do
		if v.Name ~= loaded[number].Name then
			v:Stop()
		else
			return loaded[number]
		end
	end
	loaded[number]:Play()
	return loaded[number]
end

soldierAnimation.SetState = function(Speed: number, soldierData: SoldierData)
	local rightShoulder = soldierData.Soldier:WaitForChild("Torso"):WaitForChild("Right Shoulder") :: Motor6D
	local leftShoulder = soldierData.Soldier:WaitForChild("Torso"):WaitForChild("Left Shoulder") :: Motor6D

	local LiveSpeed = Speed
	local timeStart = tick()

	soldierData.StateQueue[#soldierData.StateQueue + 1] = LiveSpeed
	repeat
		task.wait()
	until (soldierData.StateQueue[#soldierData.StateQueue] == LiveSpeed and tick() * 10 > math.ceil(timeStart * 10))
		or tick() - timeStart > 3
	if tick() - timeStart > 2 then
		return
	end
	rightShoulder.C1 = soldierData.RightShoulder
	leftShoulder.C1 = soldierData.LeftShoulder

	local state = 0
	local humanoid: Humanoid = soldierData.Humanoid

	if soldierData.Soldier:GetAttribute("Pose") == "Stand" then
		state += 0
		humanoid.WalkSpeed = 16
	elseif soldierData.Soldier:GetAttribute("Pose") == "Crawl" then
		state += 6
		humanoid.WalkSpeed = 4
	elseif soldierData.Soldier:GetAttribute("Pose") == "Crouch" then
		state += 3
		humanoid.WalkSpeed = 5
	end

	if soldierData.StateQueue[#soldierData.StateQueue] == 0 then
		if soldierData.Soldier:GetAttribute("Covering") then
			state = 10 -- hiding
		elseif
			soldierData.Soldier:GetAttribute("Building")
			or soldierData.Soldier:GetAttribute("Healing")
			or soldierData.Soldier:GetAttribute("PlantingBomb")
		then
			state = 12 -- building
		elseif soldierData.ClosesEnemy then
			state += 2 -- targeting
		else
			state += 1 -- idle
		end
	else
		state += 3 -- running
	end

	soldierData.State = soldierAnimation.PlayAnim(state, soldierData.Humanoid, soldierData.Loaded)

	if soldierData.StateQueue[#soldierData.StateQueue] == Speed then
		table.clear(soldierData.StateQueue)
		soldierData.LaststateChange = tick()
	end
end

soldierAnimation.isRunning = function(soldierData: SoldierData): boolean
	return soldierData.State.Name == soldierAnimation.Animation["RunningCrawling"]
		or soldierData.State.Name == soldierAnimation.Animation["RunningStanding"]
		or soldierData.State.Name == soldierAnimation.Animation["RunningCrouching"]
end

soldierAnimation.isFiring = function(soldierData: SoldierData): boolean
	return soldierData.State.Name == soldierAnimation.Animation["FiringCrawling"]
		or soldierData.State.Name == soldierAnimation.Animation["FiringStanding"]
		or soldierData.State.Name == soldierAnimation.Animation["FiringCrouching"]
end

soldierAnimation.isIdle = function(soldierData: SoldierData): boolean
	return soldierData.State.Name == soldierAnimation.Animation["IdleCrawling"]
		or soldierData.State.Name == soldierAnimation.Animation["IdleStanding"]
		or soldierData.State.Name == soldierAnimation.Animation["IdleCrouching"]
end

return soldierAnimation
