--// Services
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

--// Modules
local Animations = require(script.Parent.Animations)
local Effects = require(script.Parent.Effects)
local Events = require(script.Parent.Events)
local Names = require(script.Parent.Names)
local Deaths = require(script.Parent.Deaths)

--// Main Module
local Soldier = {
	Pose = {
		Standing = "Standing",
		Crawling = "Crawling",
		Crewching = "Crewching",
	},
}

Soldier.__index = Soldier

--// Module Functions
function Soldier.new(userID: number, soldier, class)
	local self = setmetatable({
		---userID---
		Owner = userID,
		Name = Names.name(),
		---Class---
		Class = class,
		---varuables---
		Shots = 0,
		LaststateChange = tick(),
		StateQueue = {},
		LeftShoulder = (soldier:WaitForChild("Torso"):WaitForChild("Left Shoulder") :: Motor6D).C1 :: CFrame,
		RightShoulder = (soldier:WaitForChild("Torso"):WaitForChild("Right Shoulder") :: Motor6D).C1 :: CFrame,
		Character = soldier,
		Humanoid = soldier:WaitForChild("Humanoid") :: Humanoid,
		HumanoidRootPart = soldier.PrimaryPart :: BasePart,
		LastEnemieSet = 0,
		Path = PathfindingService:CreatePath({
			AgentCanJump = false,
			AgentRadius = 1.7,
			WaypointSpacing = 1,
			Costs = { Center = 0.1 },
		}),
	}, Soldier)
	soldier:SetAttribute("Pose", "Stand")
	soldier:SetAttribute("Owner", userID)
	soldier:SetAttribute("Covering", false)
	soldier:SetAttribute("Building", false)
	soldier:SetAttribute("Healing", false)
	soldier:SetAttribute("StopWalking", false)
	soldier:SetAttribute("GunCoolDown", false)
	soldier:SetAttribute("PlantingBomb", false)
	soldier:SetAttribute("Meds", 5)
	soldier:SetAttribute("Walls", 5)
	soldier:SetAttribute("Range", class.Range)

	--// Setup \\--
	self.Animations = Animations.new(self)
	self.Death = Deaths.new(self)
	self.Events = Events.new(self)
	self.Effects = Effects.new(self)

	--// Calls \\--
	self.Humanoid.AutoRotate = true
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.ShotRules = self:CreateRaycastPrams()
	self.HumanoidRootPart:SetNetworkOwner(nil)
	self.Loaded = self.Animations:LoadAnimation()
	self.Animations:SetState(0)

	--// Connections \\--
	self.Connections = {
		self.Humanoid.Running:Connect(function(speed: number)
			self.Animations:SetState(speed)
		end),
		self.Humanoid.Died:Connect(function()
			self.Death:PlayDeath()
		end),
		RunService.Heartbeat:Connect(function()
			self:CanShootEnemy()
		end),
	}
	return self
end

--// Local Functions
function Soldier:DamageSandBags(hit)
	hit.Parent.Value.Value -= self.Class.Damage
	local model = hit.Parent
	while self.Class.Damage * #model:GetChildren() > model.Value.Value and model do
		local highest: MeshPart?
		for _, v in pairs(model:GetChildren()) do
			if v:IsA("MeshPart") and (not highest or v.Position.Y > highest.Position.Y) then
				highest = v
			end
		end
		if highest then
			highest:Destroy()
			highest = nil
		end
	end
	if model.Value.Value < 1 then
		hit.Parent.Parent:Destroy()
	end
end

function Soldier:DealDamage(hit: BasePart | any)
	if not hit then
		return
	end
	local Humanoid = hit.Parent:FindFirstChild("Humanoid")
	--// hit player
	if hit.Name ~= "HumanoidRootPart" and Humanoid then
		Humanoid:TakeDamage(self.Class.Damage)
	--// hit sand bag
	elseif hit.Name == "Sandbag" then
		self:DamageSandBags(hit)
	end
end

function Soldier:Reload()
	self.Shots += 1
	if self.Shots >= self.Class.ClipSize then
		if self.Character:GetAttribute("Covering") and not self.Animations:isRunning() then
			-- cover
			self.State = self.Animations:PlayAnim(10)
		end
		self.Shots = 0
		local playTime = self.Loaded[11].Length / self.Class.ReloadTime
		self.Loaded[11]:Play()
		self.Loaded[11]:AdjustSpeed(playTime)
		task.wait(self.Class.ReloadTime)
	end
	task.wait(self.Class["FiringRate"])
	self.Character:SetAttribute("GunCoolDown", false)
end

function Soldier:FireGun()
	if not self.Animations:isFiring() then
		self.LaststateChange = tick()
		self.Effects:AngleArms()
		self.Animations:SetState(0)
	end
	if tick() - self.LaststateChange > 0.5 then
		self.Character:SetAttribute("GunCoolDown", true)
		local enemyPosition: Vector3 = self.ClosesEnemy.HumanoidRootPart.Position
		local NPCPosition: Vector3 = self.HumanoidRootPart.Position
		local enemyMagnitude = (Vector3.new(enemyPosition.X, enemyPosition.Y, enemyPosition.Z) - Vector3.new(
			NPCPosition.X,
			NPCPosition.Y,
			NPCPosition.Z
		)).Magnitude
		local aimAt = Vector3.new(
			enemyPosition.X - NPCPosition.X,
			enemyPosition.Y - NPCPosition.Y,
			enemyPosition.Z - NPCPosition.Z
		)
		local offset = Vector3.new(
			math.random(-enemyMagnitude, enemyMagnitude) * self.Class.Bloom,
			math.random(-enemyMagnitude, enemyMagnitude) * self.Class.Bloom,
			math.random(-enemyMagnitude, enemyMagnitude) * self.Class.Bloom
		)

		local origin: Vector3 = NPCPosition + Vector3.new(0, 1, 0)
		local lookAt: Vector3 = self.HumanoidRootPart.CFrame.LookVector + aimAt * self.Class.Range + offset

		local raycastData: RaycastResult = Workspace:Raycast(origin, lookAt, self.ShotRules)
		self.Effects:AngleArms()
		if raycastData then
			self:DealDamage(raycastData.Instance)
			self.Effects:Bullet(self.Character:WaitForChild("Handle") :: Part, lookAt, raycastData.Distance)
		else
			self.Effects:Bullet(self.Character:WaitForChild("Handle") :: Part, lookAt, math.huge)
		end

		coroutine.resume(coroutine.create(function()
			self.Soldier.Events:GunEffects(self)
		end))

		self:Reload()
	end
end

function Soldier:CanFireAt() -- shoots as long as there is no cool down
	if not self.Character:GetAttribute("GunCoolDown") and self.LastEnemieSet - tick() < 0 then
		self.DistanceToCloses = (self.ClosesEnemy.HumanoidRootPart.Position - self.HumanoidRootPart.Position).Magnitude
		if self.DistanceToCloses <= self.Class.Range then
			self:FireGun() -- only trigers when when fires
		end
	end
end

function Soldier:notIsEnemieTargetAvalable()
	return not self.ClosesEnemy
		or not self.ClosesEnemy.Parent
		or self.ClosesEnemy.Humanoid.Health <= 0
		or (self.ClosesEnemy.PrimaryPart.Position - self.HumanoidRootPart.Position).Magnitude >= self.Class.Range
end

function Soldier:isAnEnemie(enemys)
	return enemys:GetAttribute("Owner") ~= self.Owner
		and enemys.Parent
		and enemys.PrimaryPart
		and enemys.PrimaryPart.Position
end

function Soldier:isBestNewTraget(enemys)
	return (
		not self.ClosesEnemy
		or not self.ClosesEnemy.Parent
		or (self.ClosesEnemy.PrimaryPart.Position - self.HumanoidRootPart.Position).Magnitude
			> (enemys.HumanoidRootPart.Position - self.HumanoidRootPart.Position).Magnitude
	) -- if it is the closest
		and enemys.Humanoid -- has Humanoid
		and enemys.Humanoid.Health > 0 -- health above 0
		and self.HumanoidRootPart
		and (enemys.HumanoidRootPart.Position - self.HumanoidRootPart.Position).Magnitude <= self.Class.Range
end

function Soldier:GetNewEnemy() -- gets a new enamy if it is needed
	if self:notIsEnemieTargetAvalable() then -- seeing if they need a new target
		self.ClosesEnemy = nil
		for _, teams in pairs(Workspace.Targets:GetChildren()) do --looks at all avalabe targets
			if teams.Name ~= tostring(self.Character:GetAttribute("Owner")) then
				for _, enemy in pairs(teams:GetChildren()) do
					if self:isAnEnemie(enemy) then -- makes sure they are not that same team
						if self:isBestNewTraget(enemy) then -- makes sure they are alowed to be shot at
							self.ClosesEnemy = enemy
							self.LastEnemieSet = tick() + math.random(0, 17) / 10
							self.ClosesHumanoid = self.ClosesEnemy.Humanoid
						else
							if not self.Character:GetAttribute("Covering") and not self.Animations:isRunning() then
								(self.Character:WaitForChild("Hammer") :: Part).Transparency = 1
								(self.Character:WaitForChild("Handle") :: Part).Transparency = 0
							end
						end
					end
				end
			end
		end
	end
end

function Soldier:LookAtEnemy() -- lookats enemy
	if
		self.ClosesEnemy
		and self.ClosesEnemy.Parent
		and self.ClosesEnemy.PrimaryPart.Position ~= nil
		and not ((self.HumanoidRootPart.Position - self.Humanoid.WalkToPoint).Magnitude > 4) -- makes sure they move before they shoot
		and self.Humanoid.Health > 0
		and self.ClosesEnemy.HumanoidRootPart
		and self.ClosesEnemy.Humanoid.Health > 0
	then
		if #self.StateQueue == 0 and tick() - self.LaststateChange > 0.3 then
			self.Effects:SetUnderlay()
			self.Character:PivotTo(
				self.HumanoidRootPart.CFrame:Lerp(
					CFrame.new(
						self.HumanoidRootPart.Position,
						Vector3.new(
							self.ClosesEnemy.Torso.Position.X,
							self.HumanoidRootPart.Position.Y,
							self.ClosesEnemy.Torso.Position.Z
						)
					),
					0.15
				)
			)
			task.spawn(coroutine.create(function()
				self:CanFireAt()
			end))
		end
	end
end

function Soldier:CanShootEnemy()
	local character = self.Character
	if self.State.Name ~= Animations.Animation.Reloading and not self.Animations:isRunning() then
		if
			not character:GetAttribute("Building")
			and not character:GetAttribute("Healing")
			and not character:GetAttribute("PlantingBomb")
		then
			self:GetNewEnemy()
			self:LookAtEnemy()
			if self.ClosesEnemy == nil and self.Character:GetAttribute("Covering") then
				self.Animations:PlayAnim(10)
			end
		end
	end
end

function Soldier:CreateRaycastPrams()
	local ShotRules = RaycastParams.new()
	ShotRules.FilterDescendantsInstances = {
		self.Character,
	}
	ShotRules.FilterType = Enum.RaycastFilterType.Exclude
	ShotRules.IgnoreWater = true
	return ShotRules
end

return Soldier
