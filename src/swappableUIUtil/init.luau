--[=[
	@class swappableUIUtil

	A utility which helps implement swappable UI.
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Trove = require(script.Parent.Trove)

local USER_GUI_OBJECT_HOLD_DURATION_FOR_SELECTION = 0.01
local LAST_GUI_OBJECT_ACTIVE_ATTRIBUTE = "_LastGuiObjectActive"

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local swappableUIUtil = {}

--[=[ 
	Sets up events for swappable gui object dragging where gui object swap their positions.
	This method does not actually change the positions of the gui objects, but rather their
	layout orders, so this method assumes that the gui objects are constrained by a
	[UIListLayout](https://create.roblox.com/docs/reference/engine/classes/UIListLayout).

	Returns a trove object and a callback for updating `targetGuiObjects`.
]=]

function swappableUIUtil.swappable(
	targetGuiObjects: { GuiObject },
	userSwappingObserver: ((
		input: InputObject,
		inputWasProcessed: boolean,
		guiObjectSelectedForSwapping: GuiObject
	) -> ())?,
	userSwappedObserver: ((
		input: InputObject,
		inputWasProcessed: boolean,
		guiObject: GuiObject,
		guiObjectSelectedForSwapping: GuiObject
	) -> ())?,
	userSwapValidator: ((
		guiObject: GuiObject,
		guiObjectSelectedForSwapping: GuiObject
	) -> (boolean?, GuiObject?, GuiObject?))?
)
	local trove = Trove.new()
	local guiObjectSelectedForSwappingConnections = {}
	local guiObjectSelectedForSwapping = nil
	local guiObjectHoldDurationClock = nil

	local function updateGuiObjectSelectedForSwapping(newGuiObjectSelectedForSwapping)
		if guiObjectSelectedForSwapping ~= nil and newGuiObjectSelectedForSwapping == nil then
			local lastActive =
				guiObjectSelectedForSwapping:GetAttribute(LAST_GUI_OBJECT_ACTIVE_ATTRIBUTE)
			guiObjectSelectedForSwapping.Active = if lastActive ~= nil
				then lastActive
				else guiObjectSelectedForSwapping.Active
			guiObjectSelectedForSwapping:SetAttribute(LAST_GUI_OBJECT_ACTIVE_ATTRIBUTE, nil)
		end

		guiObjectSelectedForSwapping = newGuiObjectSelectedForSwapping

		for _, connection in guiObjectSelectedForSwappingConnections do
			connection:Disconnect()
		end

		table.remove(guiObjectSelectedForSwappingConnections)

		if guiObjectSelectedForSwapping == nil then
			return
		end

		table.insert(
			guiObjectSelectedForSwappingConnections,
			guiObjectSelectedForSwapping.Destroying:Connect(function()
				if guiObjectSelectedForSwapping == newGuiObjectSelectedForSwapping then
					guiObjectSelectedForSwapping = nil
				end
			end)
		)
	end

	trove:Add(function()
		for _, connection in guiObjectSelectedForSwappingConnections do
			connection:Disconnect()
		end
	end)

	trove:Add(UserInputService.InputChanged:Connect(function(input, inputWasProcessed)
		if guiObjectSelectedForSwapping == nil then
			return
		end

		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if
			(Workspace:GetServerTimeNow() - guiObjectHoldDurationClock)
			< USER_GUI_OBJECT_HOLD_DURATION_FOR_SELECTION
		then
			guiObjectHoldDurationClock = Workspace:GetServerTimeNow()
			return
		end

		if userSwappingObserver ~= nil then
			userSwappingObserver(input, inputWasProcessed, guiObjectSelectedForSwapping)
		end

		local guiObjectsAtPosition =
			playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)

		for _, guiObject in guiObjectsAtPosition do
			if
				table.find(targetGuiObjects, guiObject) ~= nil
				and guiObject ~= guiObjectSelectedForSwapping
			then
				if userSwapValidator ~= nil then
					local shouldAllowSwap, potentialNewGuiObject, potentialNewGuiObjectSelectedForSwapping =
						userSwapValidator(guiObject, guiObjectSelectedForSwapping)
					if not shouldAllowSwap then
						continue
					end

					if
						potentialNewGuiObject ~= nil
						and potentialNewGuiObjectSelectedForSwapping ~= nil
					then
						guiObject = potentialNewGuiObject
						updateGuiObjectSelectedForSwapping(potentialNewGuiObjectSelectedForSwapping)
					end
				end

				local guiObjectLayoutOrder = guiObject.LayoutOrder
				guiObject.LayoutOrder = guiObjectSelectedForSwapping.LayoutOrder
				guiObjectSelectedForSwapping.LayoutOrder = guiObjectLayoutOrder

				if
					guiObjectSelectedForSwapping:GetAttribute(LAST_GUI_OBJECT_ACTIVE_ATTRIBUTE)
					== nil
				then
					guiObjectSelectedForSwapping:SetAttribute(
						LAST_GUI_OBJECT_ACTIVE_ATTRIBUTE,
						guiObjectSelectedForSwapping.Active
					)
				end

				guiObjectSelectedForSwapping.Active = false

				if userSwappedObserver ~= nil then
					userSwappedObserver(
						input,
						inputWasProcessed,
						guiObject,
						guiObjectSelectedForSwapping
					)

					updateGuiObjectSelectedForSwapping(nil)
				end
			end
		end
	end))

	trove:Add(UserInputService.InputBegan:Connect(function(input, inputWasProcessed)
		if not inputWasProcessed then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local guiObjectsAtPosition =
				playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)

			for _, guiObject in guiObjectsAtPosition do
				if table.find(targetGuiObjects, guiObject) == nil then
					continue
				end

				guiObjectHoldDurationClock = Workspace:GetServerTimeNow()
				updateGuiObjectSelectedForSwapping(guiObject)
				break
			end
		end
	end))

	trove:Add(UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			updateGuiObjectSelectedForSwapping(nil)
			guiObjectHoldDurationClock = nil
		end
	end))

	return trove, function(newTargetGuiObjects)
		targetGuiObjects = newTargetGuiObjects
	end
end

return table.freeze(swappableUIUtil)
