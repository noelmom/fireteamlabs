--!strict
-- Placeholder combat audio (issue #23). Plays local sounds for own weapon
-- events and shooter-side hit feedback, 3D positional sounds for other
-- players' shots, and the victim-side shield-break. All sound values come
-- from AudioConfig.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local AudioConfig = require(ReplicatedStorage.Shared.Config.AudioConfig)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)
local WeaponController = require(script.Parent.WeaponController)

local WeaponAudioController = {
	Name = "WeaponAudioController",
}

local random = Random.new()

local function makeSound(def: AudioConfig.SoundDef): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = def.SoundId
	sound.Volume = def.Volume
	local speed = def.PlaybackSpeed
	if def.SpeedJitter then
		speed += random:NextNumber(-def.SpeedJitter, def.SpeedJitter)
	end
	sound.PlaybackSpeed = speed
	return sound
end

local function playLocal(def: AudioConfig.SoundDef)
	local sound = makeSound(def)
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function playAtPosition(def: AudioConfig.SoundDef, position: Vector3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(position)

	local sound = makeSound(def)
	sound.RollOffMaxDistance = def.RollOffMaxDistance or 250
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = holder

	holder.Parent = workspace
	sound:Play()
	Debris:AddItem(holder, 3)
end

function WeaponAudioController.Start(_self: any)
	WeaponController.ShotFired:Connect(function()
		playLocal(AudioConfig.Weapon.Fire)
	end)

	WeaponController.EmptyTriggered:Connect(function()
		playLocal(AudioConfig.Weapon.EmptyClick)
	end)

	local wasReloading = false
	WeaponController.StateUpdated:Connect(function(state: WeaponController.WeaponState)
		if state.Reloading and not wasReloading then
			playLocal(AudioConfig.Weapon.Reload)
		end
		wasReloading = state.Reloading
	end)

	WeaponController.HitConfirmed:Connect(
		function(feedback: { Precision: boolean?, Eliminated: boolean?, ShieldBroken: boolean? })
			if feedback.Eliminated then
				playLocal(AudioConfig.Feedback.Elimination)
			elseif feedback.Precision then
				playLocal(AudioConfig.Feedback.PrecisionHit)
			else
				playLocal(AudioConfig.Feedback.Hit)
			end
		end
	)

	local weaponFired = RemoteUtil.getEvent(RemoteNames.WeaponFiredBroadcast)
	weaponFired.OnClientEvent:Connect(function(payload: { UserId: number, Position: Vector3 })
		if payload.UserId ~= Players.LocalPlayer.UserId then
			playAtPosition(AudioConfig.Weapon.RemoteFire, payload.Position)
		end
	end)

	local lastShield: number? = nil
	local playerStateChanged = RemoteUtil.getEvent(RemoteNames.PlayerStateChanged)
	playerStateChanged.OnClientEvent:Connect(function(state: { Shield: number, Alive: boolean })
		if lastShield and lastShield > 0 and state.Shield <= 0 and state.Alive then
			playLocal(AudioConfig.Feedback.OwnShieldBreak)
		end
		lastShield = state.Shield
	end)
end

return WeaponAudioController
