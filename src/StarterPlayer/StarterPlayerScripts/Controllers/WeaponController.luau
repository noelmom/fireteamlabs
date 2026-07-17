--!strict
-- Client side of the firing pipeline (issue #7): sends fire/reload requests
-- with the camera ray and drives ADS FOV. Presentation (ammo, hitmarker,
-- crosshair) lives in HudController, fed by the same remotes and by the
-- signals this controller exposes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local WeaponMath = require(ReplicatedStorage.Shared.Utility.WeaponMath)
local MatchLogic = require(ReplicatedStorage.Shared.Utility.MatchLogic)
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
-- Default true so solo / pre-match play fires; match state flips it (issue #28).
local combatLive = true
local lastAutoReloadClock = 0
local fireRequest: RemoteEvent
local reloadRequest: RemoteEvent

local function tryFire()
	-- Predictive gate only; the server independently enforces all of this.
	if not combatLive then
		-- Trigger does nothing during the pre-round countdown / post-round.
		return
	end

	local weapon = WeaponConfig[currentWeaponId]

	-- Melee: no ammo or reload; the server enforces reach and recovery (#9).
	if weapon.Type == "Melee" then
		local now = os.clock()
		if now - lastShotClock < weapon.SwingDelaySeconds then
			return
		end
		lastShotClock = now
		local camera = workspace.CurrentCamera
		if camera then
			fireRequest:FireServer(camera.CFrame.Position, camera.CFrame.LookVector, false)
			WeaponController.ShotFired:Fire(currentWeaponId)
		end
		return
	end

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
	WeaponController.ShotFired:Fire(currentWeaponId)
end

function WeaponController.Start(_self: any)
	fireRequest = RemoteUtil.getEvent(RemoteNames.FireWeaponRequest)
	reloadRequest = RemoteUtil.getEvent(RemoteNames.ReloadRequest)
	local equipRequest = RemoteUtil.getEvent(RemoteNames.EquipSlotRequest)
	local weaponStateChanged = RemoteUtil.getEvent(RemoteNames.WeaponStateChanged)
	local combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)
	local matchStateChanged = RemoteUtil.getEvent(RemoteNames.MatchStateChanged)

	matchStateChanged.OnClientEvent:Connect(function(matchState: { Phase: string, RoundPhase: string })
		combatLive = MatchLogic.isCombatLive(matchState.Phase, matchState.RoundPhase)
	end)

	InputController:BindAction("Fire", function(began)
		firing = began
	end)

	local function bindSlot(action: string, slot: string)
		InputController:BindAction(action, function(began)
			if began then
				equipRequest:FireServer(slot)
			end
		end)
	end
	bindSlot("SlotPrimary", "Primary")
	bindSlot("SlotSpecial", "Special")
	bindSlot("SlotHeavy", "Heavy")
	bindSlot("SlotKnife", "Knife")

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
		WeaponController.StateUpdated:Fire(state)
	end)

	combatFeedback.OnClientEvent:Connect(function(feedback: { Hit: boolean, Precision: boolean, Eliminated: boolean })
		if feedback.Hit then
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
