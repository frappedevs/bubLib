--[=[ 
	@class CustomAnimator

	A simple class for working with animations.
	
	```lua
	local playerHumanoidCustomAnimator = CustomAnimator.new(humanoidAnimator)
	local track = playerHumanoidCustomAnimator:loadAnimation(animation)
	track:Play()
	```
]=]

--[=[ 
	@type CustomAnimator CustomAnimator 
	@within CustomAnimator
]=]

--[=[ 
	@prop onAnimationLoaded Signal
	@tag CustomAnimator Instance 
	@within CustomAnimator
]=]

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local instanceTroveUtil = require(script.Parent.instanceTroveUtil)

local ANIM_FADE_TIME_ATTRIBUTE = "FadeTime"
local ANIM_WEIGHT_TIME_ATTRIBUTE = "Weight"
local ANIM_SPEED_TIME_ATTRIBUTE = "Speed"

local CustomAnimator = {}
CustomAnimator.__index = {}

--[=[ 
	Creates and returns a new custom animator object. 

	@return CustomAnimator
]=]

function CustomAnimator.new(animator: Animator | AnimationController)
	assert(
		typeof(animator) == "Instance"
			and (animator:IsA("Animator") or animator:IsA("AnimationController")),
		string.format(
			"Bad argument to 'animator', expected Animator object, got %s",
			typeof(animator)
		)
	)

	return setmetatable({
		_animator = animator,
		_loadedAnimationTracks = {},
		onAnimationLoaded = Signal.new(),
	}, CustomAnimator)
end

--[=[ 
	@tag CustomAnimator instance

	Returns the given loaded animation track from the animation, if found.
]=]

function CustomAnimator.__index:animationTrack(animation: Animation): AnimationTrack?
	return self._loadedAnimationTracks[animation]
end

--[=[ 
	@tag CustomAnimator instance

	Returns a promise which is resolved once the given animation is loaded via [CustomAnimator:loadAnimation].

	:::note Automatic promise cancellation
	The returned promise will be cancelled if the animator object or the animation controller object this custom
	animator is connected to, is destroyed.
	:::

	@return Promise<AnimationTrack>
]=]

function CustomAnimator.__index:onAnimationLoadPromise(animation: Animation)
	local animatorTrove = instanceTroveUtil.instanceTrove(self._animator)
	return animatorTrove:AddPromise(Promise.new(function(resolve)
		while self._loadedAnimationTracks[animation] == nil do
			self.onAnimationLoaded:Wait()
		end

		resolve(self._loadedAnimationTracks[animation])
	end))
end

--[=[ 
	@tag CustomAnimator instance

	Loads in the animation as an animation track.
]=]

function CustomAnimator.__index:loadAnimation(animation: Animation): AnimationTrack
	local animationTrack: AnimationTrack = self._animator:LoadAnimation(animation)
	self._loadedAnimationTracks[animation] = animationTrack
	self.onAnimationLoaded:Fire(animation)
	return animationTrack
end

--[=[ 
	@tag CustomAnimator instance

	Plays the given animation, if it has been loaded into the animator object via [CustomAnimator:loadAnimation].

	:::tip
	You can also setup attributes for `fadeTime`, `weight`, and `speed` in the animation object, 
	which will be used incase the arguments aren't specified.

	- `fadeTime` -> `FadeTime`
	- `weight` -> `Weight`
	- `speed` -> `Speed`
	:::
]=]

function CustomAnimator.__index:playLoadedAnimation(
	animation: Animation,
	fadeTime: number?,
	weight: number?,
	speed: number?
): AnimationTrack
	local animationTrack: AnimationTrack = self:animationTrack(animation)
	assert(
		animationTrack,
		string.format('Animation track "%s" cannot be played as it is not loaded!', animation.Name)
	)

	fadeTime = fadeTime or animation:GetAttribute(ANIM_FADE_TIME_ATTRIBUTE)
	weight = weight or animation:GetAttribute(ANIM_WEIGHT_TIME_ATTRIBUTE)
	speed = speed or animation:GetAttribute(ANIM_SPEED_TIME_ATTRIBUTE)

	animationTrack:Play(fadeTime, weight, speed)
	return animationTrack
end

--[=[ 
	@tag CustomAnimator instance
	@return Promise<>

	Plays the given `animation` as soon as it is loaded into the custom animator.

	:::note Automatic promise cancellation
	The returned promise will be cancelled if the animator object or the animation controller object this custom
	animator is connected to, is destroyed.
	:::
]=]

function CustomAnimator.__index:playAnimationOnLoad(
	animation: Animation,
	fadeTime: number?,
	weight: number?,
	speed: number?
): AnimationTrack?
	return self:onAnimationLoadPromise(animation):andThen(function()
		self:playLoadedAnimation(animation, fadeTime, weight, speed)
	end)
end

--[=[ 
	@tag CustomAnimator instance

	Stops the given animation, if it has been loaded into the custom animator object.

	:::tip
	You can also setup an attribute for `fadeTime` in the animation object, which will be used incase `fadeTime` isn't specified.

	- `fadeTime` -> `FadeTime`
	:::
]=]

function CustomAnimator.__index:stopLoadedAnimation(animation: Animation, fadeTime: number?)
	local animationTrack: AnimationTrack = self:animationTrack(animation)
	assert(
		animationTrack,
		string.format('Animation track "%s" cannot be stopped as it is not loaded!', animation.Name)
	)

	fadeTime = fadeTime or animation:GetAttribute(ANIM_FADE_TIME_ATTRIBUTE)
	animationTrack:Stop(fadeTime)
end

--[=[ 
	@tag CustomAnimator instance

	Works almost exactly the same as [CustomAnimator:stopLoadedAnimation], but does not error if `animation`
	is not loaded into the custom animator.
]=]

function CustomAnimator.__index:tryStopAnimation(animation: Animation, fadeTime: number?)
	local animationTrack: AnimationTrack = self:animationTrack(animation)
	if animationTrack == nil then
		return
	end

	fadeTime = fadeTime or animation:GetAttribute(ANIM_FADE_TIME_ATTRIBUTE)
	animationTrack:Stop(fadeTime)
end

--[=[ 
	@tag CustomAnimator instance

	Stops all loaded animations by calling [CustomAnimator:stopAnimation] on each loaded animation.
]=]

function CustomAnimator.__index:stopAll(fadeTime: number?)
	for animation in self._loadedAnimationTracks do
		self:stopAnimation(animation, fadeTime)
	end
end

--[=[ 
	@tag CustomAnimator instance

	Returns a read only copy dictionary of all animations loaded into the animator object.
]=]

function CustomAnimator.__index:all(): { [Animation]: AnimationTrack }
	return table.freeze(table.clone(self._loadedAnimationTracks))
end

--[=[ 
	@tag CustomAnimator instance

	Stops the given animation track if loaded, and destroys it. 
]=]

function CustomAnimator.__index:cleanupAnimationTrack(animation: Animation)
	local animationTrack: AnimationTrack? = self:animationTrack(animation)

	if animationTrack then
		animationTrack:Stop()
		animationTrack:Destroy()
	end

	self._loadedAnimationTracks[animation] = nil
end

--[=[ 
	@tag CustomAnimator instance

	Returns the animator associated to the animator object.
]=]

function CustomAnimator.__index:animator(): Animator
	return self._animator
end

--[=[ 
	@tag CustomAnimator instance
	
	Destroys the custom animator object and renders it unusuable. Additionally, [CustomAnimator:cleanupAnimationTrack] is called
	on all loaded animation tracks too.
]=]

function CustomAnimator.__index:destroy()
	for animation in table.clone(self._loadedAnimationTracks) do
		self:cleanupAnimationTrack(animation)
	end

	self.onAnimationLoaded:Destroy()
	setmetatable(self, nil)
end

export type CustomAnimator = typeof(CustomAnimator.new(Instance.new("Animator")))

return table.freeze(CustomAnimator)
