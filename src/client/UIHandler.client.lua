--!nocheck

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Varubles
local player = Players.LocalPlayer
local buttons = player.PlayerGui:WaitForChild("ShopUI").Frame
local buySoldierEvent = ReplicatedStorage.NPCEvents.BuySoldier
local GetPlayerMoney = 100
local points = player.PlayerGui.HudUI.Points.MPNumber
local data = ReplicatedStorage.Remotes.RemoteFunctions.GetDataStore:InvokeServer()

--// Modules
local classes = require(ReplicatedStorage.Shared.Classes)
local tempData = require(script.Parent.TempData)
local MiscFunctions = require(script.Parent.MiscFunctions)

--// Local Events
local function Buy(button)
	local squad = data[button.Name]
	local costOfSquad = 0

	for i in squad do
		costOfSquad += classes[squad[i]].Cost
	end

	if costOfSquad <= GetPlayerMoney then
		buySoldierEvent:FireServer(squad, tempData.characterHighlight.Parent)
		for i in ipairs(squad) do
			GetPlayerMoney -= classes[squad[i]].Cost
			points.Text = GetPlayerMoney
		end
		Players.LocalPlayer.PlayerGui.ShopUI.Enabled = false
		tempData.characterHighlight = MiscFunctions.removeObject(tempData.characterHighlight)
	end
end

local function UpdateMoney(money)
	GetPlayerMoney = money
	points.Text = GetPlayerMoney
end

--// Events
ReplicatedStorage.NPCEvents.TellClientMoney.OnClientEvent:Connect(UpdateMoney)

for _, v in buttons:GetChildren() do
	if v:IsA("GuiButton") then
		v.MouseButton1Up:Connect(function()
			Buy(v)
		end)
	end
end
