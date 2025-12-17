--!strict

--// Modules
local createInstances = require(script.CreateInstances)
local createEffects = require(script.CreateEffects)
local tempData = require(script.TempData)
local miscFunctions = require(script.MiscFunctions)
local eventModule = require(script.EventModule)
local logicModule = require(script.LogicModule)

--// Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local WorkSpace = game:GetService("Workspace")

--// Varubles
local NPCEvents = game.ReplicatedStorage.NPCEvents
local player = Players.LocalPlayer
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local actions = botGui.Actions
local position = botGui.Position
local mouse = player:GetMouse()
local remoteFunc = game.ReplicatedStorage.NPCEvents.GetNPCData

--// Gui
local wallButton: GuiButton = botGui["Build"].Background.ImageButton
local selfHeal: GuiButton = actions.HealSelf.ImageButton
local healOther: GuiButton = actions.HealOther.ImageButton
local crouch: GuiButton = position.Crouch.ImageButton
local crawl: GuiButton = position.Crawl.ImageButton
local stand: GuiButton = position.Stand.ImageButton

--// Local Functions
local function changeSoldier()
	miscFunctions.unselect()
	local selected = mouse.Target
	player.PlayerGui.ShopUI.Enabled = false
	if
		selected
		and #selected.Parent:GetTags() == 1
		and remoteFunc:InvokeServer(selected.Parent:GetTags()[1], "owner") == player.UserId
	then
		tempData.Target = selected.Parent
		local Walls = remoteFunc:InvokeServer(tempData.Target:GetTags()[1], "Walls")
		local Meds = remoteFunc:InvokeServer(tempData.Target:GetTags()[1], "meds")
		player.PlayerGui.Main.Heals.Number.Text = Meds
		player.PlayerGui.Main.Walls.Number.Text = Walls

		tempData.Target.Underlay.Color = Color3.new(1, 1, 1)
		botGui.Enabled = true
		tempData.soldierRange = remoteFunc:InvokeServer(tempData.Target:GetTags()[1], "class").Range
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
		local spawnModel: Model = mouse.Target.Parent.Parent
		local Params = OverlapParams.new()
		Params.FilterType = Enum.RaycastFilterType.Whitelist
		Params.FilterDescendantsInstances = { WorkSpace.Targets }
		local getTouchingParts =
			WorkSpace:GetPartBoundsInBox((spawnModel.PrimaryPart :: BasePart).CFrame, Vector3.new(20, 20, 20), Params)
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
