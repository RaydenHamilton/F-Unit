--!nocheck
local CreatePart = {}

--// Services
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local tempData = require(script.Parent.TempData)

--// Variables
local highlight = ReplicatedStorage.States.Highlight

CreatePart.makeBillboardGui = function(marker)
	local gui = Instance.new("BillboardGui")
	gui.Parent = marker
	gui.Size = UDim2.fromScale(5, 5)
	gui.AlwaysOnTop = true
	gui.ClipsDescendants = false
	gui.StudsOffset = Vector3.new(0, 4, 0)

	local text = Instance.new("TextLabel")
	text.Parentr = gui
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "0"
	text.TextSize = 30
	return text
end

CreatePart.setUpMarker = function(mouse)
	local marker = Instance.new("Part")
	marker.Parent = Workspace.ClientParts
	marker.Size = Vector3.new(1, 3, 1)
	marker.Anchored = true
	marker.Transparency = 0.5
	marker.Color = Color3.new(0, 0, 1)
	marker.CanCollide = false
	marker.Material = Enum.Material.SmoothPlastic
	mouse.TargetFilter = marker
	return marker
end

CreatePart.SetHighlight = function(
	Parent: Model,
	FillColor: Color3 | boolean,
	OutlineColor: Color3 | boolean,
	DepthMode: boolean
)
	if not highlight.Value then
		highlight.Value = Instance.new("Highlight")
	end
	highlight.Value.FillTransparency = DepthMode and 1 or highlight.Value.FillTransparency
	highlight.Value.Parent = Parent
	highlight.Value.FillColor = FillColor or highlight.Value.OutlineColor
	highlight.Value.OutlineColor = OutlineColor or highlight.Value.OutlineColor
	highlight.Value.DepthMode = DepthMode and "Occluded" or highlight.Value.DepthMode
end

return CreatePart
