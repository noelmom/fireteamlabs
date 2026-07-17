--!strict
-- Client side of the firing pipeline (issue #7): sends fire/reload requests
-- with the camera ray, drives ADS FOV, and shows a temporary debug HUD
-- (crosshair, hitmarker, ammo) until the real HUD lands in issue #12.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local WeaponMath = require(ReplicatedStorage.Shared.Utility.WeaponMath)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local CameraController = require(script.Parent.CameraController)
local InputController = require(script.Parent.InputController)

export type WeaponState = { WeaponId: string, Magazine: number, Reserve: number, Reloading: boolean }

local WeaponController = {
	Name = "WeaponController",
	-- Client-side events for presentation layers (viewmodel, HUD, audio).
	ShotFired = Signal.new(),
	AimChanged = Signal.new(), -- (aiming: boolean)
	StateUpdated = Signal.new(), -- (state: WeaponState)
	HitConfirmed = Signal.new(), -- (feedback: { Hit, Precision, ShieldBroken, Eliminated })
	EmptyTriggered = Signal.new(), -- fired when attempting to shoot an empty magazine
}

local firing = false
local aiming = false
local lastShotClock = 0
local currentWeaponId = "AutoRifle"
local lastState: WeaponState? = nil
local lastAutoReloadClock = 0
local fireRequest: RemoteEvent
local reloadRequest: RemoteEvent

local ammoLabel: TextLabel
local hitmarker: TextLabel

local function buildDebugHud()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatDebugHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local crosshair = Instance.new("Frame")
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.Position = UDim2.fromScale(0.5, 0.5)
	crosshair.Size = UDim2.fromOffset(4, 4)
	crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshair.BorderSizePixel = 0
	crosshair.Parent = gui

	hitmarker = Instance.new("TextLabel")
	hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
	hitmarker.Position = UDim2.fromScale(0.5, 0.5)
	hitmarker.Size = UDim2.fromOffset(40, 40)
	hitmarker.BackgroundTransparency = 1
	hitmarker.Text = "×"
	hitmarker.TextSize = 32
	hitmarker.TextColor3 = Color3.new(1, 1, 1)
	hitmarker.Visible = false
	hitmarker.Parent = gui

	ammoLabel = Instance.new("TextLabel")
	ammoLabel.AnchorPoint = Vector2.new(1, 1)
	ammoLabel.Position = UDim2.new(1, -24, 1, -24)
	ammoLabel.Size = UDim2.fromOffset(200, 32)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.Text = ""
	ammoLabel.TextSize = 24
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
	ammoLabel.TextColor3 = Color3.new(1, 1, 1)
	ammoLabel.Parent = gui

	gui.Parent = playerGui
end

local function tryFire()
	-- Predictive gate only; the server independently enforces all of this.
	if lastState and lastState.Reloading then
		return
	end
	if lastState and lastState.Magazine <= 0 then
		-- Auto-reload on empty trigger (issue #22), throttled against spam.
		local now = os.clock()
		if now - lastAutoReloadClock >= 0.5 then
			lastAutoReloadClock = now
			WeaponController.EmptyTriggered:Fire()
			if lastState.Reserve > 0 then
				reloadRequest:FireServer()
			end
		end
		return
	end

	local weapon = WeaponConfig[currentWeaponId]
	local interval = WeaponMath.fireIntervalSeconds(weapon.RoundsPerMinute)
	local now = os.clock()
	if now - lastShotClock < interval then
		return
	end
	lastShotClock = now

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	fireRequest:FireServer(camera.CFrame.Position, camera.CFrame.LookVector, aiming)
	WeaponController.ShotFired:Fire()
end

local function flashHitmarker(feedback: { Precision: boolean?, Eliminated: boolean? })
	if feedback.Eliminated then
		hitmarker.TextColor3 = Color3.fromRGB(255, 70, 70)
	elseif feedback.Precision then
		hitmarker.TextColor3 = Color3.fromRGB(255, 210, 80)
	else
		hitmarker.TextColor3 = Color3.new(1, 1, 1)
	end
	hitmarker.Visible = true
	task.delay(0.15, function()
		hitmarker.Visible = false
	end)
end

function WeaponController.Start(_self: any)
	buildDebugHud()

	fireRequest = RemoteUtil.getEvent(RemoteNames.FireWeaponRequest)
	reloadRequest = RemoteUtil.getEvent(RemoteNames.ReloadRequest)
	local weaponStateChanged = RemoteUtil.getEvent(RemoteNames.WeaponStateChanged)
	local combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)

	InputController:BindAction("Fire", function(began)
		firing = began
	end)

	InputController:BindAction("Aim", function(began)
		aiming = began
		local weapon = WeaponConfig[currentWeaponId]
		CameraController:SetAdsFov(if began then weapon.AdsFov else nil)
		WeaponController.AimChanged:Fire(began)
	end)

	InputController:BindAction("Reload", function(began)
		if began then
			reloadRequest:FireServer()
		end
	end)

	weaponStateChanged.OnClientEvent:Connect(function(state: WeaponState)
		currentWeaponId = state.WeaponId
		lastState = state
		ammoLabel.Text = if state.Reloading then "RELOADING…" else `{state.Magazine} / {state.Reserve}`
		WeaponController.StateUpdated:Fire(state)
	end)

	combatFeedback.OnClientEvent:Connect(function(feedback: { Hit: boolean, Precision: boolean, Eliminated: boolean })
		if feedback.Hit then
			flashHitmarker(feedback)
			WeaponController.HitConfirmed:Fire(feedback)
		end
	end)

	RunService.Heartbeat:Connect(function()
		if firing then
			tryFire()
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function()
		firing = false
		aiming = false
		CameraController:SetAdsFov(nil)
		WeaponController.AimChanged:Fire(false)
	end)
end

return WeaponController
