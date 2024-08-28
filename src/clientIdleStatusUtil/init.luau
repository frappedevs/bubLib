--[=[ 
	@class clientIdleStatusUtil
	
	A simple utility module around the [Player.Idled](https://create.roblox.com/docs/reference/engine/classes/Player#Idled) event.
]=]

--[=[ 
	@interface IdleStatus
	@within clientIdleStatusUtil
	.Idle "Idle"
	.UnIdle "UnIdle" 
]=]

--[=[ 
	@prop idleStatusProperty Property <newIdleStatus: string, oldIdleStatus: string?>
	@within clientIdleStatusUtil
	@readonly

	A [property](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value of the property is 
	set to a new one. The signal is only passed the new value as the only argument.
]=]

local Players = game:GetService("Players")

local Property = require(script.Parent.Property)

local PLAYER_IDLED_EVENT_SUCCESSIVE_FIRE_TIME_INTERVAL = 30 + 2 --- Additional 2 seconds just to be on the safe side

local localPlayer = Players.LocalPlayer

local IdleStatus = {
	Idle = "Idle",
	UnIdle = "UnIdle",
}

local clientIdleStatusUtil = {
	IdleStatus = IdleStatus,
	idleStatusProperty = Property.new(IdleStatus.UnIdle),
}

do
	local playerIdledSignalRefireThread = nil
	localPlayer.Idled:Connect(function()
		if playerIdledSignalRefireThread ~= nil then
			task.cancel(playerIdledSignalRefireThread)
		end

		clientIdleStatusUtil.idleStatusProperty:set(clientIdleStatusUtil.IdleStatus.Idle)

		playerIdledSignalRefireThread = task.delay(
			PLAYER_IDLED_EVENT_SUCCESSIVE_FIRE_TIME_INTERVAL,
			function()
				clientIdleStatusUtil.idleStatusProperty:set(clientIdleStatusUtil.IdleStatus.UnIdle)
			end
		)
	end)
end

return table.freeze(clientIdleStatusUtil)
