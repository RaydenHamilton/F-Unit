--!nocheck

--// Services
local RunService = game:GetService("RunService")
local WorkSpace = game:GetService("Workspace")
local Players = game:GetService("Players")

--// Modules
local Modules = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
-- local createInstances = require(script.CreateInstances)
local createEffects = require(Modules:WaitForChild("CreateEffects"))
local tempData = require(Modules.TempData)
local miscFunctions = require(Modules.MiscFunctions)
local eventModule = require(Modules.EventModule)
local logicModule = require(Modules.LogicModule)

--// Varubles
local player = Players.LocalPlayer
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local actions = botGui.Actions
local position = botGui.Position
local mouse = player:GetMouse()

--// Gui
local wallButton = botGui["Build"].Background.ImageButton
local selfHeal = actions.HealSelf.ImageButton
local healOther = actions.HealOther.ImageButton
local crouch = position.Crouch.ImageButton
local crawl = position.Crawl.ImageButton
local stand = position.Stand.ImageButton

--// Local Functions
local function changeSoldier()
	miscFunctions.unselect()
	local selected = mouse.Target
	player.PlayerGui.ShopUI.Enabled = false
	if selected and tonumber(selected.Parent:GetAttribute("Owner")) == player.UserId then
		print("Selected Soldier")
		tempData.Target = selected.Parent
		local Walls = tempData.Target:GetAttribute("Walls")
		local Meds = tempData.Target:GetAttribute("Meds")
		player.PlayerGui.Main.Heals.Number.Text = Meds
		player.PlayerGui.Main.Walls.Number.Text = Walls

		tempData.Target.Underlay.Color = Color3.new(1, 1, 1)
		botGui.Enabled = true
		tempData.soldierRange = tempData.Target:GetAttribute("Range")
		local ShotRules = RaycastParams.new()
		ShotRules.FilterDescendantsInstances = {
			tempData.Target,
		}
		ShotRules.FilterType = Enum.RaycastFilterType.Exclude
		ShotRules.IgnoreWater = true

		tempData.selceted = RunService.RenderStepped:Connect(function()
			createEffects.ShowRange(tempData.Target, tempData.soldierRange)
		end)
	end
end

local function FlashOutLine()
	tempData.erroFlash = true
	for i = 0, 1 do
		tempData.characterHighlight.OutlineColor = Color3.new(1, 1, 1)
		task.wait(0.1)
		tempData.characterHighlight.OutlineColor = Color3.new(0, 0, 0)
		task.wait(0.1)
	end
	tempData.erroFlash = false
	tempData.characterHighlight = miscFunctions.removeObject(tempData.characterHighlight)
end

local function onLelfClick()
	local target = mouse.Target
	if
		target
		and target.Parent
		and mouse.Target.Parent.Parent.Name == "Spawn"
		and tempData.characterHighlight
		and tempData.characterHighlight.Parent
	then
		local spawnModel = mouse.Target.Parent.Parent
		local Params = OverlapParams.new()
		Params.FilterType = Enum.RaycastFilterType.Whitelist
		Params.FilterDescendantsInstances = { WorkSpace.Targets }
		local getTouchingParts =
			WorkSpace:GetPartBoundsInBox(spawnModel.PrimaryPart.CFrame, Vector3.new(20, 20, 20), Params)
		if #getTouchingParts == 0 then
			tempData.characterHighlight.OutlineColor = Color3.new(1, 1, 1)
			player.PlayerGui.ShopUI.Enabled = true
		elseif not tempData.erroFlash then
			FlashOutLine()
		end
	elseif miscFunctions.ifNot() then
		eventModule.clickNewEnemy()
		changeSoldier()
	elseif tempData.placeingWall then
		eventModule.placeWall()
	elseif tempData.HealingTeamate then
		eventModule.hoverHealableWho()
	end
end

local function inputChanged(input, onGui)
	if not onGui then
		if miscFunctions.ifNot() then
			logicModule.canWalkTo(input)
		end
		createEffects.highlightCharacter(input)
		createEffects.animateUnderlay(input)
	end
end

local function onRightClick()
	if miscFunctions.ifNot() then
		if not eventModule.OpenBunker() then
			eventModule.MoveTo()
		end
	else
		miscFunctions.unselect()
	end
end

mouse.TargetFilter = WorkSpace.ClientParts

--// Events
game:GetService("UserInputService").InputChanged:Connect(inputChanged)

mouse.Button1Up:Connect(onLelfClick)
mouse.Button2Up:Connect(onRightClick)

wallButton.Activated:Connect(eventModule.clickedPlaceWall)
selfHeal.Activated:Connect(eventModule.clickSelfHeal)
healOther.Activated:Connect(eventModule.clickedHeal)
crouch.Activated:Connect(eventModule.crouch)
crawl.Activated:Connect(eventModule.crawl)
stand.Activated:Connect(eventModule.stand)
