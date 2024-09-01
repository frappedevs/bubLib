--[=[ 
    @class playerHumanoidWalkSpeedUtil

    A very simple utility module for working with player humanoid walkspeed multipliers.
]=]

--[=[ 
    @prop PLAYER_BASE_HUMANOID_WALK_SPEED StarterPlayer.CharacterWalkSpeed
    @tag Constant
    @within playerHumanoidWalkSpeedUtil

    [StarterPlayer.CharacterWalkSpeed](https://create.roblox.com/docs/reference/engine/classes/StarterPlayer#CharacterWalkSpeed)

    :::warning Not Accessible
    Constant, not accesible within `playerHumanoidWalkSpeedUtil`.
    :::
]=]

--[=[ 
    @prop PLAYER_BASE_HUMANOID_WALK_SPEED_MULTIPLIER 1
    @tag Constant
    @within playerHumanoidWalkSpeedUtil

    :::warning Not Accessible
    Constant, not accesible within `playerHumanoidWalkSpeedUtil`.
    :::
]=]

local StarterPlayer = game:GetService("StarterPlayer")

local instanceAttributeUtil = require(script.Parent.instanceAttributeUtil)
local playerHumanoidUtil = require(script.Parent.playerHumanoidUtil)

local PLAYER_HUMANOID_WALK_SPEED_MULTIPLIER_ATTRIBUTE = "PlayerHumanoidWalkSpeedMultiplier"
local PLAYER_HUMANOID_BASE_WALK_SPEED_ATTRIBUTE = "PlayerHumanoidBaseWalkSpeed"
local PLAYER_BASE_HUMANOID_WALK_SPEED_MULTIPLIER = 1
local PLAYER_BASE_HUMANOID_WALK_SPEED = StarterPlayer.CharacterWalkSpeed

local playerHumanoidWalkSpeedUtil = {}

--[=[ 
    Returns the given `player`'s new humanoid walkspeed based off of the humanoid walkspeed multiplier and the humanoid base walkspeed.
]=]

function playerHumanoidWalkSpeedUtil.updatedPlayerHumanoidWalkSpeed(player: Player): number
	local humanoid = playerHumanoidUtil.playerHumanoid(player)

	local thisPlayerHumanoidWalkSpeedMultiplier =
		playerHumanoidWalkSpeedUtil.playerHumanoidWalkSpeedMultiplier(player)
	local thisPlayerHumanoidBaseWalkSpeed =
		playerHumanoidWalkSpeedUtil.playerHumanoidBaseWalkSpeed(player)

	local speedDifference = (
		thisPlayerHumanoidBaseWalkSpeed * thisPlayerHumanoidWalkSpeedMultiplier
	) - humanoid.WalkSpeed

	return humanoid.WalkSpeed + speedDifference
end

--[=[ 
    Returns the default player humanoid base walk speed.

    @return PLAYER_BASE_HUMANOID_WALK_SPEED
]=]

function playerHumanoidWalkSpeedUtil.defaultPlayerHumanoidBaseWalkSpeed(): number
	return PLAYER_BASE_HUMANOID_WALK_SPEED
end

--[=[ 
    Returns the default player humanoid walkspeed multiplier.

    @return PLAYER_BASE_HUMANOID_WALK_SPEED_MULTIPLIER
]=]

function playerHumanoidWalkSpeedUtil.defaultPlayerHumanoidWalkSpeedMultiplier(): number
	return PLAYER_BASE_HUMANOID_WALK_SPEED_MULTIPLIER
end

--[=[ 
    Sets the given `player`'s humanoid's base walkspeed to `playerBaseHumanoidWalkSpeed`.
]=]

function playerHumanoidWalkSpeedUtil.setPlayerBaseHumanoidWalkSpeed(
	player: Player,
	playerBaseHumanoidWalkSpeed: number
)
	player:SetAttribute(PLAYER_HUMANOID_BASE_WALK_SPEED_ATTRIBUTE, playerBaseHumanoidWalkSpeed)
end

--[=[ 
    Sets the given `player`'s humanoid's walkspeed multiplier to `walkSpeedMultiplier`.
]=]

function playerHumanoidWalkSpeedUtil.setPlayerHumanoidWalkSpeedMultiplier(
	player: Player,
	walkSpeedMultiplier: number
)
	player:SetAttribute(PLAYER_HUMANOID_WALK_SPEED_MULTIPLIER_ATTRIBUTE, walkSpeedMultiplier)
end

--[=[ 
    Returns the given `player`'s humanoid's walkspeed multiplier set or `0` if no walkspeed multiplier is set.
]=]

function playerHumanoidWalkSpeedUtil.playerHumanoidWalkSpeedMultiplier(player: Player): number
	return player:GetAttribute(PLAYER_HUMANOID_WALK_SPEED_MULTIPLIER_ATTRIBUTE)
		or PLAYER_BASE_HUMANOID_WALK_SPEED_MULTIPLIER
end

--[=[ 
    Returns the given `player`'s humanoid's base walkspeed set or [StarterPlayer.CharacterWalkSpeed](https://create.roblox.com/docs/reference/engine/classes/StarterPlayer#CharacterWalkSpeed) 
    if no base humanoid walkspeed is set.
]=]

function playerHumanoidWalkSpeedUtil.playerHumanoidBaseWalkSpeed(player: Player): number
	return player:GetAttribute(PLAYER_HUMANOID_BASE_WALK_SPEED_ATTRIBUTE)
		or PLAYER_BASE_HUMANOID_WALK_SPEED
end

--[=[ 
    Observes the given `player`'s humanoid's walkspeed multiplier.

    ```lua
    playerHumanoidWalkSpeedUtil.observePlayerHumanoidWalkSpeedMultiplier(player, function(newPlayerHumanoidWalkspeedMultiplier, oldPlayerHumanoidWalkspeedMultiplier) 
        
    end)
    ```
]=]

function playerHumanoidWalkSpeedUtil.observePlayerHumanoidWalkSpeedMultiplier(
	player: Player,
	observer: (
		newPlayerHumanoidWalkspeedMultiplier: number,
		oldPlayerHumanoidWalkspeedMultiplier: number?
	) -> ()
): RBXScriptConnection
	if player:GetAttribute(PLAYER_HUMANOID_WALK_SPEED_MULTIPLIER_ATTRIBUTE) == nil then
		task.spawn(
			observer,
			playerHumanoidWalkSpeedUtil.playerHumanoidWalkSpeedMultiplier(player),
			nil
		)
	end

	return (
		instanceAttributeUtil.observe(
			player,
			PLAYER_HUMANOID_WALK_SPEED_MULTIPLIER_ATTRIBUTE,
			function(
				thisNewPlayerHumanoidWalkspeedMultiplier,
				thisOldPlayerHumanoidWalkspeedMultiplier
			)
				if
					thisNewPlayerHumanoidWalkspeedMultiplier
					== playerHumanoidWalkSpeedUtil.playerHumanoidBaseWalkSpeed(player)
				then
					return
				end

				observer(
					thisNewPlayerHumanoidWalkspeedMultiplier,
					thisOldPlayerHumanoidWalkspeedMultiplier
				)
			end
		)
	)
end

--[=[ 
    Observes the given `player`'s humanoid's base walkspeed.

    ```lua
    playerHumanoidWalkSpeedUtil.observePlayerHumanoidBaseWalkSpeed(player, function(newPlayerHumanoidWalkspeedMultiplier, oldPlayerHumanoidWalkspeedMultiplier) 
        
    end)
    ```
]=]

function playerHumanoidWalkSpeedUtil.observePlayerHumanoidBaseWalkSpeed(
	player: Player,
	observer: (
		newPlayerHumanoidBaseWalkspeed: number,
		oldPlayerHumanoidBaseWalkspeed: number?
	) -> ()
): RBXScriptConnection
	if player:GetAttribute(PLAYER_HUMANOID_BASE_WALK_SPEED_ATTRIBUTE) == nil then
		task.spawn(observer, playerHumanoidWalkSpeedUtil.playerHumanoidBaseWalkSpeed(player), nil)
	end

	return (
		instanceAttributeUtil.observe(
			player,
			PLAYER_HUMANOID_BASE_WALK_SPEED_ATTRIBUTE,
			function(thisNewPlayerHumanoidBaseWalkspeed, thisOldPlayerHumanoidBaseWalkspeed)
				if
					thisNewPlayerHumanoidBaseWalkspeed
					== playerHumanoidWalkSpeedUtil.playerHumanoidBaseWalkSpeed(player)
				then
					return
				end

				observer(thisNewPlayerHumanoidBaseWalkspeed, thisOldPlayerHumanoidBaseWalkspeed)
			end
		)
	)
end

return table.freeze(playerHumanoidWalkSpeedUtil)
