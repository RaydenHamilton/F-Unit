--!strict



--// Module
local SoldierEvents = {}

--// Service
local ServerStorage = game:GetService("ServerStorage")

--// Modules
local soldierAnimation = require(script.Parent.soldierAnimationController)
local SoldierPathFinding = require(script.Parent.SoldierPathFinding)
local SoldierClass = require(game.ServerStorage.SoldierClass)

--// Types
type SoldierData = SoldierClass.SoldierData

function SoldierEvents.MakeWall(_,size,partStart : Vector3,partEnd,selectedSoldier,soldierData : SoldierData)
	local angle = Vector3.new(partStart.X - partEnd.X,partStart.Y - partEnd.Y,partStart.Z - partEnd.Z).Unit * game.ReplicatedStorage.ReplicatedObjects.Sandbag.Size.X
	if selectedSoldier == soldierData.Soldier and SoldierPathFinding.PathFiding(partStart + angle*2,soldierData) then
		local hammer = soldierData.Soldier:WaitForChild"Hammer" :: BasePart

		soldierData.Inventory.Walls -= size
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Covering, false)
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Building, true)

		task.wait(0.5)
		soldierData.State = soldierAnimation.PlayAnim(12,soldierData.Humanoid,soldierData.Loaded)
		hammer.Transparency = 0
		hammer.Transparency = 1
		local model = Instance.new("Model",game.Workspace.walls)
		model.Name = "sandBagwall"
		for i = 0, size , 1 do
			local row = Instance.new("Model",model)
			row.Name = "sandBagRow"
			local health = Instance.new("IntValue",row)
			health.Value = 5000
			local maxhealth = Instance.new("IntValue",health)
			maxhealth.Value = 5000
			maxhealth.Name = "maxhealth"
		end
		for v = 1, 6 , 1 do
			local offset = math.random(-0.7,0.7)
			for i = 0, size , 1 do
				if not soldierData.Soldier:GetAttribute(SoldierClass.Controls.Building) then
					hammer.Transparency = 1
					hammer.Transparency = 0
					return
				end
				task.wait(1)
				
				local newSandbag =  game.ReplicatedStorage.ReplicatedObjects.Sandbag:Clone()
				newSandbag.Parent = model:GetChildren()[i+1]
				newSandbag.Position = partStart - angle*(i) + Vector3.new(0,newSandbag.Size.Y*v*0.75,0) + angle*offset
				newSandbag.Rotation = Vector3.new(0,math.random(1,360),0)
				newSandbag.Anchored = false
				task.wait(.15)
				newSandbag.Anchored = true
				newSandbag.Position = newSandbag.Position - Vector3.new(0,newSandbag.Size.Y*3*0.15,0)
			end
		end
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Building,false)
		hammer.Transparency = 1
		hammer.Transparency = 0
		local spos = soldierData.HumanoidRootPart.Position
		task.wait(0.1)
		local epos = soldierData.HumanoidRootPart.Position

		soldierAnimation.SetState((spos - epos).Magnitude,soldierData)
	end
end

function SoldierEvents.OnMoveTo(_,moveToPosition,selectedSoldier,isCover,soldierData : SoldierData)
	if selectedSoldier == soldierData.Soldier then
		if soldierAnimation.isRunning(soldierData) then
			soldierData.Soldier:SetAttribute(SoldierClass.Controls.StopWalking, true)
		end
		repeat task.wait() until not soldierData.Soldier:GetAttribute(SoldierClass.Controls.StopWalking)
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Covering, isCover)
		SoldierPathFinding.PathFiding(moveToPosition,soldierData)
	end
end

function SoldierEvents.PlantBomb(_,Valut : Vector3,soldier : Model,doors : Model,soldierData : SoldierData)
	if soldier == soldierData.Soldier and SoldierPathFinding.PathFiding(Valut,soldierData,15) then
			
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Covering, false)
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.Building, false)
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.PlantingBomb, false)

		for count = 0, 15, 1 do
			if not soldierData.Soldier:GetAttribute(SoldierClass.Controls.PlantingBomb) or (Valut-soldierData.HumanoidRootPart.Position).Magnitude > 15 then
				return
			end
			task.wait(1)
		end
		soldierData.Soldier:SetAttribute(SoldierClass.Controls.PlantingBomb, false)
		for _,child : Instance in pairs(doors:GetChildren()) do
			if child:IsA("BasePart") then
				local door : BasePart = child
				door.Transparency = 1
				door.CanCollide = false
				door.CanQuery = false 
				door.CanTouch = false
			end
		end
		for i,child : Instance in pairs((doors.Parent :: Folder):FindFirstChild'Door Open':GetChildren()) do
			if child:IsA("BasePart") then
				local door : BasePart = child
				door.Transparency = 0
			end
		end
		soldierData.State = soldierAnimation.PlayAnim(12,soldierData.Humanoid,soldierData.Loaded)
		for i,v in pairs(game.Workspace.Targets:GetChildren()) do
			if v:GetAttribute("Owner") ~= soldierData.Owner then
				v.Humaniod.Health = 0
			end
		end
		--TODO make this work Does not work cuz i idiot
		--soldierData.ClosesEnemy = (doors.Parent :: Folder).leader
	end
end

function SoldierEvents.healCharacter(_,selectedSoldier,addHealthTo:Model,soldierData : SoldierData)
	if selectedSoldier == soldierData.Soldier then
		if addHealthTo == selectedSoldier then
			soldierData.State = soldierAnimation.PlayAnim(12,soldierData.Humanoid,soldierData.Loaded)
			soldierData.Soldier:SetAttribute(SoldierClass.Controls.Healing, true)
			for medUsage = 0, 6, 1 do
				local OtherHumanoid = addHealthTo:WaitForChild'Humanoid' :: Humanoid
				if OtherHumanoid.MaxHealth == OtherHumanoid.Health then
					OtherHumanoid.Health += 10
					break
				end
				task.wait(1)
			end
			soldierData.Inventory.Meds -= 1

			local spos = soldierData.HumanoidRootPart.Position
			task.wait(0.1)
			local epos = soldierData.HumanoidRootPart.Position

			soldierAnimation.SetState((spos - epos).Magnitude,soldierData)
		else
			if not addHealthTo.PrimaryPart then return end
			SoldierPathFinding.PathFiding(addHealthTo.PrimaryPart.Position,soldierData,8)
			soldierData.State= soldierAnimation.PlayAnim(12,soldierData.Humanoid,soldierData.Loaded)
			soldierData.Soldier:SetAttribute(SoldierClass.Controls.Healing, true)
			soldierData.Humanoid.WalkToPoint = soldierData.HumanoidRootPart.Position
			local OtherHumoid = addHealthTo:WaitForChild'Humanoid' :: Humanoid
			
			for medUsage = 0, 6, 1 do
				if OtherHumoid.MaxHealth == OtherHumoid.Health then
					OtherHumoid.Health += 10
					break
				end
				task.wait(1)
			end
			soldierData.Inventory.Meds -= 1
			soldierData.Soldier:SetAttribute(SoldierClass.Controls.Healing, false)
			
			local spos = soldierData.HumanoidRootPart.Position
			task.wait(0.1)
			local epos = soldierData.HumanoidRootPart.Position

			soldierAnimation.SetState((spos - epos).Magnitude,soldierData)
		end
	end
end

function SoldierEvents.setClosesEnemy(_,Target,npc,soldierData : SoldierData)
	if soldierData.Soldier == npc then
		soldierData.ClosesEnemy = Target
	end
end

function SoldierEvents.SetPose(_,pose,npc,soldierData)
	if npc ~= soldierData.Soldier then return end
	soldierData.pose = pose
	
	local spos : Vector3= soldierData.HumanoidRootPart.Position
	task.wait(0.1)
	local epos = soldierData.HumanoidRootPart.Position
	
	soldierAnimation.SetState((spos - epos).Magnitude,soldierData)
end

return SoldierEvents
