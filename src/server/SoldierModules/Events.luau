--// Module
local Events = {}

--// Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

Events.__index = Events

function Events.new(soldier)
	local self = setmetatable({}, Events)
	self.Soldier = soldier
	return self
end

function Events:MakeWall(sizeOfWall, partStart: Vector3, partEnd)
	local character = self.Soldier.Character
	local angle = Vector3.new(partStart.X - partEnd.X, partStart.Y - partEnd.Y, partStart.Z - partEnd.Z).Unit
		* ReplicatedStorage.ReplicatedObjects.Sandbag.Size.X
	if self.Soldier.Events:PathFinding(partStart + angle * 2) then
		local hammer = character:WaitForChild("Hammer") :: BasePart
		local walls = character:GetAttribute("Walls") or 0
		character:SetAttribute("Walls", walls - sizeOfWall)
		character:SetAttribute("Covering", false)
		character:SetAttribute("Building", true)

		task.wait(0.5)
		self.Soldier.State = self.Soldier.Animations:PlayAnim(12)
		hammer.Transparency = 0
		hammer.Transparency = 1
		local model = Instance.new("Model")
		model.Parent = Workspace.Walls
		model.Name = "sandBagwall"
		for _ = 0, sizeOfWall, 1 do
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
			for i = 0, sizeOfWall, 1 do
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
		if character:GetAttribute("Building") then
			character:SetAttribute("Building", false)
			hammer.Transparency = 1
			hammer.Transparency = 0
			self.Soldier.Animations:SetState(0)
		end
	end
end

function Events:OnMoveTo(moveToPosition, isCover: boolean)
	local character = self.Soldier.Character
	if self.Soldier.Animations:isRunning() then
		self.Soldier.Character:SetAttribute("StopWalking", true)
		repeat
			task.wait()
		until not character:GetAttribute("StopWalking")
	end
	character:SetAttribute("Covering", isCover)
	self.Soldier.Events:PathFinding(moveToPosition)
end

function Events:PlantBomb(Valut: Vector3, doors)
	local character = self.Soldier.Character
	if self.Soldier.Event:PathFinding(Valut, 15) then
		character:SetAttribute("Covering", false)
		character:SetAttribute("Building", false)
		character:SetAttribute("PlantingBomb", false) -- fix?

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
		for _, child: Instance in pairs(doors.Parent["Door Open"]:GetChildren()) do
			if child:IsA("BasePart") then
				local door: BasePart = child
				door.Transparency = 0
			end
		end
		self.Soldier.State = self.Soldier.Animations:PlayAnim(12)
		--TODO make this work Does not work cuz i idiot
		-- make the guy kill the leader after the door opens
		--self.Soldier.ClosesEnemy = (doors.Parent :: Folder).leader
	end
end

function Events:HealCharacter(addHealthTo: Model)
	local character = self.Soldier.Character
	local meds = character:GetAttribute("Meds")
	local humanoid = addHealthTo:FindFirstChild("Humanoid")
	if
		not humanoid
		or meds <= 0
		or character:GetAttribute("Owner") ~= addHealthTo:GetAttribute("Owner")
		or humanoid.MaxHealth == humanoid.Health
	then
		return
	end
	character:SetAttribute("Meds", meds - 1)
	if addHealthTo ~= character then
		self.Soldier.Events:PathFinding(addHealthTo.PrimaryPart.Position, 8)
		self.Soldier.Humanoid.WalkToPoint = self.Soldier.HumanoidRootPart.Position
	end

	character:SetAttribute("Healing", true)
	for _ = 1, 6, 1 do
		local cancelling = not character:GetAttribute("Healing")
		if humanoid.MaxHealth == humanoid.Health or cancelling then
			if not cancelling then
				character:SetAttribute("Healing", false)
				self.Soldier.Animations:SetState(0)
			end
			break
		end
		self.Soldier.Animations:PlayAnim(12)
		task.wait(1)
		humanoid.Health += 5
	end
end

function Events:SetClosesEnemy(Target)
	self.Soldier.ClosesEnemy = Target
end

function Events:SetPose(pose)
	self.Soldier.Character:SetAttribute("Pose", pose)

	local spos: Vector3 = self.Soldier.HumanoidRootPart.Position
	task.wait(0.1)
	local epos = self.Soldier.HumanoidRootPart.Position

	self.Soldier.Animations:SetState((spos - epos).Magnitude, self.Soldier)
end

function Events:PathFinding(dest: Vector3, magnitude: number)
	local character = self.Soldier.Character
	character:SetAttribute("Building", false)
	character:SetAttribute("Healing", false)
	character:SetAttribute("PlantingBomb", false)

	if dest then
		self.Soldier.Effects:SetUnderlay()
		self.Soldier.Path:ComputeAsync(character.Underlay.Position, dest)
		if self.Soldier.Path.Status == Enum.PathStatus.Success then
			local waypoints = self.Soldier.Path:GetWaypoints()
			for index, point in ipairs(waypoints) do
				character.Humanoid:MoveTo(point.Position)
				-- Wait until the Soldier reaches the point or stop is triggered
				while (character.HumanoidRootPart.Position - point.Position).magnitude > 5 do
					if
						character:GetAttribute("StopWalking")
						or (index == #waypoints and (character.HumanoidRootPart.Position - point.Position).magnitude <= 1)
						or (magnitude and (character.HumanoidRootPart.Position - dest).magnitude < magnitude)
					then
						if not self.Soldier.closesEnemy then
							character["Hammer"].Transparency = 1
							character["Handle"].Transparency = 0
						end
						character:SetAttribute("StopWalking", false)
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

return Events
