--!strict
local SoldierClass = require(game.ServerStorage.SoldierClass)
type SoldierData = SoldierClass.SoldierData

local SoldierPathFinding = {}

function SoldierPathFinding.PathFiding(dest, soldierData: SoldierData, magnitude)
	SoldierPathFinding.SetUnderlay(soldierData)
	soldierData.Soldier:SetAttribute("Building", false)
	soldierData.Soldier:SetAttribute("Healing", false)
	soldierData.Soldier:SetAttribute("PlantingBomb", false)

	if dest then
		soldierData.path:ComputeAsync(soldierData.Soldier.Underlay.Position, dest)
		if soldierData.path.Status == Enum.PathStatus.Success then
			local waypoints = soldierData.path:GetWaypoints()
			for index, point in ipairs(waypoints) do
				soldierData.Soldier.Humanoid:MoveTo(point.Position)
				-- Wait until the Soldier reaches the point or stop is triggered
				while (soldierData.Soldier.HumanoidRootPart.Position - point.Position).magnitude > 5 do
					if
						soldierData.stopWalking
						or (index == #waypoints and (soldierData.Soldier.HumanoidRootPart.Position - point.Position).magnitude <= 1)
						or (magnitude and (soldierData.Soldier.HumanoidRootPart.Position - dest).magnitude < magnitude)
					then
						if not soldierData.closesEnemy then
							soldierData.Soldier["Hammer"].Transparency = 1
							soldierData.Soldier["Handle"].Transparency = 0
						end
						return true
					end
					task.wait() -- Give some time for movement
				end
			end
		else
			warn("Pathfinding failed, recalculating...")
			return false
			-- Optional: Try again after a delay or find a new path
		end
	end
	return true
end

function SoldierPathFinding.SetUnderlay(soldierData: SoldierData)
	local raycastResult = workspace:Raycast(
		soldierData.HumanoidRootPart.Position + Vector3.new(0, -2, 0),
		Vector3.new(0, -9999999, 0),
		soldierData.ShotRules
	)
	soldierData.Soldier.Underlay.CFrame = CFrame.new(
		raycastResult.Position + Vector3.new(0.001),
		(raycastResult.Position + Vector3.new(0.001)) + raycastResult.Normal
	) * CFrame.Angles(math.rad(-90), 0, math.rad(-0))
end

return SoldierPathFinding
