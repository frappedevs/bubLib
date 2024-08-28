--[=[
	@class playerHumanoidUtil

	A simple utility module for working with the player's humanoid.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local instanceUtil = require(script.Parent.instanceUtil)
local playerEventsUtil = require(script.Parent.playerEventsUtil)

local playerHumanoidUtil = {}

--[=[ 
	Attempts to return the given `player`'s character's humanoid, if found.
]=]

function playerHumanoidUtil.playerHumanoid(player: Player): Humanoid?
	return if player.Character then player.Character:FindFirstChildWhichIsA("Humanoid") else nil
end

--[=[ 
	Promisfied verison of [playerHumanoidUtil.playerHumanoid].

	@return Promise<Humanoid>
]=]

function playerHumanoidUtil.playerHumanoidPromise(player: Player)
	local connections = {}

	local thisPlayerHumanoidPromise = Promise.new(function(resolve)
		local playerHumanoid = playerHumanoidUtil.playerHumanoid(player)
		if playerHumanoid ~= nil then
			resolve(playerHumanoid)
			return
		end

		local onPlayerHumanoidRetrievedSignal = Signal.new()

		table.insert(
			connections,
			playerEventsUtil.usePlayerCharacterAdded(player, function(newCharacter)
				playerHumanoid = playerHumanoidUtil.playerHumanoid(player)

				if playerHumanoid ~= nil then
					onPlayerHumanoidRetrievedSignal:Fire()
				else
					table.insert(
						connections,
						newCharacter.ChildAdded:Connect(function()
							playerHumanoid = playerHumanoidUtil.playerHumanoid(player)

							if playerHumanoid ~= nil then
								onPlayerHumanoidRetrievedSignal:Fire()
							end
						end)
					)
				end
			end)
		)

		Promise.fromEvent(onPlayerHumanoidRetrievedSignal):expect()
		onPlayerHumanoidRetrievedSignal:Destroy()
		resolve(playerHumanoid)
	end)

	thisPlayerHumanoidPromise:finally(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	return thisPlayerHumanoidPromise
end

--[=[ 
   Attempts the seat the `given` player in `seat` if `seat.Occupant` = `nil`. Handles an edgecase
   where [seat:Sit](https://create.roblox.com/docs/reference/engine/classes/Seat#Sit) does not work
   if given humanoid was seated, by unsitting the humanoid through  `humanoid.Sit = false` and then seating the humanoid.
]=]

function playerHumanoidUtil.seatPlayer(player: Player, seat: VehicleSeat | Seat)
	if RunService:IsClient() then
		assert(player == Players.LocalPlayer, "Can only seat local player to a seat")
	end

	local humanoid = playerHumanoidUtil.playerHumanoid(player)

	if humanoid ~= nil and seat.Occupant == nil then
		if humanoid.SeatPart ~= nil then
			humanoid.Sit = false
			humanoid:GetPropertyChangedSignal("SeatPart"):Once(function()
				seat:Sit(humanoid)
			end)
		else
			seat:Sit(humanoid)
		end
	end
end

--[=[ 
	```lua
	playerHumanoidUtil.playerHumanoidSeatPartObserver(player, function(newSeatPlayerIsSittingOn)
		print(player.Name .. " sat on seat " ..tostring(newSeatPlayerIsSittingOn.Name))		
	end, function(newSeatPlayerIsNoLongerSittingOn)
		if newSeatPlayerIsNoLongerSittingOn ~= nil then 
			print(player.Name .. " left seat " ..tostring(newSeatPlayerIsNoLongerSittingOn.Name))		
		end
	end)
	```

	While you can simply listen to [humanoid.SeatPart](https://create.roblox.com/docs/reference/engine/classes/Humanoid#SeatPart), 
	this method accounts for new player character reloading. Returns a cleanup function.
]=]

function playerHumanoidUtil.playerHumanoidSeatPartObserver(
	player: Player,
	observerSeated: ((
		newSeatPlayerIsSittingOn: Seat | VehicleSeat,
		oldSeatPlayerWasSittingOn: (Seat | VehicleSeat)?
	) -> ())?,
	observerUnseated: ((
		newSeatPlayerIsNoLongerSittingOn: (Seat | VehicleSeat)?,
		oldSeatPlayerWasNoLongerSittingOn: (Seat | VehicleSeat)?
	) -> ())?
): () -> ()
	assert(
		observerSeated ~= nil or observerUnseated ~= nil,
		"`observerSeated` and `observerUnseated`: one of them must be specified!"
	)

	local connections = {}
	local lastHumanoidRetrievalPromise = nil

	table.insert(
		connections,
		playerEventsUtil.usePlayerCharacterAdded(player, function(newCharacter)
			if lastHumanoidRetrievalPromise ~= nil then
				lastHumanoidRetrievalPromise:cancel()
			end

			lastHumanoidRetrievalPromise = playerHumanoidUtil
				.playerHumanoidPromise(player)
				:andThen(function(newHumanoid)
					local oldSeatSeated = nil

					table.insert(
						connections,
						instanceUtil.observeProperty(
							newHumanoid,
							"SeatPart",
							function(newSeatPart, oldSeatPart)
								if newSeatPart ~= nil then
									if observerSeated ~= nil then
										observerSeated(newSeatPart, oldSeatPart)
									end
								else
									if observerUnseated ~= nil then
										observerUnseated(oldSeatPart, oldSeatSeated)
										oldSeatSeated = oldSeatPart
									end
								end
							end
						)
					)
				end)
		end)
	)

	return function()
		if lastHumanoidRetrievalPromise ~= nil then
			lastHumanoidRetrievalPromise:cancel()
		end

		for _, connection in connections do
			connection:Disconnect()
		end
	end
end

return table.freeze(playerHumanoidUtil)
