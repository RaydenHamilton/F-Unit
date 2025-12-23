--// Module
local SoldierEvents = {}

--// Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Modules
local soldierAnimation = require(script.Parent.soldierAnimationController)
local SoldierPathFinding = require(script.Parent.SoldierPathFinding)

SoldierEvents.__index = SoldierEvents

function SoldierEvents.new(soldier)
	local self = setmetatable({}, SoldierEvents)
	self.Soldier = soldier
	return self
end

function SoldierEvents:MakeWall(_, size, partStart: Vector3, partEnd, selectedSoldier)
	local character = self.Soldier.Character
	local angle = Vector3.new(partStart.X - partEnd.X, partStart.Y - partEnd.Y, partStart.Z - partEnd.Z).Unit
		* ReplicatedStorage.ReplicatedObjects.Sandbag.Size.X
	if selectedSoldier == character and SoldierPathFinding.PathFiding(partStart + angle * 2, self.Soldier) then
		local hammer = character:WaitForChild("Hammer") :: BasePart

		local walls = character:GetAttribute("Walls") or 0
		character:SetAttribute("Walls", walls - size)
		character:SetAttribute("Covering", false)
		character:SetAttribute("Building", true)

		task.wait(0.5)
		self.Soldier.State = self.Animaton:PlayAnim(12)
		hammer.Transparency = 0
		hammer.Transparency = 1
		local model = Instance.new("Model")
		model.Parent = Workspace.Walls
		model.Name = "sandBagwall"
		for i = 0, size, 1 do
			local row = Instance.new("Model")
			row.Parent = model
			row.Name = "sandBagRow"
			local health = Instance.new("IntValue")
			health.Parent = row
			health.Value = 5000
			local maxhealth = Instance.new("IntValue")
			maxhealth.Parent = health
			maxhealth.Value = 5000
			maxhealth.Name = "maxhealth"
		end
		for v = 1, 6, 1 do
			local offset = math.random(-0.7, 0.7)
			for i = 0, size, 1 do
				if not character:GetAttribute("Building") then
					hammer.Transparency = 1
					hammer.Transparency = 0
					return
				end
				task.wait(1)

				local newSandbag = ReplicatedStorage.ReplicatedObjects.Sandbag:Clone()
				newSandbag.Parent = model:GetChildren()[i + 1]
				newSandbag.Position = partStart
					- angle * i
					+ Vector3.new(0, newSandbag.Size.Y * v * 0.75, 0)
					+ angle * offset
				newSandbag.Rotation = Vector3.new(0, math.random(1, 360), 0)
				newSandbag.Anchored = false
				task.wait(0.15)
				newSandbag.Anchored = true
				newSandbag.Position = newSandbag.Position - Vector3.new(0, newSandbag.Size.Y * 3 * 0.15, 0)
			end
		end
		character:SetAttribute("Building", false)
		hammer.Transparency = 1
		hammer.Transparency = 0
		local spos = self.Soldier.HumanoidRootPart.Position
		task.wait(0.1)
		local epos = self.Soldier.HumanoidRootPart.Position

		self.Soldier.Animtaion:SetState((spos - epos).Magnitude, self.Soldier)
	end
end

function SoldierEvents:OnMoveTo(_, moveToPosition, selectedSoldier, isCover: boolean)
	if selectedSoldier == self.Soldier.Character then
		if soldierAnimation.isRunning(self.Soldier) then
			self.Soldier.Character:SetAttribute("StopWalking", true)
		end
		repeat
			task.wait()
		until not self.Soldier.Character:GetAttribute("StopWalking")
		self.Soldier.Character:SetAttribute("Covering", isCover)
		self.Soldier.Event:PathFiding(moveToPosition, self.Soldier)
	end
end

function SoldierEvents:PlantBomb(_, Valut: Vector3, soldier: Model, doors: Model)
	local character = self.Soldier.Character
	if soldier == character and self.Soldier.Event:PathFiding(Valut, self.Soldier, 15) then
		character:SetAttribute("Covering", false)
		character:SetAttribute("Building", false)
		character:SetAttribute("PlantingBomb", false)

		for _ = 0, 15, 1 do
			if
				not self.Soldier.Character:GetAttribute("PlantingBomb")
				or (Valut - self.Soldier.HumanoidRootPart.Position).Magnitude > 15
			then
				return
			end
			task.wait(1)
		end
		self.Soldier.Character:SetAttribute("PlantingBomb", false)
		for _, child: Instance in pairs(doors:GetChildren()) do
			if child:IsA("BasePart") then
				local door: BasePart = child
				door.Transparency = 1
				door.CanCollide = false
				door.CanQuery = false
				door.CanTouch = false
			end
		end
		for i, child: Instance in pairs((doors.Parent :: Folder):FindFirstChild("Door Open"):GetChildren()) do
			if child:IsA("BasePart") then
				local door: BasePart = child
				door.Transparency = 0
			end
		end
		self.Soldier.State = self.Soldier.Animation:PlayAnim(12, self.Soldier.Humanoid, self.Soldier.Loaded)
		for _, v in pairs(Workspace.Targets:GetChildren()) do
			if v:GetAttribute("Owner") ~= self.Soldier.Owner then
				v.Humaniod.Health = 0
			end
		end
		--TODO make this work Does not work cuz i idiot
		-- make the guy kill the leader after the door opens
		--self.Soldier.ClosesEnemy = (doors.Parent :: Folder).leader
	end
end

function SoldierEvents:HealCharacter(_, selectedSoldier, addHealthTo: Model)
	local character = self.Soldier.Character
	if selectedSoldier == character then
		if addHealthTo == selectedSoldier then
			self.Soldier.State = self.Soldier.Animation.PlayAnim(12)
			self.Soldier.Character:SetAttribute("Healing", true)
			for _ = 0, 6, 1 do
				local OtherHumanoid = addHealthTo:WaitForChild("Humanoid") :: Humanoid
				if OtherHumanoid.MaxHealth == OtherHumanoid.Health then
					OtherHumanoid.Health += 10
					break
				end
				task.wait(1)
			end

			local meds = character:GetAttribute("Walls") or 0
			character:SetAttribute("Meds", meds - 1)

			local spos = self.Soldier.HumanoidRootPart.Position
			task.wait(0.1)
			local epos = self.Soldier.HumanoidRootPart.Position

			self.Soldier.Animation:SetState((spos - epos).Magnitude, self.Soldier)
		else
			if not addHealthTo.PrimaryPart then
				return
			end
			self.Soldier.Events:PathFiding(addHealthTo.PrimaryPart.Position, self.Soldier, 8)
			self.Soldier.State = self.Soldier.Animation:PlayAnim(12)
			character:SetAttribute("Healing", true)
			self.Soldier.Humanoid.WalkToPoint = self.Soldier.HumanoidRootPart.Position
			local OtherHumoid = addHealthTo:WaitForChild("Humanoid")

			for _ = 0, 6, 1 do
				if OtherHumoid.MaxHealth == OtherHumoid.Health then
					OtherHumoid.Health += 10
					break
				end
				task.wait(1)
			end
			local meds = character:GetAttribute("Walls") or 0
			character:SetAttribute("Meds", meds - 1)

			character:SetAttribute("Healing", false)

			local spos = self.Soldier.HumanoidRootPart.Position
			task.wait(0.1)
			local epos = self.Soldier.HumanoidRootPart.Position

			self.Soldier.Animation:SetState((spos - epos).Magnitude, self.Soldier)
		end
	end
end

function SoldierEvents:SetClosesEnemy(_, Target)
	self.Soldier.ClosesEnemy = Target
end

function SoldierEvents:SetPose(_, pose)
	self.Soldier.Character:SetAttribute("Pose", pose)

	local spos: Vector3 = self.Soldier.HumanoidRootPart.Position
	task.wait(0.1)
	local epos = self.Soldier.HumanoidRootPart.Position

	self.Soldier.Animation:SetState((spos - epos).Magnitude, self.Soldier)
end
function SoldierEvents:PathFiding(dest, magnitude)
	self.Soldier.Character:SetAttribute("Building", false)
	self.Soldier.Character:SetAttribute("Healing", false)
	self.Soldier.Character:SetAttribute("PlantingBomb", false)

	if dest then
		self.Soldier.Path:ComputeAsync(self.Soldier.Character.Underlay.Position, dest)
		if self.Soldier.Path.Status == Enum.PathStatus.Success then
			local waypoints = self.Soldier.Path:GetWaypoints()
			for index, point in ipairs(waypoints) do
				self.Soldier.Character.Humanoid:MoveTo(point.Position)
				-- Wait until the Soldier reaches the point or stop is triggered
				while (self.Soldier.Character.HumanoidRootPart.Position - point.Position).magnitude > 5 do
					if
						self.Soldier.stopWalking
						or (index == #waypoints and (self.Soldier.Character.HumanoidRootPart.Position - point.Position).magnitude <= 1)
						or (
							magnitude
							and (self.Soldier.Character.HumanoidRootPart.Position - dest).magnitude < magnitude
						)
					then
						if not self.Soldier.closesEnemy then
							self.Soldier.Character["Hammer"].Transparency = 1
							self.Soldier.Character["Handle"].Transparency = 0
						end
						return true
					end
					task.wait() -- Give some time for movement
				end
			end
		else
			warn("Pathfinding failed, recalculating...")
			return false
			-- Optional: Try again after a delay or find a new path
		end
	end
	return true
end

return SoldierEvents
