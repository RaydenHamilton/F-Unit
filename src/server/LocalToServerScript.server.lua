--!nocheck

--// Services
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Varubles
local TestingData = DataStoreService:GetDataStore("TestingData")

--// Remotes
ReplicatedStorage.Remotes.RemoteFunctions.GetDataStore.OnServerInvoke = function(player)
	local _, data = pcall(function()
		return TestingData:GetAsync(player.UserId)
	end)
	return data
end
