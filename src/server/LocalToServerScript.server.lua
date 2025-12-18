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

-- ReplicatedStorage.NPCEvents.GetNPCData.OnServerInvoke = function(Player, char, var)
--if not (char or var) or not NPCDataTable[char] then return nil end
--return NPCDataTable[char][var]
-- end
