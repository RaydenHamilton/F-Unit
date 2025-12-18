--// Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

--// Functions
local function adminPFpic()
	local Admins = {
		105977445,
		201096477,
	}
	local num = math.random(0, #Admins)
	return tostring(Admins[num])
end

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

	for i, v in pairs(Workspace.Pictures:GetChildren()) do
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local content, isReady = Players:GetUserThumbnailAsync(PlayersFriends[i].Id, thumbType, thumbSize)
		-- set the ImageLabel's content to the user thumbnail
		local imageLabel = v.SurfaceGui.ImageLabel
		imageLabel.Image = (isReady and content)
			or "rbxthumb://type=AvatarHeadShot&id=" .. adminPFpic() .. "&w=420&h=420 true false"
	end
end

player(Players.LocalPlayer)
