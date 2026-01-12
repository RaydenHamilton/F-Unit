--!strict
--// Services
local Debris = game:GetService("Debris")

--// Module
local soldierEffects = {}

soldierEffects.__index = soldierEffects

function soldierEffects.new(soldier)
	local self = setmetatable({}, soldierEffects)
	self.Soldier = soldier
	return self
end

--// Local Functions
local function MapRange(value: number, inMin: number, inMax: number, outMin: number, outMax: number)
	return -((value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin)
end

--// Module Functions
function soldierEffects:AngleArms()
	local torso = self.Soldier.Character:FindFirstChild("Torso") :: BasePart
	local rightShoulder, leftShoulder =
		torso:FindFirstChild("Right Shoulder") :: JointInstance, torso:FindFirstChild("Left Shoulder") :: JointInstance
	local minZ, maxZ, minTilt, maxTilt = -math.pi, math.pi, 4, -4
	-- Calculate the direction to the mouse from the NPC's arm
	local rightC1X: number, rightC1Y: number = rightShoulder.C1:ToOrientation()
	-- Calculate the new look direction
	local newZ = CFrame.lookAt(
		(self.Soldier.Character:FindFirstChild("Handle") :: BasePart).Position,
		self.Soldier.ClosesEnemy.Head.Position
	):ToOrientation()
	-- Create the new CFrame preserving the X and Z angles
	rightShoulder.C1, leftShoulder.C1 =
		CFrame.Angles(rightC1X, rightC1Y, -newZ),
		CFrame.Angles(-newZ * 2.5, 0, 0) * CFrame.new(
			0.5,
			0.5,
			MapRange(newZ, minZ, maxZ, minTilt, maxTilt),
			-4.37113883e-08,
			0,
			-1,
			0,
			0.99999994,
			0,
			1,
			0,
			-4.37113883e-08
		)
end

function soldierEffects:Bullet(gun, lookAt, distance)
	if distance and distance > 2048 then
		distance = 2048
	end
	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.05, 0.05, distance or 2048)
	bullet.CastShadow = false
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.CanTouch = false
	bullet.Anchored = true
	bullet.Color = Color3.fromRGB(239, 184, 56)
	bullet.Parent = workspace
	bullet.CFrame = CFrame.new(gun.Position, lookAt)
	bullet.CFrame = bullet.CFrame + (bullet.CFrame.LookVector * bullet.Size.Z / 2)
	Debris:AddItem(bullet, 0.05)
end

function soldierEffects:GunEffects()
	local torso = self.Soldier.Character:FindFirstChild("Torso")
	local rightShoulder, leftShoulder =
		torso:FindFirstChild("Right Shoulder") :: JointInstance, torso:FindFirstChild("Left Shoulder") :: JointInstance
	local handle = self.Soldier.Character:FindFirstChild("Handle")
	local barral = handle:FindFirstChild("Barrel");

	(handle:FindFirstChild("ShootSound") :: Sound):Play()

	local function Flash(bool)
		(barral:FindFirstChild(".05") :: PointLight).Enabled = bool;
		(barral:FindFirstChild("emit1") :: ParticleEmitter).Enabled = bool
		rightShoulder.C1 = rightShoulder.C1 :: CFrame * CFrame.Angles(0, 0, bool and -0.1 or 0.1)
		leftShoulder.C1 = leftShoulder.C1 :: CFrame * CFrame.Angles(0, 0, bool and -0.1 or 0.1)
	end

	Flash(true)
	task.wait(0.1)
	Flash(false)
end

function soldierEffects:SetUnderlay()
	local center: Vector3 = self.Soldier.HumanoidRootPart.Position
	local raycastResult =
		workspace:Raycast(center - Vector3.new(0, 2, 0), Vector3.new(0, -1000, 0), self.Soldier.ShotRules)
	self.Soldier.Character.Underlay.CFrame = CFrame.new(
		raycastResult.Position + Vector3.new(0.001),
		(raycastResult.Position + Vector3.new(0.001)) + raycastResult.Normal
	) * CFrame.Angles(math.rad(-90), 0, math.rad(-0))
end

return soldierEffects
