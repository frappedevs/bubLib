--[=[ 
	@class playerCacheUtil

	A very simple utility module for storing in data per player in an unique way.
 
	```lua
	local cache = playerCacheUtil.cacheForPlayer(player.UserId)  
	cache.test = 1

	print(cache.test) --> 1 
	```
]=]

local Players = game:GetService("Players")

local cachePerPlayer = {}

local playerCacheUtil = {}

--[=[
	Returns the cache for the given player. 
	
	:::tip Uniqueness
	Player caches are stored per each player, uniquely keyed by script names. This means a player's cache 
	will always be unique when accessed from different scripts.

	For e.g:

	```lua
	-- Script 1:
	local cache = playerCacheUtil.cacheForPlayer(player)  
	cache.test = 1

	print(cache) --> {test = 1}


	-- Script 2:
	local cache = playerCacheUtil.cacheForPlayer(player)  
	cache.opper = 5
	print(cache) --> {opper = 5} 
	```
	:::

	:::warning Potential error
    This method will throw an error if `player` is not present in game.
    :::
]=]

function playerCacheUtil.cacheForPlayer(player: Player)
	assert(
		player:IsDescendantOf(Players),
		string.format('Given player "%s" must be in game.', player.Name)
	)

	cachePerPlayer[player] = cachePerPlayer[player] or {}

	local file = debug.info(2, "sl")
	cachePerPlayer[player][file] = cachePerPlayer[player][file] or {}
	return cachePerPlayer[player][file]
end

Players.PlayerRemoving:Connect(function(player: Player)
	cachePerPlayer[player] = nil
end)

return table.freeze(playerCacheUtil)
