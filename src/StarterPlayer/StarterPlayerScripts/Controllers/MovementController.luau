--!strict
-- Sprint/crouch state and speeds (MASTERPLAN.md section 10). Values come
-- from GameConfig.Movement; FOV goes through CameraController; the server
-- independently validates resulting speeds in MovementValidationService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local CameraController = require(script.Parent.CameraController)
local InputController = require(script.Parent.InputController)

local Movement = GameConfig.Movement

local MovementController = {
	Name = "MovementController",
}

local sprinting = false
local crouching = false

local function currentSpeed(): number
	-- Crouch wins over sprint; you cannot sprint while crouched.
	if crouching then
		return Movement.CrouchSpeed
	elseif sprinting then
		return Movement.SprintSpeed
	end
	return Movement.WalkSpeed
end

local function apply()
	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = currentSpeed()
	end
	CameraController:SetSprinting(sprinting and not crouching)
end

function MovementController.Start(_self: any)
	InputController:BindAction("Sprint", function(began)
		sprinting = began
		apply()
	end)

	InputController:BindAction("Crouch", function(began)
		crouching = began
		apply()
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function()
		sprinting = false
		crouching = false
		task.defer(apply)
	end)
end

return MovementController
