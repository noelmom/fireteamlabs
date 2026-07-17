--!strict
-- Single owner of camera FOV so sprint and ADS can't fight over it.
-- ADS wins over sprint; otherwise sprint FOV applies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Movement = GameConfig.Movement
local FOV_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CameraController = {
	Name = "CameraController",
}

local sprinting = false
local adsFov: number? = nil

local function apply()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local target = Movement.NormalFov
	if adsFov then
		target = adsFov
	elseif sprinting then
		target = Movement.SprintFov
	end
	TweenService:Create(camera, FOV_TWEEN, { FieldOfView = target }):Play()
end

function CameraController.SetSprinting(_self: any, value: boolean)
	sprinting = value
	apply()
end

-- Pass a weapon's ADS FOV to enter ADS, nil to leave it.
function CameraController.SetAdsFov(_self: any, value: number?)
	adsFov = value
	apply()
end

function CameraController.Start(_self: any)
	local camera = workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Movement.NormalFov
	end
end

return CameraController
