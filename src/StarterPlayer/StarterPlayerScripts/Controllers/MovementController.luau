--!strict
-- Sprint/crouch state and speeds, sprint FOV (MASTERPLAN.md section 10).
-- Values come from GameConfig.Movement; the server independently validates
-- resulting speeds in MovementValidationService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local InputController = require(script.Parent.InputController)

local Movement = GameConfig.Movement
local FOV_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

local function currentFov(): number
	if sprinting and not crouching then
		return Movement.SprintFov
	end
	return Movement.NormalFov
end

local function apply()
	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = currentSpeed()
	end

	local camera = workspace.CurrentCamera
	if camera then
		TweenService:Create(camera, FOV_TWEEN, { FieldOfView = currentFov() }):Play()
	end
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

	local camera = workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Movement.NormalFov
	end
end

return MovementController
