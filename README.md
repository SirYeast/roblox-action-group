# Roblox Action Group
Have complex systems (placement, fighting) with many context actions? Action groups allow you to group together related actions for easy management and clean up. You should be familiar with the [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService) before using this.

All grouped actions are unique to the group they are in, so a "Shoot" action in group "WeaponSystemV1" is completely different from a "Shoot" action in group "WeaponSystemV2." However, they can still share the same inputs.

## API
```Lua
function ActionGroup.new(groupName: string, priority: number?) -> ActionGroup
```
Returns a new ActionGroup. `groupName` must be unique, two groups cannot have the same name. `priority` is optional, it sets the default priority for actions added to the group.

---
```Lua
function ActionGroup.getGroup(groupName: string) -> ActionGroup?
```
Returns the ActionGroup if it exists, nil otherwise.

---
```Lua
function ActionGroup:SetActionHandler(actionHandler: (actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)->Enum.ContextActionResult)
```
Sets the action handler. Read more about handling actions [here](https://create.roblox.com/docs/reference/engine/classes/ContextActionService#BindAction). Setting a new handler while there are actions bound will rebind them to use the new one.

---
```Lua
function ActionGroup:AddAction(actionName: string, createTouchButton: boolean, priority: number?, ...Enum.KeyCode|Enum.UserInputType)
```
Adds an action or overwrites an existing one. It will not be automatically bound.

---
```Lua
function ActionGroup:BindAction(actionName: string)
```
Binds an action. Will error if an action handler hasn't been set or if the action doesn't exist.

---
```Lua
function ActionGroup:UnbindAction(actionName: string, remove: boolean?)
```
Unbinds an action or does nothing if it doesn't exist. `remove` is optional and defaults to nil (same as false).

---
```Lua
function ActionGroup:IsActionBound(actionName: string) -> boolean
```
Returns a boolean indicating whether the action is bound or not.

---
```Lua
function ActionGroup:BindAllActions()
```
Binds all actions. Will error if an action handler hasn't been set.

---
```Lua
function ActionGroup:UnbindAllActions()
```
Unbinds all actions. They will not be removed and can be rebound at any time.

---
```Lua
function ActionGroup:Destroy()
```
Unbinds all actions, removes the metatable and freezes the group. Method calls after destruction will error. To check if a group is destroyed, use [table.isfrozen()](https://create.roblox.com/docs/reference/engine/libraries/table#isfrozen).

## Example
```Lua
local ActionGroup = require(...)

local viewModelIndex = 0
local viewModelCount = 5

local placementGroup = ActionGroup.new("Placement", 0)
placementGroup:AddAction("Place", false, 1, Enum.UserInputType.MouseButton1)
placementGroup:AddAction("Rotate", false, nil, Enum.KeyCode.R)
placementGroup:AddAction("Previous", false, nil, Enum.KeyCode.Q)
placementGroup:AddAction("Next", false, nil, Enum.KeyCode.E)
placementGroup:AddAction("Cancel", false, nil, Enum.KeyCode.X)

placementGroup:SetActionHandler(function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then
		if actionName == "Place" then
			print("Placing")
		elseif actionName == "Rotate" then
			print("Rotating")
		elseif actionName == "Previous" and viewModelIndex > 0 then
			viewModelIndex -= 1
			print("Switched to previous view model:", viewModelIndex)
		elseif actionName == "Next" and viewModelIndex < viewModelCount then
			viewModelIndex += 1
			print("Switched to next view model:", viewModelIndex)
		else
			placementGroup:UnbindAllActions()
			print("Canceled Placement")
		end
	end
	return Enum.ContextActionResult.Sink
end)

local testGroup = ActionGroup.new("Test")
testGroup:AddAction("EnablePlacement", false, nil, Enum.KeyCode.V)
testGroup:AddAction("DisablePlacement", false, nil, Enum.KeyCode.B)
testGroup:AddAction("IsPlaceEnabled", false, 2, Enum.UserInputType.MouseButton1)
testGroup:AddAction("DestroyGroups", false, nil, Enum.KeyCode.N)

testGroup:SetActionHandler(function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then
		if actionName == "EnablePlacement" then
			placementGroup:BindAllActions()
			print("Enabled Placement")
		elseif actionName == "DisablePlacement" then
			placementGroup:UnbindAllActions()
			print("Disabled Placement")
		elseif actionName == "IsPlaceEnabled" then
			--the statement below will print before "Placing" because it has a higher priority (2)
			print("Placement Enabled:", placementGroup:IsActionBound("Place"))
			--Enum.ContextActionResult.Pass needs to be returned to execute the next highest priority action ("Placing")
			return Enum.ContextActionResult.Pass
		else
			testGroup:Destroy()
			placementGroup:Destroy()
			print("ActionGroups Destroyed")
		end
	end
	return Enum.ContextActionResult.Sink
end)

testGroup:BindAllActions()
```