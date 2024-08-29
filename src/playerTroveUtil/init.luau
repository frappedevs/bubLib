--[=[ 
	@class playerTroveUtil

	An utility module for working with player troves.
]=]

local Players = game:GetService("Players")

local Trove = require(script.Parent.Trove)

local playerTroves = {}

local playerTroveUtil = {}

--[=[
	Returns the given `player`'s trove. If one does not exist, it'll be creatd for the given `player`. This trove
    will be automatically cleaned up once `player` is destroyed.

    :::warning Potential error
    This method will throw an error if `player` is not present in game.
    :::
]=]

function playerTroveUtil.playerTrove(player: Player)
	assert(
		player:IsDescendantOf(Players),
		string.format('Given player "%s" must be in game.', player.Name)
	)

	if playerTroves[player] ~= nil then
		return playerTroves[player]
	end

	local playerTrove = Trove.new()
	playerTrove:AttachToInstance(player)
	playerTroves[player] = playerTrove

	playerTrove:Add(function()
		playerTroves[player] = nil
	end)

	return playerTrove
end

return table.freeze(playerTroveUtil)
