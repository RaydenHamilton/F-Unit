local playerData = {}

local keyTable = {}

playerData.__index = playerData

function playerData.New(player:Player)
	local self = setmetatable({},playerData)
	
	table.insert(keyTable,player.UserId)
	self.Id = player.UserId
	self.Points = 100
	
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
	table.remove(keyTable, table.find(keyTable, self.Id))
	setmetatable(self, nil)
end


return playerData
