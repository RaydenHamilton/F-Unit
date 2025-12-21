--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

--// Variables
local player = Players.LocalPlayer
--// Move StarterGui to PlayerGui
for _, GuiElement in pairs(StarterGui:GetChildren()) do
	GuiElement:Clone().Parent = player.PlayerGui
end
local tabs = player.PlayerGui:WaitForChild("ShopUI")
local options = tabs.Options
local playerMoney = 0
local points = player.PlayerGui.HudUI.Points.MPNumber
local highlight = ReplicatedStorage.States.Highlight

--// Modules
local SoldierClasses = require(ReplicatedStorage.Shared.SoldierClasses)
local SquadClasses = require(ReplicatedStorage.Shared.SquadClasses)
local WeaponClasses = require(ReplicatedStorage.Shared.WeaponClasses)
local VehicleClasses = require(ReplicatedStorage.Shared.VehicleClasses)

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
			if playerMoney >= classInfo.Cost then
				local success = ReplicatedStorage.Remotes.RemoteFunctions.SpawnInit:InvokeServer(
					tabName,
					className,
					highlight.Value and highlight.Value.Parent or nil
				)
				if success then
					playerMoney = playerMoney - classInfo.Cost
					points.Text = playerMoney
					button.Parent.Visible = false
					options.Visible = true
					tabs.Enabled = false
					highlight.Value.Enabled = false
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
	template.Visible = false
	local itemTemplate = tabs.ItemTemplate
	itemTemplate.Visible = false
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
	playerMoney = money
	points.Text = playerMoney
end

--// Events
ReplicatedStorage.NPCEvents.TellClientMoney.OnClientEvent:Connect(UpdateMoney)

--// Initial
LoadItems()
