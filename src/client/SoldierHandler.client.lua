--// Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
--// Modules
local Modules = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
-- local createInstances = require(script.CreateInstances)
local createEffects = require(Modules.CreateEffects)
local ClientStates = require(Modules.ClientStates)
local miscFunctions = require(Modules.MiscFunctions)
local eventModule = require(Modules.EventModule)
local logicModule = require(Modules.LogicModule)

--// Varubles
local player = Players.LocalPlayer
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local actions = botGui.Actions
local position = botGui.Position
local mouse = player:GetMouse()
local Highlight = ReplicatedStorage.States.Highlight
local Target = ReplicatedStorage.States.Target
local checkSpawnSize = Vector3.new(20, 20, 20)
local colorWhite = Color3.new(1, 1, 1)
local colorBlack = Color3.new(0, 0, 0)

--// Gui
local wallButton = botGui["Build"].Background.ImageButton
local selfHeal = actions.HealSelf.ImageButton
local healOther = actions.HealOther.ImageButton
local crouch = position.Crouch.ImageButton
local crawl = position.Crawl.ImageButton
local stand = position.Stand.ImageButton
local camera = Workspace.CurrentCamera

--// Local Functions

local function getMouseRaycastTarget()
	local mousePos = UserInputService:GetMouseLocation()

	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { Workspace.ClientParts }
	params.IgnoreWater = true

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

	return result
end

local function changeSoldier()
	miscFunctions.unselect()
	local raycastResult = getMouseRaycastTarget()
	local target = raycastResult and raycastResult.Instance
	player.PlayerGui.ShopUI.Enabled = false
	local owner = target.Parent:GetAttribute("Owner")
	if target and owner == player.UserId then
		Target.Value = target.Parent

		local Walls = Target.Value:GetAttribute("Walls")
		local Meds = Target.Value:GetAttribute("Meds")
		player.PlayerGui.Main.Heals.Number.Text = Meds
		player.PlayerGui.Main.Walls.Number.Text = Walls

		Target.Value.Underlay.Color = Color3.new(1, 1, 1)
		botGui.Enabled = true
		local ShotRules = RaycastParams.new()
		ShotRules.FilterDescendantsInstances = {
			Target.Value,
		}
		ShotRules.FilterType = Enum.RaycastFilterType.Exclude
		ShotRules.IgnoreWater = true

		ClientStates.selceted = RunService.RenderStepped:Connect(function()
			createEffects.ShowRange(Target.Value, Target.Value:GetAttribute("Range"))
		end)
	end
end

local function FlashOutLine()
	local highlight = Highlight.Value
	Highlight.Value = nil
	for _ = 0, 4 do
		highlight.OutlineColor = highlight.OutlineColor == colorBlack and colorWhite or colorBlack
		task.wait(0.1)
	end
	miscFunctions.removeObject(highlight)
end
local function SpawnHighlighted()
	local raycastResult = getMouseRaycastTarget()
	local target = raycastResult and raycastResult.Instance
	if not target then
		return false
	end

	local model = target.Parent and target.Parent.Parent
	if not model or model.Name ~= "Spawn" then
		return false
	end

	return Highlight.Value and Highlight.Value.Parent == model
end

local function NoSoldiersNearSpawn()
	local raycastResult = getMouseRaycastTarget()
	local spawnModel = raycastResult and raycastResult.Instance.Parent.Parent
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Whitelist
	Params.FilterDescendantsInstances = { Workspace.Targets }
	local getTouchingParts = Workspace:GetPartBoundsInBox(spawnModel.PrimaryPart.CFrame, checkSpawnSize, Params)
	return #getTouchingParts == 0
end

local function OpenShopUI()
	player.PlayerGui.ShopUI.Enabled = true
	Highlight.Value.OutlineColor = colorWhite
end

local function onLeftClick()
	if SpawnHighlighted() then
		--// check if there are players near spawn
		if NoSoldiersNearSpawn() then
			OpenShopUI()
			return
		else
			FlashOutLine()
			return
		end
	elseif ClientStates.placeingWall then
		eventModule.placeWall()
		return
	elseif ClientStates.HealingTeamate then
		eventModule.hoverHealableWho()
		return
	else --// if not building or healing
		eventModule.clickNewEnemy()
		changeSoldier()
	end
end

local function inputChanged(input, onGui)
	if onGui then
		return
	end
	if miscFunctions.SoldierNotDoingAnything() and input.UserInputType == Enum.UserInputType.MouseMovement then
		logicModule.SetHologram()
	end
	createEffects.highlightCharacter(input)
	createEffects.animateUnderlay(input)
end

local function onRightClick()
	if miscFunctions.SoldierNotDoingAnything() then
		if not eventModule.OpenBunker() then
			eventModule.MoveTo()
		end
	else
		miscFunctions.unselect()
	end
end

--// Events
UserInputService.InputChanged:Connect(inputChanged)

mouse.Button1Up:Connect(onLeftClick)
mouse.Button2Up:Connect(onRightClick)

wallButton.Activated:Connect(eventModule.clickedPlaceWall)
selfHeal.Activated:Connect(eventModule.clickSelfHeal)
healOther.Activated:Connect(eventModule.clickedHeal)
crouch.Activated:Connect(eventModule.crouch)
crawl.Activated:Connect(eventModule.crawl)
stand.Activated:Connect(eventModule.stand)
