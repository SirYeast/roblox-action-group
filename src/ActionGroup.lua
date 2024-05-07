--!strict
local ContextAction = game:GetService("ContextActionService")

type ActionHandler = (actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)->Enum.ContextActionResult

type ActionGroupImpl = {
	__index: ActionGroupImpl,
	new: (groupName: string, priority: number?)->ActionGroup,
	getGroup: (groupName: string)->ActionGroup?,
	SetActionHandler: (self: ActionGroup, actionHandler: ActionHandler)->(),
	AddAction: (self: ActionGroup, actionName: string, createTouchButton: boolean, priority: number?, ...Enum.KeyCode|Enum.UserInputType)->(),
	BindAction: (self: ActionGroup, actionName: string)->(),
	UnbindAction: (self: ActionGroup, actionName: string, remove: boolean?)->(),
	IsActionBound: (self: ActionGroup, actionName: string)->boolean,
	BindAllActions: (self: ActionGroup)->(),
	UnbindAllActions: (self: ActionGroup)->(),
	Destroy: (self: ActionGroup)->()
}

type Action = {
	_fullName: string, --groupName + actionName
	_inputs: {Enum.KeyCode|Enum.UserInputType},
	_priority: number?,
	_hasTouchButton: boolean?,
}

export type ActionGroup = typeof(setmetatable({}::{
	_name: string,
	_actionHandler: ActionHandler?,
	_actions: {[string]: Action},
	_priority: number?
}, {}::ActionGroupImpl))

local actionGroups: {[string]: ActionGroup} = {}

local ActionGroup: ActionGroupImpl = {}::ActionGroupImpl
ActionGroup.__index = ActionGroup

function ActionGroup.new(groupName, priority)
	if actionGroups[groupName] then
		error("Unable to create new action group '"..groupName.."' as it already exists.")
	end

	return setmetatable({
		_name = groupName,
		_actions = {},
		_priority = priority
	}, ActionGroup)
end

function ActionGroup.getGroup(groupName)
	return actionGroups[groupName]
end

function ActionGroup:SetActionHandler(actionHandler)
	local previous = self._actionHandler
	self._actionHandler = function(actionFullName, inputState, inputObject)
		return actionHandler(actionFullName:sub(self._name:len() + 1, actionFullName:len()), inputState, inputObject)
	end

	if not previous then return end
	--rebind all bound actions to use new action handler
	for actionName, action in self._actions do
		if next(ContextAction:GetBoundActionInfo(action._fullName)) then
			self:BindAction(actionName)
		end
	end
end

function ActionGroup:AddAction(actionName, createTouchButton, priority, ...)
	local action = self._actions[actionName]
	if not action then
		action = {}::Action
		self._actions[actionName] = action
	end

	action._fullName = self._name..actionName
	action._priority = priority
	action._hasTouchButton = createTouchButton
	action._inputs = {...}
end

function ActionGroup:BindAction(actionName)
	if not self._actionHandler then
		error("Unable to bind action as no action handler has been set in group: "..self._name)
	end

	local action = self._actions[actionName]
	if not action then
		error("Unable to bind action '"..actionName.."' as it doesn't exist in group: "..self._name)
	end

	local priority = action._priority or self._priority

	if not priority then
		ContextAction:BindAction(action._fullName, self._actionHandler, action._hasTouchButton, table.unpack(action._inputs))
	else
		ContextAction:BindActionAtPriority(action._fullName, self._actionHandler, action._hasTouchButton, priority, table.unpack(action._inputs))
	end
end

function ActionGroup:UnbindAction(actionName, remove)
	local action = self._actions[actionName]
	if not action then return end

	ContextAction:UnbindAction(action._fullName)

	if remove then
		self._actions[actionName] = nil
	end
end

function ActionGroup:IsActionBound(actionName)
	local action = self._actions[actionName]
	return action and next(ContextAction:GetBoundActionInfo(action._fullName)) ~= nil
end

function ActionGroup:BindAllActions()
	for actionName, _ in self._actions do
		self:BindAction(actionName)
	end
end

function ActionGroup:UnbindAllActions()
	for _, action in self._actions do
		ContextAction:UnbindAction(action._fullName)
	end
end

function ActionGroup:Destroy()
	actionGroups[self._name] = nil

	self:UnbindAllActions()
	self._actionHandler = nil

	setmetatable(self::any, nil)
	table.freeze(self)
end

return ActionGroup