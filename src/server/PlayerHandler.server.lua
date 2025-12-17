--!strict

--// Modules
local playerData = require(game.ServerStorage.PlayerData)
local soldierClasses = require(game.ReplicatedStorage.Classes)
local CreateSoldierModule = require(game.ServerStorage.soldierModule)

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Varubles
local PlayerInstances = {}

function onPlayerAdded(player: Player) -- change to on round start
	PlayerInstances[player.UserId] = playerData.New(player)
	ReplicatedStorage.NPCEvents.TellClientMoney:FireClient(player, PlayerInstances[player.UserId].Points)
	while task.wait(1) and game.Players:FindFirstChild(player.Name) do
		PlayerInstances[player.UserId]:AddPoints()
		ReplicatedStorage.NPCEvents.TellClientMoney:FireClient(player, PlayerInstances[player.UserId].Points)
	end
end

function buySoldier(player: Player, soldierType, spawn: Model)
	local rootPart = spawn.PrimaryPart :: BasePart
	local numberOfSoldiers = #soldierType -- Number of rays in the circle

	for i = 1, numberOfSoldiers do
		local angle = (i / numberOfSoldiers) * math.pi * 2 -- Convert index to radians
		local localDirection = Vector3.new(math.cos(angle), 0, math.sin(angle)) -- Direction in rootPart's local space
		local direction = rootPart.CFrame:VectorToWorldSpace(localDirection) -- Convert to world space relative to rootPart

		local cost = soldierClasses[soldierType[i]].Cost
		PlayerInstances[player.UserId]:RemovePoints(cost)

		local class = require(ReplicatedStorage.Classes)[soldierType[i]]
		local soldier: Model = ReplicatedStorage.SoldierCopys[soldierType[i]]:Clone()
		soldier.Parent = game.Workspace.Targets;

		(soldier.PrimaryPart :: BasePart).CFrame = CFrame.new((rootPart.Position + Vector3.new(0, 5, 0)))
			* CFrame.new(direction * 10)

		CreateSoldierModule.new(player.UserId, soldier, class)
	end
end

function onPlayerRemoved(player)
	PlayerInstances[player.UserId]:RemoveKey()
	PlayerInstances[player.UserId] = nil
end

--// Events
Players.PlayerRemoving:Connect(onPlayerRemoved)
Players.PlayerAdded:Connect(onPlayerAdded)
game.ReplicatedStorage.NPCEvents.Heal.OnServerEvent:Connect(buySoldier)
