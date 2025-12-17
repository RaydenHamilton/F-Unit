--// Services
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

--// Varubles
local npcs = game.Workspace.Targets
local ID = 0

local function setClosesEnemy(_, enemy, selectedSoldier, soldierData)
	if selectedSoldier == soldierData.Soldier then
		soldierData.ClosesEnemy = enemy
	end
end
