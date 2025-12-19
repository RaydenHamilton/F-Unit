--!strict

--// Modules
local SoldierClass = require(game.ServerStorage.SoldierClass)
type SoldierData = SoldierClass.SoldierData

local DeathModule = {}

--// Module Functions \\--
function DeathModule.PlayDeath(soldierData : SoldierData)
	--dead target
	local rightarmw
	local rightlegw
	local leftarmw
	local leftlegw
	if soldierData.Soldier:FindFirstChild("Handle") and soldierData.Soldier:WaitForChild("Handle"):FindFirstChild("Barrel")  then
		soldierData.Soldier:WaitForChild("Handle"):FindFirstChild("Barrel"):Destroy()
	end
	soldierData.Humanoid.HealthDisplayDistance = 0
	--soldierData.Soldier.Name = ""
	soldierData.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	--stops taget from moving
	soldierData.Humanoid.WalkSpeed = 0
	soldierData.Humanoid.JumpPower = 0
	--plays random sound
	local Deathsound = Instance.new("Sound", soldierData.Soldier:WaitForChild('Head'))
	Deathsound.Volume = 1
	local Deathsounds = {
		"rbxassetid://6932519682",
		"rbxassetid://6599779766",
		"rbxassetid://8798232381",
		"rbxassetid://5154928569",
		"rbxassetid://297237983",
		"rbxassetid://7227567562",
		"rbxassetid://7172055941",
		"rbxassetid://3040094458",
		"rbxassetid://180404792",
		"rbxassetid://1394480679",
		"rbxassetid://4737305841",
		"rbxassetid://5682262154",
		"rbxassetid://159102636",
		"rbxassetid://6586979979",
	}

	local Deathrandom = math.random(1,#Deathsounds)
	Deathsound.SoundId = Deathsounds[Deathrandom]
	Deathsound:Play()
	soldierData.HumanoidRootPart.Anchored = true
	--if soldierData.Soldier has an right arm, Right Leg, Left Arm ,and Left Leg then weld to Torso
	local Torso = soldierData.Soldier:WaitForChild('Torso') :: BasePart

	if soldierData.Soldier:FindFirstChild("Right Arm") then
		rightarmw = Instance.new("Weld", Torso)
		rightarmw.Part0 = Torso
		rightarmw.Part1 = soldierData.Soldier:WaitForChild("Right Arm") :: BasePart
		rightarmw.C0 = CFrame.new(1.5,0,0)
		rightarmw.Name = "RightArmWeld"
	end
	if soldierData.Soldier:FindFirstChild("Right Leg") then
		rightlegw = Instance.new("Weld", Torso)
		rightlegw.Part0 = Torso
		rightlegw.Part1 = soldierData.Soldier:WaitForChild("Right Leg") :: BasePart
		rightlegw.C0 = CFrame.new(0.5,-2,0)
		rightlegw.Name = "RightLegWeld"
	end
	if soldierData.Soldier:FindFirstChild("Left Arm") then
		leftarmw = Instance.new("Weld", Torso)
		leftarmw.Part0 = Torso
	leftarmw.Part1 = soldierData.Soldier:WaitForChild("Left Arm") :: BasePart
		leftarmw.C0 = CFrame.new(-1.5,0,0)
		leftarmw.Name = "LeftArmWeld"
	end
	if soldierData.Soldier:FindFirstChild("Left Leg") then
		leftlegw = Instance.new("Weld", Torso)
		leftlegw.Part0 = Torso
		leftlegw.Part1 = soldierData.Soldier:WaitForChild("Left Leg") :: BasePart
		leftlegw.C0 = CFrame.new(-0.5,-2,0)
		leftlegw.Name = "LeftLegWeld"
	end
	--weld root part to Torso
	local humanoidrootpartw = Instance.new("Weld", soldierData.HumanoidRootPart)
	humanoidrootpartw.Part0 = soldierData.HumanoidRootPart
	humanoidrootpartw.Part1 = Torso
	humanoidrootpartw.Name = "HumanoidRootPartWeld"
	--Death Animation
	for frame = 0,1 , 0.02 do
		rightarmw.C0 = rightarmw.C0:Lerp(CFrame.new(1.64086914, 0.201171875, 0, 0.939692497, -0.342020094, 0, 0.342020124, 0.939692557, 0, 0, 0, 1),frame)
		leftarmw.C0 = leftarmw.C0:Lerp(CFrame.new(-1.98254395, 0.588928223, 0, 0.342020214, 0.939692438, -1.77635663e-15, -0.939692497, 0.342020243, -3.55271368e-15, 0, 3.55271368e-15, 1),frame)
		leftlegw.C0 = leftlegw.C0:Lerp(CFrame.new(-0.681274414, -2.07165527, 0, 0.984807611, 0.173648268, 0, -0.173648283, 0.98480767, 0, 0, 0, 1),frame)
		rightlegw.C0 = rightlegw.C0:Lerp(CFrame.new(1.0670166, -2.11602783, 0, 0.866025329, -0.499999851, 0, 0.499999881, 0.866025388, 0, 0, 0, 1),frame)
		humanoidrootpartw.C0 = humanoidrootpartw.C0:Lerp(CFrame.new(0, -2.60009766, 1.20001221, 0.99999994, 0, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08),frame)
		game:GetService("RunService").Heartbeat:wait()
	end
	for i in ipairs(soldierData.Connections) do
		soldierData.Connections[i]:Disconnect()
	end
	soldierData.Soldier:WaitForChild("Underlay"):Destroy()

	task.wait(3)

	soldierData.Soldier.Parent = game.Workspace.Dead
	for i,bodyPart : BasePart | any in pairs(soldierData.Soldier:GetDescendants()) do
		if bodyPart:IsA("BasePart") then
			local BasePart : BasePart = bodyPart
			BasePart.CanCollide = false
			BasePart.CanQuery = false
			BasePart.CanTouch = false
		end
	end
	for index in pairs(soldierData) do
		soldierData[index] = nil
	end
end

return DeathModule
