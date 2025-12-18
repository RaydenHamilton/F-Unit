--!nocheck
local CreatePart = {}

local Workspace = game:GetService("Workspace")

local tempData = require(script.Parent.TempData)

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
	if not tempData.characterHighlight then
		tempData.characterHighlight = Instance.new("Highlight")
	end
	tempData.characterHighlight.FillTransparency = DepthMode and 1 or tempData.characterHighlight.FillTransparency
	tempData.characterHighlight.Parent = Parent
	tempData.characterHighlight.FillColor = FillColor or tempData.characterHighlight.OutlineColor
	tempData.characterHighlight.OutlineColor = OutlineColor or tempData.characterHighlight.OutlineColor
	tempData.characterHighlight.DepthMode = DepthMode and "Occluded" or tempData.characterHighlight.DepthMode
end

return CreatePart
