--!strict
-- Server-authoritative class abilities (issue #10, MASTERPLAN.md section 15).
-- Each class has one charged melee ability on F with a shared cooldown; classes
-- are otherwise identical. The server validates cooldown, alive state, and the
-- combat gate, then resolves the ability:
--   Specter  - Flechette:  a thrown blade projectile with gravity drop.
--   Conduit  - Surge Bolt: a bolt projectile dealing direct damage + burn.
--   Bulwark  - Kinetic Ram: a forward lunge; walls stop it, contact damages.
-- Abilities never change health, shield, movement, hitbox, weapon, or grenades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassConfig = require(ReplicatedStorage.Shared.Config.ClassConfig)
local AbilityLogic = require(ReplicatedStorage.Shared.Utility.AbilityLogic)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local PlayerStateService = require(ServerScriptService.Services.PlayerStateService)

local ABILITY_CATEGORY = "ClassAbility"
local MAX_ORIGIN_OFFSET_STUDS = 8
local DEFAULT_CLASS = "Specter"

type Feedback = { Hit: boolean, Precision: boolean, ShieldBroken: boolean, Eliminated: boolean }

type ClassState = {
	ClassId: string,
	CooldownEnd: number, -- server time the ability becomes ready
}

type Projectile = {
	Owner: Player,
	Character: Model,
	Kind: string, -- "Flechette" | "SurgeBolt"
	Ability: any,
	Position: Vector3,
	Velocity: Vector3,
	Drop: number, -- downward accel (studs/s^2)
	Life: number,
	Part: BasePart,
}

local AbilityService = {
	Name = "AbilityService",
}

local classStates: { [Player]: ClassState } = {}
local projectiles: { Projectile } = {}
local projectileFolder: Folder

local abilityStateChanged: RemoteEvent
local abilityEffect: RemoteEvent
local combatFeedback: RemoteEvent

local function newFeedback(): Feedback
	return { Hit = false, Precision = false, ShieldBroken = false, Eliminated = false }
end

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function victimFromResult(result: RaycastResult, shooter: Player): (Player?, boolean)
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local victim = model and Players:GetPlayerFromCharacter(model)
	if victim and victim ~= shooter then
		return victim, result.Instance.Name == "Head"
	end
	return nil, false
end

local function applyHit(owner: Player, victim: Player, damage: number, feedback: Feedback)
	local result = PlayerStateService:ApplyDamage(victim, damage, ABILITY_CATEGORY, owner)
	if result then
		feedback.Hit = true
		feedback.ShieldBroken = feedback.ShieldBroken or result.ShieldBroken
		feedback.Eliminated = feedback.Eliminated or result.Eliminated
	end
end

local function excludeParams(character: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, projectileFolder }
	return params
end

local function replicate(player: Player)
	local state = classStates[player]
	if not state then
		return
	end
	local class = ClassConfig.Classes[state.ClassId]
	abilityStateChanged:FireClient(player, {
		ClassId = state.ClassId,
		AbilityName = class.Ability.Name,
		CooldownEnd = state.CooldownEnd,
	})
end

-- Projectile spawner shared by Flechette and Surge Bolt.
local function spawnProjectile(
	player: Player,
	character: Model,
	origin: Vector3,
	direction: Vector3,
	kind: string,
	ability: any,
	speed: number,
	drop: number,
	color: Color3
)
	local part = Instance.new("Part")
	part.Name = kind
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(origin)
	part.Parent = projectileFolder

	table.insert(projectiles, {
		Owner = player,
		Character = character,
		Kind = kind,
		Ability = ability,
		Position = origin,
		Velocity = direction * speed,
		Drop = drop,
		Life = 4,
		Part = part,
	})
end

local function startBurn(owner: Player, victim: Player, ability: any)
	for tick = 1, ability.BurnTicks do
		task.delay(ability.BurnTickIntervalSeconds * tick, function()
			if PlayerStateService:IsAlive(victim) then
				PlayerStateService:ApplyDamage(victim, ability.BurnDamagePerTick, ABILITY_CATEGORY, owner)
			end
		end)
	end
end

local function onProjectileHit(projectile: Projectile, victim: Player, isPrecision: boolean)
	local ability = projectile.Ability
	local feedback = newFeedback()
	if projectile.Kind == "Flechette" then
		local damage = if isPrecision then ability.PrecisionDamage else ability.BodyDamage
		applyHit(projectile.Owner, victim, damage, feedback)
	elseif projectile.Kind == "SurgeBolt" then
		applyHit(projectile.Owner, victim, ability.DirectDamage, feedback)
		startBurn(projectile.Owner, victim, ability)
	end
	if feedback.Hit then
		combatFeedback:FireClient(projectile.Owner, feedback)
	end
end

local function updateProjectiles(deltaSeconds: number)
	for index = #projectiles, 1, -1 do
		local projectile = projectiles[index]
		projectile.Life -= deltaSeconds
		projectile.Velocity -= Vector3.new(0, projectile.Drop * deltaSeconds, 0)
		local step = projectile.Velocity * deltaSeconds

		local params = excludeParams(projectile.Character)
		local result = workspace:Raycast(projectile.Position, step, params)

		local finished = false
		if result then
			local victim, isPrecision = victimFromResult(result, projectile.Owner)
			if victim then
				onProjectileHit(projectile, victim, isPrecision)
			end
			finished = true
		else
			projectile.Position += step
			projectile.Part.CFrame = CFrame.new(projectile.Position)
			finished = projectile.Life <= 0
		end

		if finished then
			projectile.Part:Destroy()
			table.remove(projectiles, index)
		end
	end
end

local function doLunge(player: Player, character: Model, direction: Vector3, ability: any)
	local root = character.PrimaryPart
	if not root then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	flat = flat.Unit

	-- Contact damage: a wall along the path blocks the ram (can't pass through).
	local result = workspace:Raycast(root.Position, flat * ability.LungeStuds, excludeParams(character))
	local feedback = newFeedback()
	if result then
		local victim = victimFromResult(result, player)
		if victim then
			applyHit(player, victim, ability.Damage, feedback)
		end
	end
	combatFeedback:FireClient(player, feedback)

	-- Movement is applied by the owning client (it has network ownership of its
	-- character); walls stop the dash via physics.
	abilityEffect:FireClient(player, { Kind = "Lunge", Direction = flat, Studs = ability.LungeStuds })
end

local function onUseAbility(player: Player, origin: unknown, direction: unknown)
	local state = classStates[player]
	if not state or not PlayerStateService:IsAlive(player) or not PlayerStateService:IsCombatEnabled() then
		return
	end
	if not AbilityLogic.isReady(serverNow(), state.CooldownEnd) then
		return
	end
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	local originVector = origin :: Vector3
	local directionVector = direction :: Vector3
	if directionVector.Magnitude < 1e-3 or directionVector.X ~= directionVector.X then
		return
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not character or not head then
		return
	end
	if (originVector - head.Position).Magnitude > MAX_ORIGIN_OFFSET_STUDS then
		return
	end

	local class = ClassConfig.Classes[state.ClassId]
	local ability = class.Ability
	local unit = directionVector.Unit

	if state.ClassId == "Specter" then
		spawnProjectile(
			player,
			character,
			originVector,
			unit,
			"Flechette",
			ability,
			ability.ProjectileSpeed,
			ability.ProjectileDropStudsPerSecond,
			Color3.fromRGB(180, 220, 255)
		)
	elseif state.ClassId == "Conduit" then
		spawnProjectile(
			player,
			character,
			originVector,
			unit,
			"SurgeBolt",
			ability,
			ability.ProjectileSpeed,
			0,
			Color3.fromRGB(255, 140, 70)
		)
	elseif state.ClassId == "Bulwark" then
		doLunge(player, character, unit, ability)
	end

	state.CooldownEnd = serverNow() + ClassConfig.AbilityCooldownSeconds
	replicate(player)
end

local function onSetClass(player: Player, classId: unknown)
	local state = classStates[player]
	if not state or typeof(classId) ~= "string" or not ClassConfig.Classes[classId] then
		return
	end
	-- Class locks once the round is live; changes only during prep phases (#38).
	if PlayerStateService:IsCombatEnabled() then
		return
	end
	state.ClassId = classId
	replicate(player)
end

function AbilityService.Init(_self: any)
	abilityStateChanged = RemoteUtil.getEvent(RemoteNames.AbilityStateChanged)
	abilityEffect = RemoteUtil.getEvent(RemoteNames.AbilityEffect)
	combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)

	projectileFolder = Instance.new("Folder")
	projectileFolder.Name = "AbilityProjectiles"
	projectileFolder.Parent = workspace

	RemoteUtil.getEvent(RemoteNames.UseAbilityRequest).OnServerEvent:Connect(onUseAbility)
	RemoteUtil.getEvent(RemoteNames.SetClassRequest).OnServerEvent:Connect(onSetClass)
end

function AbilityService.Start(_self: any)
	local function ensureState(player: Player)
		if not classStates[player] then
			classStates[player] = { ClassId = DEFAULT_CLASS, CooldownEnd = 0 }
		end
	end

	Players.PlayerAdded:Connect(function(player)
		ensureState(player)
		player.CharacterAdded:Connect(function()
			-- Fresh ability each spawn.
			local state = classStates[player]
			if state then
				state.CooldownEnd = 0
				replicate(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		classStates[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaSeconds)
		if #projectiles > 0 then
			updateProjectiles(deltaSeconds)
		end
	end)
end

return AbilityService
