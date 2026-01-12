local playerData = {}

--// Services
local Workspace = game:GetService("Workspace")

local keyTable = {}

playerData.__index = playerData

function playerData.New(player: Player)
	local self = setmetatable({}, playerData)
	local teamFolder = Instance.new("Folder")
	teamFolder.Parent = Workspace.Targets
	teamFolder.Name = player.UserId

	table.insert(keyTable, player.UserId)
	self.Id = player.UserId
	self.Points = 100
	self.Team = teamFolder
	return self
end

function playerData:RemovePoints(points: IntValue)
	self.Points -= points
end

function playerData:AddPoints()
	if self.Points < 500 then
		self.Points += 1
	end
end

function playerData:RemoveKey()
	self.Team:Destroy()
	table.remove(keyTable, table.find(keyTable, self.Id))
	setmetatable(self, nil)
end

return playerData
