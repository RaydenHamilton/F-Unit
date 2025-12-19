--!strict
--// Services
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local soldierAnimation = require(script.Parent.soldierAnimationController)
local soldierEffects = require(script.Parent.soldierEffects)
local SoldierEvents = require(script.Parent.SoldierEvents)
local nameModule = require(script.Parent.NameModule)
local deathModule = require(script.Parent.DeathModule)
local SoldierClass = require(game.ServerStorage.SoldierClass)

--// Type Declarations
type SoldierData = SoldierClass.SoldierData

--// Models or Folders
local NPCEvents = ReplicatedStorage.NPCEvents

--// Main Module
local SoldierModule = {
	Pose = {
		Standing = "Standing",
		Crawling = "Crawling",
		Crewching = "Crewching",
	},
	Path = PathfindingService:CreatePath({
		AgentCanJump = false,
		AgentRadius = 1.7,
		WaypointSpacing = 1,
		Costs = { Center = 0.1 },
	}),
}

--// Data Table
local AllSoldiers = {}

--// Local Functions
local function DealDamage(hit: BasePart | any, soldierData: SoldierData)
	if not hit or hit:IsA("BasePart") then
		return
	end
	if hit.Name ~= "HumanoidRootPart" and hit.Parent:findFirstChildOfClass("Humanoid") ~= nil then
		hit.Parent.Humanoid:TakeDamage(soldierData.Class.Damage)
	elseif hit.Name == "Sandbag" then
		hit.Parent.Value.Value -= soldierData.Class.Damage
		local model = hit.Parent
		while soldierData.Class.Damage * #model:GetChildren() > model.Value.Value and model do
			local highest: MeshPart?
			for i, v in pairs(model:GetChildren()) do
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
end

local function Reload(soldierData: SoldierData)
	soldierData.Shots += 1
	if soldierData.Shots >= soldierData.Class.ClipSize then
		if soldierData.Soldier:GetAttribute("Covering") and not soldierAnimation.isRunning(soldierData) then
			-- cover
			soldierData.State = soldierAnimation.PlayAnim(10, soldierData.Humanoid, soldierData.Loaded)
		end
		soldierData.Shots = 0
		local playTime = soldierData.Loaded[11].Length / soldierData.Class.ReloadTime
		soldierData.Loaded[11]:Play()
		soldierData.Loaded[11]:AdjustSpeed(playTime)
		task.wait(soldierData.Class.ReloadTime)
	end
	task.wait(soldierData.Class["FiringRate"])
	soldierData.Soldier:SetAttribute("GunCoolDown", false)
end

local function FireGun(soldierData: SoldierData)
	if not soldierAnimation.isFiring(soldierData) then
		--soldierData.State = soldierAnimation.PlayAnim(firing,soldierData.Soldier.Humanoid,soldierData.Loaded)
		soldierData.LaststateChange = tick()
		soldierEffects.AngleArms(soldierData)
	end
	if tick() - soldierData.LaststateChange > 0.5 then
		soldierData.Soldier:SetAttribute("GunCoolDown", true)
		local enemyPosition: Vector3 = soldierData.ClosesEnemy.HumanoidRootPart.Position
		local NPCPosition: Vector3 = soldierData.HumanoidRootPart.Position
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
			math.random(-enemyMagnitude, enemyMagnitude) * soldierData.Class.Bloom,
			math.random(-enemyMagnitude, enemyMagnitude) * soldierData.Class.Bloom,
			math.random(-enemyMagnitude, enemyMagnitude) * soldierData.Class.Bloom
		)

		local origin: Vector3 = NPCPosition + Vector3.new(0, 1, 0)
		local lookAt: Vector3 = soldierData.HumanoidRootPart.CFrame.LookVector
			+ aimAt * soldierData.Class.Range
			+ offset

		local raycastData: RaycastResult = game.Workspace:Raycast(origin, lookAt, soldierData.ShotRules)
		soldierEffects.AngleArms(soldierData)
		if raycastData then
			DealDamage(raycastData.Instance, soldierData)
			soldierEffects.Bullet(soldierData.Soldier:WaitForChild("Handle") :: Part, lookAt, raycastData.Distance)
		else
			soldierEffects.Bullet(soldierData.Soldier:WaitForChild("Handle") :: Part, lookAt, math.huge)
		end

		coroutine.resume(coroutine.create(function()
			soldierEffects.GunEffects(soldierData)
		end))

		Reload(soldierData)
	end
end

local function CanFireAt(soldierData: SoldierData) -- shoots as long as there is no cool down
	if not soldierData.Soldier:GetAttribute("GunCoolDown") and soldierData.LastEnemieSet - tick() < 0 then
		soldierData.DistanceToCloses = (
			soldierData.ClosesEnemy.HumanoidRootPart.Position - soldierData.HumanoidRootPart.Position
		).Magnitude
		if soldierData.DistanceToCloses <= soldierData.Class.Range then
			FireGun(soldierData) -- only trigers when when fires
		end
	end
end

local function notIsEnemieTargetAvalable(soldierData: SoldierData)
	return not soldierData.ClosesEnemy
		or not soldierData.ClosesEnemy.Parent
		or soldierData.ClosesEnemy.Humanoid.Health <= 0
		or (soldierData.ClosesEnemy.PrimaryPart.Position - soldierData.HumanoidRootPart.Position).Magnitude
			>= soldierData.Class.Range
end

local function isAnEnemie(soldierData: SoldierData, enemys)
	return enemys:GetAttribute("Owner") ~= soldierData.Owner
		and enemys.Parent
		and enemys.PrimaryPart
		and enemys.PrimaryPart.Position
end

local function isBestNewTraget(soldierData: SoldierData, enemys: SoldierData)
	return (
		not soldierData.ClosesEnemy
		or not soldierData.ClosesEnemy.Parent
		or (soldierData.ClosesEnemy.PrimaryPart.Position - soldierData.HumanoidRootPart.Position).Magnitude
			> (enemys.HumanoidRootPart.Position - soldierData.HumanoidRootPart.Position).Magnitude
	) -- if it is the closest
		and enemys.Humanoid -- has Humanoid
		and enemys.Humanoid.Health > 0 -- health above 0
		and soldierData.HumanoidRootPart
		and (enemys.HumanoidRootPart.Position - soldierData.HumanoidRootPart.Position).Magnitude
			<= soldierData.Class.Range
end

local function GetNewEnemy(soldierData: SoldierData) -- gets a new enamy if it is needed
	if notIsEnemieTargetAvalable(soldierData) then -- seeing if they need a new target
		soldierData.ClosesEnemy = nil
		for i, enemys in pairs(game.Workspace.Targets:GetChildren()) do --looks at all avalabe targets
			if isAnEnemie(soldierData, enemys) then -- makes sure they are not that same team
				if isBestNewTraget(soldierData, enemys) then -- makes sure they are alowed to be shot at
					soldierData.ClosesEnemy = enemys
					soldierData.LastEnemieSet = tick() + math.random(0, 17) / 10
					soldierData.ClosesHumanoid = soldierData.ClosesEnemy.Humanoid
				else
					if
						not soldierData.Soldier:GetAttribute("Covering")
						and not soldierAnimation.isRunning(soldierData)
					then
						(soldierData.Soldier:WaitForChild("Hammer") :: Part).Transparency = 1
						(soldierData.Soldier:WaitForChild("Handle") :: Part).Transparency = 0
					end
				end
			end
		end
	end
end

local function LookAtEnemy(soldierData: SoldierData) -- lookats enemy
	if
		soldierData.ClosesEnemy
		and soldierData.ClosesEnemy.Parent
		and soldierData.ClosesEnemy.PrimaryPart.Position ~= nil
		and not ((soldierData.HumanoidRootPart.Position - soldierData.Humanoid.WalkToPoint).Magnitude > 4) -- makes sure they move before they shoot
		and soldierData.Humanoid.Health > 0
		and soldierData.ClosesEnemy.HumanoidRootPart
		and soldierData.ClosesEnemy.Humanoid.Health > 0
	then
		if #soldierData.StateQueue == 0 and tick() - soldierData.LaststateChange > 0.3 then
			soldierData.Soldier:PivotTo(
				soldierData.HumanoidRootPart.CFrame:Lerp(
					CFrame.new(
						soldierData.HumanoidRootPart.Position,
						Vector3.new(
							soldierData.ClosesEnemy.Torso.Position.X,
							soldierData.HumanoidRootPart.Position.Y,
							soldierData.ClosesEnemy.Torso.Position.Z
						)
					),
					0.15
				)
			)
			CanFireAt(soldierData)
		end
	end
end

local function CanShootEnemy(soldierData: SoldierData)
	if
		soldierData.State.Name ~= soldierAnimation.Animation.Reloading and not soldierAnimation.isRunning(soldierData)
	then
		if
			not soldierData.Soldier:GetAttribute("Building")
			and not soldierData.Soldier:GetAttribute("Healing")
			and not soldierData.Soldier:GetAttribute("PlantingBomb")
		then
			GetNewEnemy(soldierData)
			LookAtEnemy(soldierData)
		elseif
			soldierData.Soldier:GetAttribute("Building")
			or soldierData.Soldier:GetAttribute("Healing")
			or soldierData.Soldier:GetAttribute("PlantingBomb")
		then
			SoldierEvents.SetPose(nil, soldierData.Soldier:GetAttribute("Pose"), soldierData.Soldier, soldierData)
		end
	end
end

local function CreateRaycastPrams(soldier)
	local ShotRules = RaycastParams.new()
	ShotRules.FilterDescendantsInstances = {
		soldier,
	}
	ShotRules.FilterType = Enum.RaycastFilterType.Exclude
	ShotRules.IgnoreWater = true
	return ShotRules
end

--// Module Functions
function SoldierModule.new(id: number, soldier: Model, class)
	local self = {
		---userID---
		Owner = id,
		Name = nameModule.name(),
		---Class---
		Class = class,
		---Invrntory---
		Inventory = {
			Meds = 2,
			Walls = 5,
		},
		---varuables---
		Shots = 0,
		LaststateChange = tick(),
		StateQueue = {},

		LeftShoulder = (soldier:WaitForChild("Torso"):WaitForChild("Left Shoulder") :: Motor6D).C1 :: CFrame,
		RightShoulder = (soldier:WaitForChild("Torso"):WaitForChild("Right Shoulder") :: Motor6D).C1 :: CFrame,
		Soldier = soldier,
		Humanoid = soldier:WaitForChild("Humanoid") :: Humanoid,
		HumanoidRootPart = soldier.PrimaryPart :: BasePart,
		LastEnemieSet = 0,
		ShotRules = CreateRaycastPrams(soldier),
		Loaded = soldierAnimation.LoadAnimation(soldier:WaitForChild("Humanoid") :: Humanoid),
		path = SoldierModule.Path,
	} :: SoldierData
	--Data Init---
	soldier:SetAttribute("Pose", "Stand")
	soldier:SetAttribute("Owner", id)
	---Controls---
	soldier:SetAttribute("Covering", false)
	soldier:SetAttribute("Building", false)
	soldier:SetAttribute("Healing", false)
	soldier:SetAttribute("StopWalking", false)
	soldier:SetAttribute("GunCoolDown", false)
	soldier:SetAttribute("PlantingBomb", false)
	soldier:SetAttribute("Meds", 5)
	soldier:SetAttribute("Walls", 5)
	soldier:SetAttribute("Range", class.Range)

	self.HumanoidRootPart:SetNetworkOwner(nil)

	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.Humanoid.AutoRotate = true

	soldierAnimation.SetState(0, self)

	self.Connections = {

		self.Humanoid.Running:Connect(function(speed: number)
			soldierAnimation.SetState(speed, self)
		end),

		RunService.Heartbeat:Connect(function()
			CanShootEnemy(self)
		end),

		self.Humanoid.Died:Connect(function()
			deathModule.PlayDeath(self)
			SoldierModule[self.Soldier] = nil
		end),
		---Events---
		NPCEvents.Move.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			table.insert(args, self)
			SoldierEvents.OnMoveTo(table.unpack(args))
		end),

		NPCEvents.NewTarget.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			if ... then
				table.insert(args, self)
				SoldierEvents.setClosesEnemy(table.unpack(args))
			end
		end),

		NPCEvents.PlaceObject.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			table.insert(args, self)
			SoldierEvents.MakeWall(table.unpack(args))
		end),

		NPCEvents.Heal.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			table.insert(args, self)
			SoldierEvents.healCharacter(table.unpack(args))
		end),
		NPCEvents.PlantBomb.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			table.insert(args, self)
			SoldierEvents.PlantBomb(table.unpack(args))
		end),
		NPCEvents.SetPose.OnServerEvent:Connect(function(...)
			local args = table.pack(...)
			table.insert(args, self)
			SoldierEvents.SetPose(table.unpack(args))
		end),
	}

	AllSoldiers[self.Soldier] = self
end

return SoldierModule
