--[=[ 
	@class playerRefUtil

	A simple utility module for retrieving player refs. Best suited for code that need to run
	during invocation point of player object cleanup code.
]=]

local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)
local playerEventsUtil = require(script.Parent.playerEventsUtil)

local playerRefs = {}
local onPlayerRefCreated = Signal.new()

local playerRefUtil = {}

--[=[ 
	Promisified version of `playerRefUtil.playerRef`.
]=]

function playerRefUtil.playerRefPromise(playerUserId: number)
	return Promise.new(function(resolve)
		while playerRefs[playerUserId] == nil do
			onPlayerRefCreated:Wait()
		end

		resolve(playerRefs[playerUserId])
	end)
end

--[=[ 
   Returns the player ref from `playerUserId`.
]=]

function playerRefUtil.playerRef(playerUserId: number): Player?
	return playerRefs[playerUserId]
end

playerEventsUtil.usePlayerAdded(function(player)
	playerRefs[player.UserId] = player

	player.Destroying:Connect(function()
		task.defer(function()
			playerRefs[player.UserId] = nil
		end)
	end)
end)

return table.freeze(playerRefUtil)
