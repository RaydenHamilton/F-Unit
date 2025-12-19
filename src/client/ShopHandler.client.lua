--!nocheck

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Varubles
local player = Players.LocalPlayer
local tabs = player.PlayerGui:WaitForChild("ShopUI")
local options = tabs.Options
local GetPlayerMoney = 100
local points = player.PlayerGui.HudUI.Points.MPNumber

--// Modules
local SoldierClasses = require(ReplicatedStorage.Shared.SoldierClasses)
local SquadClasses = require(ReplicatedStorage.Shared.SquadClasses)
local WeaponClasses = require(ReplicatedStorage.Shared.WeaponClasses)
local VehicleClasses = require(ReplicatedStorage.Shared.VehicleClasses)
local TempData = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client").TempData)

--// Local Events
local function LoadButtons(tabName, classes)
	local newTab = tabs.TabTemplate:Clone()
	newTab.Parent = tabs
	newTab.Name = tabName
	for className, classInfo in pairs(classes) do
		local button = tabs.ItemTemplate:Clone()
		button.Name = className
		button.Text = className .. " - Cost: " .. tostring(classInfo.Cost)
		button.Parent = newTab
		button.Visible = true
		button.Activated:Connect(function()
			if GetPlayerMoney >= classInfo.Cost then
				local success = ReplicatedStorage.Remotes.RemoteFunctions.SpawnInit:InvokeServer(
					tabName,
					className,
					TempData.characterHighlight.Parent
				)
				if success then
					GetPlayerMoney = GetPlayerMoney - classInfo.Cost
					points.Text = GetPlayerMoney
					button.Parent.Visible = false
					options.Visible = true
					tabs.Enabled = false
					TempData.characterHighlight.Enabled = false
				end
			end
		end)
	end
end

local function LoadItems()
	LoadButtons("Soldiers", SoldierClasses)
	LoadButtons("Squads", SquadClasses)
	LoadButtons("Weapons", WeaponClasses)
	LoadButtons("Vehicles", VehicleClasses)
	local template = tabs.TabTemplate
	template:Destroy()
	local itemTemplate = tabs.ItemTemplate
	itemTemplate:Destroy()
end

local function BacktoOptions(option)
	options.Visible = true
	option.Visible = false
end

local function OpenOptions(button)
	local option = tabs[button.Name]

	option.Visible = true
	options.Visible = false

	local exitFunction
	exitFunction = option.Exit.Activated:Connect(function()
		BacktoOptions(option)
		exitFunction:Disconnect()
	end)
end

--// Initial
LoadItems()

--// Connections
for _, option in pairs(options:GetChildren()) do
	if option:IsA("TextButton") then
		option.Activated:Connect(function()
			OpenOptions(option)
		end)
	end
end

--// sould be in another scripts
local function UpdateMoney(money)
	GetPlayerMoney = money
	points.Text = GetPlayerMoney
end

--// Events
ReplicatedStorage.NPCEvents.TellClientMoney.OnClientEvent:Connect(UpdateMoney)
