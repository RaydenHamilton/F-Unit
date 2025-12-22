--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

--// Modules
local playerData = require(ServerStorage.PlayerData)
local soldierClasses = require(ReplicatedStorage.Shared.SoldierClasses)
local SquadClasses = require(ReplicatedStorage.Shared.SquadClasses)
local VehicleClasses = require(ReplicatedStorage.Shared.VehicleClasses)
local WeaponClasses = require(ReplicatedStorage.Shared.WeaponClasses)
local CreateSoldierModule = require(script.Parent.SoldierModules.soldierModule)
--// Varubles
local PlayerInstances = {}
local SpawnInit = ReplicatedStorage.Remotes.RemoteFunctions.SpawnInit

local function onPlayerAdded(player: Player) -- change to on round start
	PlayerInstances[player.UserId] = playerData.New(player)
	ReplicatedStorage.NPCEvents.TellClientMoney:FireClient(player, PlayerInstances[player.UserId].Points)
	while task.wait(1) and Players:FindFirstChild(player.Name) do
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
		soldier.Parent = Workspace.Targets;

		(soldier.PrimaryPart :: BasePart).CFrame = CFrame.new((rootPart.Position + Vector3.new(0, 5, 0)))
			* CFrame.new(direction * 10)

		CreateSoldierModule.new(player.UserId, soldier, soldierClasses[soldierType[i]])
	end
end

local function onPlayerRemoved(player)
	PlayerInstances[player.UserId]:RemoveKey()
	PlayerInstances[player.UserId] = nil
end

local function GetClass(tabName: string)
	if tabName == "Soldiers" then
		return soldierClasses
	elseif tabName == "Squads" then
		return SquadClasses
	elseif tabName == "Vehicles" then
		return VehicleClasses
	elseif tabName == "Weapons" then
		return WeaponClasses
	end
	warn("not a valid class")
	return nil
end

--// Events
Players.PlayerRemoving:Connect(onPlayerRemoved)
Players.PlayerAdded:Connect(onPlayerAdded)
ReplicatedStorage.NPCEvents.Heal.OnServerEvent:Connect(buySoldier)

SpawnInit.OnServerInvoke = function(player, tabName: string, className: string, spawn: Model)
	local classes = GetClass(tabName)
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
