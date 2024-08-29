--[=[
	@class promiseCleanupUtil

	An utility module for working with [Promise](https://eryn.io/roblox-lua-promise/) cleanups.
]=]

local promiseCleanupUtil = {}

--[=[
    @param promise Promise 
    @param cleanupTable {[string]: Promise}

    Adds the given `promise` to `cleanupTable`, indexed by `key`. Once the promise has finished running, it'll be safely
    removed from `cleanupTable`.
]=]

function promiseCleanupUtil.addPromiseAndCleanupOnFinishedRunning(
	promise,
	key: string,
	cleanupTable: {[string]: any}
)
	cleanupTable.playerCustomAnimatorSetupPromise[key] = promise
	promise:finally(function()
		if promise == cleanupTable.playerCustomAnimatorSetupPromise[key] then
			cleanupTable.playerCustomAnimatorSetupPromise[key] = nil
		end
	end)
end

return table.freeze(promiseCleanupUtil)
