--!strict

--// Modules
local SoldierClass = require(game.ServerStorage.SoldierClass)

--// Types
type SoldierData = SoldierClass.SoldierData

--// Modules
local soldierEffects = {}

--// Local Functions
local function MapRange(value : number, inMin : number, inMax : number, outMin : number, outMax : number)
	return -((value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin)
end

--// Module Functions
soldierEffects.AngleArms = function(soldierData : SoldierData)
	local torso = soldierData.Soldier:FindFirstChild("Torso") :: BasePart 
	local rightShoulder,leftShoulder = torso:FindFirstChild"Right Shoulder" :: JointInstance,torso:FindFirstChild"Left Shoulder" :: JointInstance
	local minZ,maxZ,minTilt,maxTilt = -math.pi,math.pi,4,-4
	-- Calculate the direction to the mouse from the NPC's arm
	local rightC1X : number, rightC1Y : number = rightShoulder.C1:ToOrientation()
	-- Calculate the new look direction
	local newZ = CFrame.lookAt((soldierData.Soldier:FindFirstChild'Handle' :: BasePart).Position, soldierData.ClosesEnemy.Head.Position):ToOrientation()
	-- Create the new CFrame preserving the X and Z angles
	rightShoulder.C1, leftShoulder.C1 = CFrame.Angles(rightC1X, rightC1Y, -newZ), CFrame.Angles(-newZ*2.5, 0,0) * CFrame.new(0.5, 0.5, MapRange(newZ, minZ, maxZ, minTilt, maxTilt), -4.37113883e-08, 0, -1, 0, 0.99999994, 0, 1, 0, -4.37113883e-08)
end

soldierEffects.Bullet = function(gun,lookAt, distance)
	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.05, 0.05,distance or 2048) 
	bullet.CastShadow = false
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.CanTouch = false
	bullet.Anchored = true
	bullet.Color = Color3.fromRGB(239, 184, 56)
	bullet.Parent = workspace
	bullet.CFrame = CFrame.new(gun.Position ,lookAt) 
	bullet.CFrame = bullet.CFrame + (bullet.CFrame.LookVector * bullet.Size.Z / 2)
	game.Debris:AddItem(bullet, 0.05)
end


soldierEffects.GunEffects = function(soldierDate : SoldierData)
	local torso = soldierDate.Soldier:FindFirstChild('Torso')
	local rightShoulder,leftShoulder = torso:FindFirstChild"Right Shoulder" :: JointInstance ,torso:FindFirstChild"Left Shoulder" :: JointInstance
	local handle = soldierDate.Soldier:FindFirstChild'Handle'
	local barral = handle:FindFirstChild'Barrel';
	
	(handle:FindFirstChild('ShootSound') :: Sound):Play()
	
	local function Flash(bool)
		(barral:FindFirstChild".05" :: PointLight).Enabled = bool;
		(barral:FindFirstChild"emit1" :: ParticleEmitter).Enabled = bool
		rightShoulder.C1 = rightShoulder.C1 :: CFrame * CFrame.Angles(0,0,bool and -0.1 or 0.1)
		leftShoulder.C1 = leftShoulder.C1 :: CFrame * CFrame.Angles(0,0,bool and -0.1 or 0.1)
	end
	
	Flash(true)
	task.wait(0.1)
	Flash(false)
end



return soldierEffects
