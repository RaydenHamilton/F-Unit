local function player(friends: Player)
	local players = game:GetService("Players")
	local PlayersFriends = {}

	local success, page = pcall(function()
		return players:GetFriendsAsync(friends.UserId)
	end)

	if success then
		repeat
			local info = page:GetCurrentPage()
			for _, friendInfo in pairs(info) do
				table.insert(PlayersFriends, friendInfo)
			end
			if not page.IsFinished then
				page:AdvanceToNextPageAsync()
			end
		until page.IsFinished
	end

	for i, v in pairs(game.Workspace.Pictures:GetChildren()) do
		local PLACEHOLDER_IMAGE = "rbxassetid://0" -- replace with placeholder image
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local content, isReady = game.Players:GetUserThumbnailAsync(PlayersFriends[i].Id, thumbType, thumbSize)
		-- set the ImageLabel's content to the user thumbnail
		local imageLabel = v.SurfaceGui.ImageLabel
		imageLabel.Image = (isReady and content)
			or "rbxthumb://type=AvatarHeadShot&id=" .. adminPFpic() .. "&w=420&h=420 true false"
	end
end

function adminPFpic()
	local Admins = {
		105977445,
		201096477,
	}
	local num = math.random(0, #Admins)
	return tostring(Admins[num])
end

player(game.Players.LocalPlayer)
