--!strict
-- Owns per-player durability: shield, health, regeneration, elimination
-- (MASTERPLAN.md section 9). The single entry point for dealing damage;
-- other services must never touch Humanoid.Health directly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)
local DamageMath = require(ReplicatedStorage.Shared.Utility.DamageMath)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)

local ServerScriptService = game:GetService("ServerScriptService")
local TeamService = require(ServerScriptService.Services.TeamService)

local Durability = GameConfig.Durability

export type DamageResult = {
	ShieldDamage: number,
	HealthDamage: number,
	ShieldBroken: boolean,
	Eliminated: boolean,
}

type PlayerState = {
	Shield: number,
	Health: number,
	Alive: boolean,
	LastDamageClock: number,
}

local PlayerStateService = {
	Name = "PlayerStateService",

	-- (victim: Player, attacker: Player?)
	ShieldBroken = Signal.new(),
	-- (victim: Player, attacker: Player?, category: string?)
	Eliminated = Signal.new(),
}

local states: { [Player]: PlayerState } = {}
local playerStateChanged: RemoteEvent
local eliminationBroadcast: RemoteEvent

-- Master combat gate (issue #28). MatchService drives this from match state so
-- no damage lands during the pre-round countdown, post-round, or post-match.
-- Defaults true so free-roam / solo testing deals damage before any match runs.
local combatEnabled = true

local function replicate(player: Player)
	local state = states[player]
	if not state then
		return
	end
	playerStateChanged:FireClient(player, {
		Shield = state.Shield,
		Health = state.Health,
		MaxShield = Durability.MaxShield,
		MaxHealth = Durability.MaxHealth,
		Alive = state.Alive,
	})
end

local function resetDurability(player: Player)
	states[player] = {
		Shield = Durability.MaxShield,
		Health = Durability.MaxHealth,
		Alive = true,
		LastDamageClock = -math.huge,
	}
	replicate(player)
end

local function eliminate(player: Player, attacker: Player?, category: string?)
	local state = states[player]
	if not state or not state.Alive then
		return
	end
	state.Alive = false
	state.Health = 0
	replicate(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end

	-- Feed every client's kill feed / elimination banner (issue #57). Teams are
	-- server-only state, so the colors ride along with the names.
	eliminationBroadcast:FireAllClients({
		Killer = attacker and attacker.Name or nil,
		KillerTeam = attacker and TeamService:GetTeam(attacker) or nil,
		Victim = player.Name,
		VictimTeam = TeamService:GetTeam(player),
		Category = category,
	})

	PlayerStateService.Eliminated:Fire(player, attacker, category)
end

function PlayerStateService.GetState(_self: any, player: Player): PlayerState?
	return states[player]
end

function PlayerStateService.IsAlive(_self: any, player: Player): boolean
	local state = states[player]
	return state ~= nil and state.Alive
end

-- Set by MatchService each time match state changes.
function PlayerStateService.SetCombatEnabled(_self: any, enabled: boolean)
	combatEnabled = enabled
end

function PlayerStateService.IsCombatEnabled(_self: any): boolean
	return combatEnabled
end

-- Applies category-multiplied, shield-before-health damage. Returns nil if
-- the victim has no state or is already eliminated.
function PlayerStateService.ApplyDamage(
	_self: any,
	victim: Player,
	amount: number,
	category: string,
	attacker: Player?
): DamageResult?
	local state = states[victim]
	if not state or not state.Alive or amount <= 0 then
		return nil
	end
	if not combatEnabled then
		-- Combat gated off (pre-round, post-round, post-match). Covers every
		-- damage source since they all route through here (issue #28).
		return nil
	end

	local multiplier = CombatConfig.ShieldMultipliers[category] or 1
	local newShield, newHealth, breakdown = DamageMath.apply(state.Shield, state.Health, amount, multiplier)

	state.Shield = newShield
	state.Health = newHealth
	state.LastDamageClock = os.clock()

	local eliminated = newHealth <= 0

	if breakdown.ShieldBroken then
		PlayerStateService.ShieldBroken:Fire(victim, attacker)
	end

	if eliminated then
		eliminate(victim, attacker, category)
	else
		replicate(victim)
	end

	return {
		ShieldDamage = breakdown.ShieldDamage,
		HealthDamage = breakdown.HealthDamage,
		ShieldBroken = breakdown.ShieldBroken,
		Eliminated = eliminated,
	}
end

local function onCharacterAdded(player: Player, character: Model)
	resetDurability(player)

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		-- Covers deaths outside the damage pipeline (falls, resets).
		eliminate(player, nil, nil)
	end)
end

function PlayerStateService.Init(_self: any)
	playerStateChanged = RemoteUtil.getEvent(RemoteNames.PlayerStateChanged)
	eliminationBroadcast = RemoteUtil.getEvent(RemoteNames.EliminationBroadcast)
end

function PlayerStateService.Start(_self: any)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	local sinceReplication = 0
	RunService.Heartbeat:Connect(function(deltaSeconds)
		sinceReplication += deltaSeconds
		local shouldReplicate = sinceReplication >= 0.1
		if shouldReplicate then
			sinceReplication = 0
		end

		local now = os.clock()
		for player, state in states do
			if not state.Alive then
				continue
			end

			local regenerated = DamageMath.regenStep(
				state.Shield,
				Durability.MaxShield,
				Durability.ShieldRegenPerSecond,
				deltaSeconds,
				now - state.LastDamageClock,
				Durability.ShieldRegenDelaySeconds
			)
			local changed = regenerated ~= state.Shield
			state.Shield = regenerated

			if Durability.HealthRegenEnabled then
				state.Health = DamageMath.regenStep(
					state.Health,
					Durability.MaxHealth,
					Durability.HealthRegenPerSecond,
					deltaSeconds,
					now - state.LastDamageClock,
					Durability.HealthRegenDelaySeconds
				)
			end

			if changed and shouldReplicate then
				replicate(player)
			end
		end
	end)
end

return PlayerStateService
