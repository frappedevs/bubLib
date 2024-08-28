--[=[ 
	@class badgeServiceUtil

	An utility module for working with [BadgeService](https://create.roblox.com/docs/reference/engine/classes/BadgeService).
]=]

--[=[
	@interface BadgeInfo
	@within badgeServiceUtil	
	.Name string
	.Description string
	.IconImageId string
	.IsEnabled boolean
]=]

--[=[
	@interface DefaultBadgeInfo
	@within badgeServiceUtil	
	.Name ""
	.Description ""
	.IconImageId ""
	.IsEnabled false
]=]

local BadgeService = game:GetService("BadgeService")

local Promise = require(script.Parent.Promise)

local DEFAULT_BADGE_INFO = {
	Name = "",
	Description = "",
	IconImageId = "",
	IsEnabled = false,
}

local badgeServiceUtil = {}

--[=[
	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved wih the badge info of the given
	badge id. This is just a wrapper over [BadgeService:GetBadgeInfoAsync](https://create.roblox.com/docs/reference/engine/classes/BadgeService#GetBadgeInfoAsync).
	
	:::note Promise rejection with default data
	The promise will reject with the [DefaultBadgeInfo] and an error message, instead of just the error message - allowing your code to adapt
	easily incase of failure:

	```lua
	local wasSuccessful, badgeInfo, errorMessage = badgeServiceUtil.badgeInfoPromise(badgeId):await()
	```
	:::

	@return Promise<BadgeInfo>
]=]

function badgeServiceUtil.badgeInfoPromise(badgeId: number)
	return Promise.new(function(resolve, reject)
		local wasSuccessful, response = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, badgeId)

		if wasSuccessful then
			resolve(response)
		else
			reject(DEFAULT_BADGE_INFO, response)
		end
	end)
end

--[=[
	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved wih an array of badge ids the given player owns.
	This is just a wrapper over [BadgeService:GetBadgeInfoAsync](https://create.roblox.com/docs/reference/engine/classes/BadgeService#GetBadgeInfoAsync).

	:::note Promise rejection with default data
	The promise will reject with an empty array and an error message, instead of just the error message - allowing your code to adapt
	easily incase of failure:

	```lua
	local wasSuccessful, playerOwnedBadgeIds, errorMessage = badgeServiceUtil.checkPlayerBadgesPromise(badgeIds):await()
	```
	:::

	@return Promise<{number}>
]=]

function badgeServiceUtil.checkPlayerBadgesPromise(playerUserId: number, badgeIds: { number })
	return Promise.new(function(resolve, reject)
		local wasSuccessful, response =
			pcall(BadgeService.CheckUserBadgesAsync, BadgeService, playerUserId, badgeIds)

		if wasSuccessful then
			resolve(response)
		else
			reject({}, response)
		end
	end)
end

--[=[
	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved wih a boolean indicating
	whether or not the given player has the specified badge or not. This is just a wrapper over 
	[BadgeService:UserHasBadgeAsync](https://create.roblox.com/docs/reference/engine/classes/BadgeService#UserHasBadgeAsync).

	:::note Promise rejection with default data
	The promise will reject with `false` and an error message, instead of just the error message - allowing your code to adapt
	easily incase of failure:

	```lua
	local wasSuccessful, playerHasBadge, errorMessage = badgeServiceUtil.playerHasBadge(badgeId):await()
	```
	:::

	@return Promise<boolean>
]=]

function badgeServiceUtil.playerHasBadge(playerUserId: number, badgeId: number)
	return Promise.new(function(resolve, reject)
		local wasSuccessful, response =
			pcall(BadgeService.UserHasBadgeAsync, BadgeService, playerUserId, badgeId)

		if wasSuccessful then
			resolve(response)
		else
			reject(false, response)
		end
	end)
end

--[=[
	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved once the given player
	has being successfully awarded with the given badge. This is just a wrapper over 
	[BadgeService:AwardBadge](https://create.roblox.com/docs/reference/engine/classes/BadgeService#AwardBadge).

	```lua
	local wasSuccessful, playerWasAwardedBadge = badgeServiceUtil.awardBadgeToPlayer(123, 123):await()
	```

	@return Promise<boolean>
]=]

function badgeServiceUtil.awardBadgeToPlayer(playerUserId: number, badgeId: number)
	return Promise.new(function(resolve)
		resolve(BadgeService:AwardBadge(playerUserId, badgeId))
	end)
end

return table.freeze(badgeServiceUtil)
