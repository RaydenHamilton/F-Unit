--// Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

--// Varubles
local Modules = Players.LocalPlayer.PlayerScripts.Client
local player = Players.LocalPlayer
local botGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local actions = botGui.Actions
local position = botGui.Position
local mouse = player:GetMouse()
local Highlight = ReplicatedStorage.States.Highlight
local checkSpawnSize = Vector3.new(20, 20, 20)
local colorWhite = Color3.new(1, 1, 1)
local colorBlack = Color3.new(0, 0, 0)
local selectionBox
local selectionConnection

--// Modules
local createEffects = require(Modules.CreateEffects)
local ClientStates = require(Modules.ClientStates)
local miscFunctions = require(Modules.MiscFunctions)
local eventModule = require(Modules.EventModule)
local logicModule = require(Modules.LogicModule)

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
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Targets[player.UserId], Workspace.Map }
	params.IgnoreWater = true
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return result
end

local function ShowRange(target)
	local frameCounter = 0
	ClientStates.selected = RunService.RenderStepped:Connect(function()
		frameCounter += 1
		if frameCounter % 3 == 0 then
			createEffects.ShowRange(target, target:GetAttribute("Range"), 3)
		end
	end)
end

--continue tomorrow
local function changeSoldier()
	for _, soldier in ClientStates.squad do
		player.PlayerGui.ShopUI.Enabled = false

		local Walls = soldier:GetAttribute("Walls")
		local Meds = soldier:GetAttribute("Meds")

		player.PlayerGui.Main.Heals.Number.Text = Meds
		player.PlayerGui.Main.Walls.Number.Text = Walls

		soldier.Underlay.Color = Color3.new(1, 1, 1)
		botGui.Enabled = true
		local ShotRules = RaycastParams.new()
		ShotRules.FilterDescendantsInstances = {
			ClientStates.squad,
		}
		ShotRules.FilterType = Enum.RaycastFilterType.Exclude
		ShotRules.IgnoreWater = true
		-- ShowRange(target)
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
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = { Workspace.Targets }
	local getTouchingParts = Workspace:GetPartBoundsInBox(spawnModel.PrimaryPart.CFrame, checkSpawnSize, Params)
	return #getTouchingParts == 0
end

local function OpenShopUI()
	player.PlayerGui.ShopUI.Enabled = true
	Highlight.Value.OutlineColor = colorWhite
end
local function isVector2InFrame(point, frame: Frame)
	local min = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
	local max = min - Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
	return (point.X >= min.X and point.X <= max.X and point.Y >= min.Y and point.Y <= max.Y)
end

local function selectInBox()
	local selectedTable = {}
	miscFunctions.unselect()
	for num, soldier in Workspace.Targets[player.UserId]:GetChildren() do
		local vector3, onscreen = camera:WorldToViewportPoint(soldier:GetPivot().Position)
		if onscreen and isVector2InFrame(vector3, selectionBox) then
			table.insert(selectedTable, soldier)
			if num == 10 then
				break
			end
		end
	end
	return selectedTable
end

local function getSquadData(): { Wall: number, Meds: number }
	local squadData = {
		Wall = 0,
		Meds = 0,
	}
	for _, soldier in ClientStates.squad do
		squadData.Wall += soldier:GetAttribute("Walls")
		squadData.Meds += soldier:GetAttribute("Meds")
	end
	return squadData
end

local function onLeftClick()
	selectionConnection:Disconnect()
	print(selectionBox.size.X.Offset, selectionBox.size.Y.Offset)
	if selectionBox.size.X.Offset > -10 and selectionBox.size.Y.Offset > -10 then
		if SpawnHighlighted() then
			--// check if there are players near spawn
			if NoSoldiersNearSpawn() then
				OpenShopUI()
				return
			else
				FlashOutLine()
				return
			end
		elseif ClientStates.PlacingWall then
			eventModule.placeWall()
			return
		elseif ClientStates.HealingTeammate then
			eventModule.hoverHealableWho()
			return
		end
		miscFunctions.unselect()
	else
		ClientStates.squad = selectInBox()
		changeSoldier()
		ClientStates.squadData = getSquadData()
	end
	selectionBox:Destroy()
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

local function selectionBoxEvent()
	local frame, mouseX, mouseY = createEffects.CreateselectionBox()
	selectionBox = frame
	selectionConnection = RunService.Heartbeat:Connect(function()
		frame.Size = UDim2.fromOffset(mouseX - mouse.X, mouseY - mouse.Y)
	end)
end

--// Events
UserInputService.InputChanged:Connect(inputChanged)

mouse.Button1Down:Connect(selectionBoxEvent)
mouse.Button1Up:Connect(onLeftClick)
mouse.Button2Up:Connect(onRightClick)

wallButton.Activated:Connect(eventModule.clickedPlaceWall)
selfHeal.Activated:Connect(eventModule.clickSelfHeal)
healOther.Activated:Connect(eventModule.clickedHeal)
crouch.Activated:Connect(eventModule.crouch)
crawl.Activated:Connect(eventModule.crawl)
stand.Activated:Connect(eventModule.stand)
