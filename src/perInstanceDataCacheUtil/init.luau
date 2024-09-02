--[=[ 
	@class perInstanceDataCacheUtil

	A very simple utility module for storing data unique to every instance in an unique way.
]=]

local cachePerInstance = {}

local perInstanceDataCacheUtil = {}

--[=[
	Returns the data cache for the given `instance`, which is automatically cleaned up once `instance` is destroyed. 
	
	If the data cache for the given `instance` does not exist, it will be initialized with an empty table.
	
	:::tip Uniqueness
	Instance data caches are stored per each instance, uniquely keyed by script names. This means a given 
	instance's cache will always be unique when accessed from different scripts.

	For e.g:

	```lua
	-- Script 1:
	local cache = perInstanceDataCacheUtil.dataCachePerInstance(instance)  
	-- `cache` is an empty table
	
	cache.test = 1

	print(cache) --> {test = 1}


	-- Script 2:
	local cache = perInstanceDataCacheUtil.dataCachePerInstance(instance)  
	-- `cache` is an empty table

	cache.opper = 5
	print(cache) --> {opper = 5} 
	```
	:::

	:::warning
	This method will throw an error if `instance` is not present in game.
	:::
]=]

function perInstanceDataCacheUtil.dataCachePerInstance(instance: Instance)
	assert(
		instance:IsDescendantOf(game),
		string.format('Given instance "%s" must be in game.', instance.Name)
	)

	local file = debug.info(2, "sl")

	if cachePerInstance[instance] ~= nil and cachePerInstance[instance][file] then
		return cachePerInstance[instance][file]
	end

	if cachePerInstance[instance] == nil then
		cachePerInstance[instance] = {}

		instance.Destroying:Connect(function()
			cachePerInstance[instance] = nil
		end)
	end

	cachePerInstance[instance][file] = cachePerInstance[instance][file] or {}
	return cachePerInstance[instance][file]
end

return table.freeze(perInstanceDataCacheUtil)
