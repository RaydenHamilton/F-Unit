--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
--// Modules
local PlayerData = require(script.Parent.PlayerData)
local soldierClasses = require(ReplicatedStorage.Shared.SoldierClasses)
local SquadClasses = require(ReplicatedStorage.Shared.SquadClasses)
local VehicleClasses = require(ReplicatedStorage.Shared.VehicleClasses)
local WeaponClasses = require(ReplicatedStorage.Shared.WeaponClasses)
local Soldier = require(script.Parent.SoldierModules.Soldier)
--// Varubles
local PlayerInstances = {}
local SpawnUnit = ReplicatedStorage.Remotes.RemoteFunctions.SpawnUnit
local NPCEvents = ReplicatedStorage.NPCEvents
local classList = {
	["Soldiers"] = soldierClasses,
	["Squads"] = SquadClasses,
	["Vehicles"] = VehicleClasses,
	["Weapons"] = WeaponClasses,
}
local SoldierInstance = {}

local function GetSoldierFromCharacter(soldierCharacter)
	return SoldierInstance[soldierCharacter]
end

local function onPlayerAdded(player: Player) -- change to on round start
	PlayerInstances[player.UserId] = PlayerData.new(player)
	ReplicatedStorage.NPCEvents.TellClientMoney:FireClient(player, PlayerInstances[player.UserId].Points)
	while task.wait(1) and PlayerInstances[player.UserId] do
		PlayerInstances[player.UserId]:AddPoints()
		ReplicatedStorage.NPCEvents.TellClientMoney:FireClient(player, PlayerInstances[player.UserId].Points)
	end
end

local function buySoldier(player: Player, soldierType, spawn: Model)
	local rootPart = spawn.PrimaryPart :: BasePart
	local numberOfSoldiers = #soldierType -- Number of rays in the circle

	for i = 1, numberOfSoldiers do
		local angle = (i / numberOfSoldiers) * math.pi * 2 -- Convert index to radians
		local localDirection = Vector3.new(math.cos(angle), 0, math.sin(angle)) -- Direction in rootPart's local space
		local direction = rootPart.CFrame:VectorToWorldSpace(localDirection) -- Convert to world space relative to rootPart

		local soldier: Model = ReplicatedStorage.SoldierCopys[soldierType[i]]:Clone()
		soldier.Parent = Workspace.Targets[player.UserId];

		(soldier.PrimaryPart :: BasePart).CFrame = CFrame.new((rootPart.Position + Vector3.new(0, 5, 0)))
			* CFrame.new(direction * 10)

		local SoldierData = Soldier.new(player.UserId, soldier, soldierClasses[soldierType[i]])
		SoldierInstance[SoldierData.Character] = SoldierData
		local removingEvent
		removingEvent = SoldierData.Character.Destroying:Connect(function()
			SoldierInstance[SoldierData.Character] = nil
			removingEvent:Disconnect()
		end)
	end
end

local function onPlayerRemoved(player)
	PlayerInstances[player.UserId]:RemoveKey()
	PlayerInstances[player.UserId] = nil
end

SpawnUnit.OnServerInvoke = function(player, tabName: string, className: string, spawn: Model)
	local classes = classList[tabName]
	if classes[className] then
		local classInfo = classes[className]
		if PlayerInstances[player.UserId].Points >= classInfo.Cost then
			PlayerInstances[player.UserId]:RemovePoints(classInfo.Cost)
			if tabName == "Soldiers" then
				buySoldier(player, { className }, spawn)
			elseif tabName == "Squads" then
				buySoldier(player, classInfo.Units, spawn)
			end
			return true
		end
	end
	return false
end

--// Events
Players.PlayerRemoving:Connect(onPlayerRemoved)
Players.PlayerAdded:Connect(onPlayerAdded)

NPCEvents.Move.OnServerEvent:Connect(function(_, soldiersCharacter, state, position)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:OnMoveTo(state, position)
		end)
	end
end)
NPCEvents.PlaceObject.OnServerEvent:Connect(function(_, soldiersCharacter, sizeOfWall, startOfWall, endOfWall)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:MakeWall(sizeOfWall, startOfWall, endOfWall)
		end)
	end
end)
NPCEvents.Heal.OnServerEvent:Connect(function(_, soldiersCharacter, soldierHealing)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:HealCharacter(soldierHealing)
		end)
	end
end)
NPCEvents.PlantBomb.OnServerEvent:Connect(function(_, soldiersCharacter, mousePosition, valut)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:PlantBomb(mousePosition, valut)
		end)
	end
end)
NPCEvents.SetPose.OnServerEvent:Connect(function(_, soldiersCharacter, pose)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:SetPose(pose)
		end)
	end
end)
NPCEvents.NewTarget.OnServerEvent:Connect(function(_, soldiersCharacter, newTarget)
	for _, soldier in soldiersCharacter do
		task.spawn(function()
			GetSoldierFromCharacter(soldier).Events:SetClosesEnemy(newTarget)
		end)
	end
end)
