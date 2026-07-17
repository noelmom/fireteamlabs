--!strict
-- Server-authoritative firing pipeline (issues #7, #8; MASTERPLAN.md sections
-- 11 and 20). Each player carries a loadout of weapons in slots and switches
-- between them; the server enforces fire rate, ammo, origin sanity, applies
-- spread, and resolves damage through PlayerStateService. Firing dispatches by
-- weapon Type: Hitscan (single ray), Shotgun (many pellets), Projectile (a
-- server-simulated rocket with splash).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local WeaponMath = require(ReplicatedStorage.Shared.Utility.WeaponMath)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local PlayerStateService = require(ServerScriptService.Services.PlayerStateService)

-- Tolerances for legitimate network jitter; anything beyond is rejected.
local FIRE_INTERVAL_TOLERANCE = 0.92
local MAX_ORIGIN_OFFSET_STUDS = 8

-- Default loadout: which weapon fills each slot (issue #8). Knife slot lands
-- with #9.
local SLOT_WEAPONS: { [string]: string } = {
	Primary = "AutoRifle",
	Special = "Shotgun",
	Heavy = "RocketLauncher",
	Knife = "Knife",
}
local SLOT_ORDER = { "Primary", "Special", "Heavy", "Knife" }

type SlotState = {
	WeaponId: string,
	Magazine: number, -- -1 means unlimited (melee)
	Reserve: number,
	LastFireClock: number,
	Reloading: boolean,
	NextReadyClock: number, -- melee: earliest time the next swing is allowed
}

type Loadout = {
	Slots: { [string]: SlotState },
	ActiveSlot: string,
	Generation: number, -- invalidates pending reloads across respawns
}

type Feedback = {
	Hit: boolean,
	Precision: boolean,
	ShieldBroken: boolean,
	Eliminated: boolean,
}

type Projectile = {
	Owner: Player,
	Character: Model,
	Weapon: any,
	Position: Vector3,
	Velocity: Vector3,
	Life: number,
	Part: BasePart,
}

local WeaponService = {
	Name = "WeaponService",
}

local loadouts: { [Player]: Loadout } = {}
local projectiles: { Projectile } = {}
local projectileFolder: Folder
local random = Random.new()

local weaponStateChanged: RemoteEvent
local combatFeedback: RemoteEvent
local weaponFiredBroadcast: RemoteEvent

local function newFeedback(): Feedback
	return { Hit = false, Precision = false, ShieldBroken = false, Eliminated = false }
end

local function activeState(player: Player): (SlotState?, any)
	local loadout = loadouts[player]
	if not loadout then
		return nil, nil
	end
	local slot = loadout.Slots[loadout.ActiveSlot]
	if not slot then
		return nil, nil
	end
	return slot, WeaponConfig[slot.WeaponId]
end

local function replicate(player: Player)
	local slot = activeState(player)
	if not slot then
		return
	end
	local loadout = loadouts[player]
	weaponStateChanged:FireClient(player, {
		WeaponId = slot.WeaponId,
		Slot = loadout.ActiveSlot,
		Magazine = slot.Magazine,
		Reserve = slot.Reserve,
		Reloading = slot.Reloading,
	})
end

local function resetLoadout(player: Player)
	local previous = loadouts[player]
	local slots: { [string]: SlotState } = {}
	for _, slotId in SLOT_ORDER do
		local weaponId = SLOT_WEAPONS[slotId]
		local weapon: any = WeaponConfig[weaponId]
		local isMelee = weapon.Type == "Melee"
		slots[slotId] = {
			WeaponId = weaponId,
			Magazine = if isMelee then -1 else weapon.MagazineSize,
			Reserve = if isMelee then -1 else weapon.ReserveAmmo,
			LastFireClock = 0,
			Reloading = false,
			NextReadyClock = 0,
		}
	end
	loadouts[player] = {
		Slots = slots,
		ActiveSlot = "Primary",
		Generation = (previous and previous.Generation or 0) + 1,
	}
	replicate(player)
end

local function characterParts(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character, head, humanoid
end

local function applySpread(direction: Vector3, degrees: number): Vector3
	local radians = math.rad(degrees)
	local cframe = CFrame.lookAlong(Vector3.zero, direction)
		* CFrame.Angles(random:NextNumber(-radians, radians), random:NextNumber(-radians, radians), 0)
	return cframe.LookVector
end

local function victimFromResult(result: RaycastResult, shooter: Player): (Player?, boolean)
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local victim = model and Players:GetPlayerFromCharacter(model)
	if victim and victim ~= shooter then
		return victim, result.Instance.Name == "Head"
	end
	return nil, false
end

local function applyHit(
	shooter: Player,
	victim: Player,
	damage: number,
	isPrecision: boolean,
	slot: string,
	feedback: Feedback
)
	local result = PlayerStateService:ApplyDamage(victim, damage, slot, shooter)
	if result then
		feedback.Hit = true
		feedback.Precision = feedback.Precision or isPrecision
		feedback.ShieldBroken = feedback.ShieldBroken or result.ShieldBroken
		feedback.Eliminated = feedback.Eliminated or result.Eliminated
	end
end

-- One raycast; used by hitscan and per shotgun pellet.
local function fireRay(
	shooter: Player,
	character: Model,
	origin: Vector3,
	direction: Vector3,
	weapon: any,
	baseDamage: number,
	feedback: Feedback
)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, projectileFolder }

	local result = workspace:Raycast(origin, direction * weapon.MaxRangeStuds, params)
	if not result then
		return
	end
	local victim, isPrecision = victimFromResult(result, shooter)
	if not victim then
		return
	end
	local distance = (result.Position - origin).Magnitude
	local falloff = WeaponMath.falloffScale(
		weapon.FalloffStartStuds,
		weapon.FalloffEndStuds,
		weapon.FalloffMinDamageScale,
		distance
	)
	local damage = WeaponMath.damage(baseDamage, weapon.PrecisionMultiplier, isPrecision, falloff)
	applyHit(shooter, victim :: Player, damage, isPrecision, weapon.Slot, feedback)
end

local function explodeRocket(projectile: Projectile, position: Vector3, directVictim: Player?)
	local weapon = projectile.Weapon
	local owner = projectile.Owner
	local feedback = newFeedback()

	if directVictim then
		applyHit(owner, directVictim, weapon.DirectDamage, false, weapon.Slot, feedback)
	end

	for _, other in Players:GetPlayers() do
		if other == owner or other == directVictim or not PlayerStateService:IsAlive(other) then
			continue
		end
		local character = other.Character
		local root = character and character.PrimaryPart
		if not root then
			continue
		end
		local toTarget = root.Position - position
		local distance = toTarget.Magnitude
		if distance > weapon.SplashRadiusStuds then
			continue
		end
		-- Obstruction: ignore the target's own body so only walls block the blast.
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, projectileFolder }
		local blocked = workspace:Raycast(position, toTarget, params)
		if blocked then
			continue
		end
		local damage =
			WeaponMath.splashDamage(weapon.SplashMaxDamage, weapon.SplashMinDamage, weapon.SplashRadiusStuds, distance)
		applyHit(owner, other, damage, false, weapon.Slot, feedback)
	end

	if feedback.Hit then
		combatFeedback:FireClient(owner, feedback)
	end
end

local function spawnRocket(player: Player, character: Model, origin: Vector3, direction: Vector3, weapon: any)
	local part = Instance.new("Part")
	part.Name = "Rocket"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.8, 0.8, 0.8)
	part.Color = Color3.fromRGB(255, 170, 60)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false -- raycasts ignore all rockets
	part.CanTouch = false
	part.CFrame = CFrame.new(origin)
	part.Parent = projectileFolder

	table.insert(projectiles, {
		Owner = player,
		Character = character,
		Weapon = weapon,
		Position = origin,
		Velocity = direction * weapon.ProjectileSpeed,
		Life = weapon.ProjectileLifetimeSeconds,
		Part = part,
	})
end

local function updateProjectiles(deltaSeconds: number)
	for index = #projectiles, 1, -1 do
		local projectile = projectiles[index]
		projectile.Life -= deltaSeconds
		local step = projectile.Velocity * deltaSeconds

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { projectile.Character, projectileFolder }
		local result = workspace:Raycast(projectile.Position, step, params)

		local explodeAt: Vector3? = nil
		local directVictim: Player? = nil
		if result then
			explodeAt = result.Position
			directVictim = victimFromResult(result, projectile.Owner)
		else
			projectile.Position += step
			projectile.Part.CFrame = CFrame.new(projectile.Position)
			if projectile.Life <= 0 then
				explodeAt = projectile.Position
			end
		end

		if explodeAt then
			explodeRocket(projectile, explodeAt, directVictim)
			projectile.Part:Destroy()
			table.remove(projectiles, index)
		end
	end
end

-- Melee swing (issue #9): server-validated forward reach; a hit swings on the
-- base cadence, a whiff adds the recovery delay. No ammo, no reload.
local function doMelee(
	player: Player,
	character: Model,
	head: BasePart,
	origin: Vector3,
	direction: Vector3,
	weapon: any,
	slot: SlotState
)
	local now = os.clock()
	if now < slot.NextReadyClock then
		return
	end
	weaponFiredBroadcast:FireAllClients({ UserId = player.UserId, Position = head.Position, WeaponId = slot.WeaponId })

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, projectileFolder }
	local result = workspace:Raycast(origin, direction * weapon.RangeStuds, params)

	local feedback = newFeedback()
	if result then
		local victim = victimFromResult(result, player)
		if victim then
			applyHit(player, victim, weapon.Damage, false, weapon.Slot, feedback)
		end
	end

	local recovery = if feedback.Hit then 0 else weapon.MissRecoverySeconds
	slot.NextReadyClock = now + weapon.SwingDelaySeconds + recovery
	combatFeedback:FireClient(player, feedback)
end

local function onFireRequest(player: Player, origin: unknown, direction: unknown, isAds: unknown)
	local slot, weapon = activeState(player)
	if not slot or slot.Reloading then
		return
	end
	if not PlayerStateService:IsAlive(player) or not PlayerStateService:IsCombatEnabled() then
		return
	end

	-- Payload sanity: reject anything malformed instead of erroring.
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	local directionVector = direction :: Vector3
	local originVector = origin :: Vector3
	if directionVector.Magnitude < 1e-3 or directionVector.X ~= directionVector.X then
		return
	end

	local character, head, humanoid = characterParts(player)
	if not character or not head or not humanoid then
		return
	end
	if (originVector - head.Position).Magnitude > MAX_ORIGIN_OFFSET_STUDS then
		return
	end

	if weapon.Type == "Melee" then
		doMelee(player, character, head, originVector, directionVector.Unit, weapon, slot)
		return
	end

	local now = os.clock()
	local interval = WeaponMath.fireIntervalSeconds(weapon.RoundsPerMinute)
	if now - slot.LastFireClock < interval * FIRE_INTERVAL_TOLERANCE or slot.Magazine <= 0 then
		return
	end

	slot.LastFireClock = now
	slot.Magazine -= 1
	weaponFiredBroadcast:FireAllClients({ UserId = player.UserId, Position = head.Position, WeaponId = slot.WeaponId })

	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local baseDirection = directionVector.Unit

	if weapon.Type == "Projectile" then
		spawnRocket(player, character, originVector, baseDirection, weapon)
	elseif weapon.Type == "Shotgun" then
		local spread = WeaponMath.spreadDegrees(weapon.SpreadDegrees, isAds == true, isMoving, isAirborne)
		local feedback = newFeedback()
		for _ = 1, weapon.Pellets do
			fireRay(
				player,
				character,
				originVector,
				applySpread(baseDirection, spread),
				weapon,
				weapon.PelletDamage,
				feedback
			)
		end
		combatFeedback:FireClient(player, feedback)
	else
		local spread = WeaponMath.spreadDegrees(weapon.SpreadDegrees, isAds == true, isMoving, isAirborne)
		local feedback = newFeedback()
		fireRay(
			player,
			character,
			originVector,
			applySpread(baseDirection, spread),
			weapon,
			weapon.BodyDamage,
			feedback
		)
		combatFeedback:FireClient(player, feedback)
	end

	replicate(player)
end

local function onReloadRequest(player: Player)
	local slot, weapon = activeState(player)
	if not slot or slot.Reloading or not PlayerStateService:IsAlive(player) then
		return
	end
	if weapon.Type == "Melee" then
		return -- no reload for the knife
	end
	if slot.Magazine >= weapon.MagazineSize or slot.Reserve <= 0 then
		return
	end

	slot.Reloading = true
	replicate(player)

	local loadout = loadouts[player]
	local generation = loadout.Generation
	local reloadingSlot = slot
	task.delay(weapon.ReloadSeconds, function()
		local current = loadouts[player]
		if not current or current.Generation ~= generation or not reloadingSlot.Reloading then
			return
		end
		local needed = weapon.MagazineSize - reloadingSlot.Magazine
		local transferred = math.min(needed, reloadingSlot.Reserve)
		reloadingSlot.Magazine += transferred
		reloadingSlot.Reserve -= transferred
		reloadingSlot.Reloading = false
		if current.ActiveSlot == loadout.ActiveSlot then
			replicate(player)
		end
	end)
end

local function onEquipRequest(player: Player, slotName: unknown)
	local loadout = loadouts[player]
	if not loadout or typeof(slotName) ~= "string" then
		return
	end
	if not loadout.Slots[slotName] or slotName == loadout.ActiveSlot then
		return
	end
	-- Switching cancels a reload in progress on the slot we leave.
	local leaving = loadout.Slots[loadout.ActiveSlot]
	if leaving then
		leaving.Reloading = false
	end
	loadout.ActiveSlot = slotName
	replicate(player)
end

function WeaponService.Init(_self: any)
	weaponStateChanged = RemoteUtil.getEvent(RemoteNames.WeaponStateChanged)
	combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)
	weaponFiredBroadcast = RemoteUtil.getEvent(RemoteNames.WeaponFiredBroadcast)

	projectileFolder = Instance.new("Folder")
	projectileFolder.Name = "Projectiles"
	projectileFolder.Parent = workspace

	RemoteUtil.getEvent(RemoteNames.FireWeaponRequest).OnServerEvent:Connect(onFireRequest)
	RemoteUtil.getEvent(RemoteNames.ReloadRequest).OnServerEvent:Connect(onReloadRequest)
	RemoteUtil.getEvent(RemoteNames.EquipSlotRequest).OnServerEvent:Connect(onEquipRequest)
end

function WeaponService.Start(_self: any)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			resetLoadout(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		loadouts[player] = nil
	end)

	RunService.Heartbeat:Connect(function(deltaSeconds)
		if #projectiles > 0 then
			updateProjectiles(deltaSeconds)
		end
	end)
end

return WeaponService
