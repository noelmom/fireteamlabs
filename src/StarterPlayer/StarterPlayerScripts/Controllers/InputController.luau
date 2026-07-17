--!strict
-- Central input abstraction (MASTERPLAN.md section 10). The only module on
-- the client allowed to touch UserInputService; gameplay code binds to named
-- actions so gamepad, mobile, and rebinding can be added here later.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Keybinds = require(ReplicatedStorage.Shared.Constants.Keybinds)

export type ActionName =
	"Jump"
	| "Sprint"
	| "Crouch"
	| "Fire"
	| "Aim"
	| "Reload"
	| "SlotPrimary"
	| "SlotSpecial"
	| "SlotHeavy"
	| "SlotKnife"
	| "Grenade"
	| "ClassAbility"
	| "Interact"
	| "CommWheel"
	| "Scoreboard"

type Handler = (began: boolean) -> ()

local InputController = {
	Name = "InputController",
}

local keyToAction: { [Enum.KeyCode]: ActionName } = {}
for action, keyCode in Keybinds :: { [string]: Enum.KeyCode } do
	keyToAction[keyCode] = action :: ActionName
end

local handlers: { [ActionName]: { Handler } } = {}

-- Mouse buttons are not KeyCodes; map them explicitly.
local mouseButtonActions: { [Enum.UserInputType]: ActionName } = {
	[Enum.UserInputType.MouseButton1] = "Fire",
	[Enum.UserInputType.MouseButton2] = "Aim",
}

function InputController.BindAction(_self: any, action: ActionName, handler: Handler)
	local list = handlers[action]
	if not list then
		list = {}
		handlers[action] = list
	end
	table.insert(list, handler)
end

local function dispatch(action: ActionName?, began: boolean)
	if not action then
		return
	end
	local list = handlers[action]
	if not list then
		return
	end
	for _, handler in list do
		task.spawn(handler, began)
	end
end

local function actionFromInput(input: InputObject): ActionName?
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return keyToAction[input.KeyCode]
	end
	return mouseButtonActions[input.UserInputType]
end

function InputController.Start(_self: any)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed then
			dispatch(actionFromInput(input), true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, _gameProcessed)
		-- Releases dispatch even when the UI consumed them, so held states
		-- (sprint, crouch, fire) can never stick.
		dispatch(actionFromInput(input), false)
	end)
end

return InputController
