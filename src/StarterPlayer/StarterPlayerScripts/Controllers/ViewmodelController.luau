--!strict
-- Procedural first-person weapon viewmodel (issue #20). Purely visual:
-- renders a blocky rifle at the camera with hip/ADS/sprint/reload poses,
-- recoil kick, muzzle flash, and rotation-lag sway. No gameplay effect.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementController = require(script.Parent.MovementController)
local WeaponController = require(script.Parent.WeaponController)

local ViewmodelController = {
	Name = "ViewmodelController",
}

-- Poses are offsets from the camera; priority: reload > sprint > ADS > hip.
local HIP_POSE = CFrame.new(1.15, -0.95, -1.7) * CFrame.Angles(0, math.rad(-2), 0)
local ADS_POSE = CFrame.new(0, -0.52, -1.15)
local SPRINT_POSE = CFrame.new(0.85, -1.25, -1.5) * CFrame.Angles(math.rad(-40), math.rad(16), 0)
local RELOAD_POSE = CFrame.new(0.95, -1.3, -1.55) * CFrame.Angles(math.rad(22), 0, math.rad(-18))

local POSE_LERP_SPEED = 12
local RECOIL_KICK = 1
local RECOIL_DECAY = 9
local SWAY_FACTOR = 0.35
local SWAY_DECAY = 10

local DARK = Color3.fromRGB(52, 56, 64)
local MID = Color3.fromRGB(78, 84, 96)
local ACCENT = Color3.fromRGB(90, 180, 255)

local aiming = false
local sprinting = false
local reloading = false
local alive = true

local recoil = 0
local swayPitch = 0
local swayYaw = 0
local lastCameraCFrame: CFrame? = nil
local currentPose = HIP_POSE

local model: Model? = nil
local partOffsets: { [BasePart]: CFrame } = {}
local muzzleFlash: BasePart? = nil

local function block(size: Vector3, offset: CFrame, color: Color3, parent: Model, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	partOffsets[p] = offset
	return p
end

type PartSpec = { Size: Vector3, Offset: CFrame, Color: Color3, Neon: boolean? }
type WeaponBuild = { Parts: { PartSpec }, Muzzle: CFrame }

-- Procedural per-weapon shapes (issue #8). Muzzle is where the flash sits.
local WEAPON_BUILDS: { [string]: WeaponBuild } = {
	AutoRifle = {
		Parts = {
			{ Size = Vector3.new(0.32, 0.42, 1.6), Offset = CFrame.new(0, 0, 0), Color = MID },
			{ Size = Vector3.new(0.28, 0.34, 0.55), Offset = CFrame.new(0, -0.02, 1.0), Color = DARK },
			{ Size = Vector3.new(0.14, 0.14, 1.1), Offset = CFrame.new(0, 0.06, -1.3), Color = DARK },
			{
				Size = Vector3.new(0.22, 0.55, 0.34),
				Offset = CFrame.new(0, -0.42, 0.25) * CFrame.Angles(math.rad(8), 0, 0),
				Color = DARK,
			},
			{ Size = Vector3.new(0.06, 0.14, 0.06), Offset = CFrame.new(0, 0.31, -0.55), Color = ACCENT, Neon = true },
		},
		Muzzle = CFrame.new(0, 0.06, -1.95),
	},
	Shotgun = {
		Parts = {
			{ Size = Vector3.new(0.36, 0.46, 1.3), Offset = CFrame.new(0, 0, 0), Color = MID },
			{ Size = Vector3.new(0.3, 0.36, 0.5), Offset = CFrame.new(0, -0.02, 0.9), Color = DARK },
			{ Size = Vector3.new(0.22, 0.24, 1.2), Offset = CFrame.new(0, 0.06, -1.05), Color = DARK },
			{ Size = Vector3.new(0.26, 0.2, 0.42), Offset = CFrame.new(0, -0.2, -0.6), Color = ACCENT, Neon = true },
			{
				Size = Vector3.new(0.2, 0.5, 0.32),
				Offset = CFrame.new(0, -0.4, 0.2) * CFrame.Angles(math.rad(8), 0, 0),
				Color = DARK,
			},
		},
		Muzzle = CFrame.new(0, 0.06, -1.7),
	},
	RocketLauncher = {
		Parts = {
			{ Size = Vector3.new(0.5, 0.5, 2.3), Offset = CFrame.new(0, 0, -0.2), Color = MID },
			{ Size = Vector3.new(0.56, 0.56, 0.35), Offset = CFrame.new(0, 0, 1.0), Color = DARK },
			{ Size = Vector3.new(0.18, 0.5, 0.32), Offset = CFrame.new(0, -0.44, 0.25), Color = DARK },
			{ Size = Vector3.new(0.08, 0.18, 0.08), Offset = CFrame.new(0, 0.36, -0.3), Color = ACCENT, Neon = true },
		},
		Muzzle = CFrame.new(0, 0, -1.5),
	},
	Knife = {
		Parts = {
			{ Size = Vector3.new(0.12, 0.12, 0.5), Offset = CFrame.new(0, 0, 0.3), Color = DARK },
			{ Size = Vector3.new(0.26, 0.06, 0.08), Offset = CFrame.new(0, 0, 0.05), Color = MID },
			{ Size = Vector3.new(0.05, 0.16, 0.72), Offset = CFrame.new(0, 0.02, -0.42), Color = ACCENT, Neon = true },
		},
		Muzzle = CFrame.new(0, 0, -0.85),
	},
}

local function buildViewmodel(weaponId: string): Model
	local build = WEAPON_BUILDS[weaponId] or WEAPON_BUILDS.AutoRifle
	local viewmodel = Instance.new("Model")
	viewmodel.Name = "Viewmodel"
	partOffsets = {}

	for _, spec in build.Parts do
		block(spec.Size, spec.Offset, spec.Color, viewmodel, spec.Neon)
	end

	local flash = block(Vector3.new(0.3, 0.3, 0.35), build.Muzzle, Color3.fromRGB(255, 190, 90), viewmodel, true)
	flash.Transparency = 1
	flash.Shape = Enum.PartType.Ball
	muzzleFlash = flash

	return viewmodel
end

local function targetPose(): CFrame
	if reloading then
		return RELOAD_POSE
	elseif sprinting then
		return SPRINT_POSE
	elseif aiming then
		return ADS_POSE
	end
	return HIP_POSE
end

local function onRenderStep(deltaSeconds: number)
	local camera = workspace.CurrentCamera
	local rifle = model
	if not camera or not rifle then
		return
	end

	if not alive then
		rifle.Parent = nil
		return
	elseif rifle.Parent == nil then
		rifle.Parent = camera
	end

	-- Rotation-lag sway from camera movement.
	local cameraCFrame = camera.CFrame
	if lastCameraCFrame then
		local delta = lastCameraCFrame:ToObjectSpace(cameraCFrame)
		local pitch, yaw = delta:ToEulerAnglesYXZ()
		swayPitch = math.clamp(swayPitch + pitch * SWAY_FACTOR, -0.06, 0.06)
		swayYaw = math.clamp(swayYaw + yaw * SWAY_FACTOR, -0.08, 0.08)
	end
	lastCameraCFrame = cameraCFrame
	local swayAlpha = math.exp(-SWAY_DECAY * deltaSeconds)
	swayPitch *= swayAlpha
	swayYaw *= swayAlpha

	recoil *= math.exp(-RECOIL_DECAY * deltaSeconds)

	local poseAlpha = 1 - math.exp(-POSE_LERP_SPEED * deltaSeconds)
	currentPose = currentPose:Lerp(targetPose(), poseAlpha)

	local recoilOffset = CFrame.new(0, recoil * 0.05, recoil * 0.22) * CFrame.Angles(math.rad(recoil * 5), 0, 0)
	local swayOffset = CFrame.Angles(-swayPitch, -swayYaw, 0)
	local base = cameraCFrame * swayOffset * currentPose * recoilOffset

	for part, offset in partOffsets do
		part.CFrame = base * offset
	end
end

function ViewmodelController.Start(_self: any)
	local currentWeaponId = "AutoRifle"
	model = buildViewmodel(currentWeaponId)

	WeaponController.ShotFired:Connect(function()
		recoil = math.min(recoil + RECOIL_KICK, 2.5)
		local flash = muzzleFlash
		if flash then
			flash.Transparency = 0
			task.delay(0.05, function()
				flash.Transparency = 1
			end)
		end
	end)

	WeaponController.AimChanged:Connect(function(value: boolean)
		aiming = value
	end)

	WeaponController.StateUpdated:Connect(function(state: WeaponController.WeaponState)
		reloading = state.Reloading
		if state.WeaponId ~= currentWeaponId then
			currentWeaponId = state.WeaponId
			if model then
				model:Destroy()
			end
			model = buildViewmodel(currentWeaponId)
		end
	end)

	MovementController.SprintChanged:Connect(function(value: boolean)
		sprinting = value
	end)

	local player = Players.LocalPlayer
	local function watchCharacter(character: Model)
		alive = true
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			alive = false
		end)
	end
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end

	RunService.RenderStepped:Connect(onRenderStep)
end

return ViewmodelController
