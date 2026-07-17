--!strict
-- Server-authoritative firing pipeline (issue #7, MASTERPLAN.md sections 11
-- and 20). Clients request shots with their camera origin/direction; the
-- server enforces fire rate, ammo, origin sanity, applies spread, raycasts,
-- and deals damage through PlayerStateService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local WeaponMath = require(ReplicatedStorage.Shared.Utility.WeaponMath)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local PlayerStateService = require(ServerScriptService.Services.PlayerStateService)

-- Tolerances for legitimate network jitter; anything beyond is rejected.
local FIRE_INTERVAL_TOLERANCE = 0.92
local MAX_ORIGIN_OFFSET_STUDS = 8

type WeaponState = {
	WeaponId: string,
	Magazine: number,
	Reserve: number,
	LastFireClock: number,
	Reloading: boolean,
	Generation: number, -- invalidates pending reloads across respawns
}

local WeaponService = {
	Name = "WeaponService",
}

local states: { [Player]: WeaponState } = {}

local weaponStateChanged: RemoteEvent
local combatFeedback: RemoteEvent

local function replicate(player: Player)
	local state = states[player]
	if not state then
		return
	end
	weaponStateChanged:FireClient(player, {
		WeaponId = state.WeaponId,
		Magazine = state.Magazine,
		Reserve = state.Reserve,
		Reloading = state.Reloading,
	})
end

local function resetLoadout(player: Player)
	local previous = states[player]
	local weapon = WeaponConfig.AutoRifle
	states[player] = {
		WeaponId = "AutoRifle",
		Magazine = weapon.MagazineSize,
		Reserve = weapon.ReserveAmmo,
		LastFireClock = 0,
		Reloading = false,
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

local function applySpread(direction: Vector3, degrees: number, random: Random): Vector3
	local radians = math.rad(degrees)
	local cframe = CFrame.lookAlong(Vector3.zero, direction)
		* CFrame.Angles(random:NextNumber(-radians, radians), random:NextNumber(-radians, radians), 0)
	return cframe.LookVector
end

local random = Random.new()

local function onFireRequest(player: Player, origin: unknown, direction: unknown, isAds: unknown)
	local state = states[player]
	if not state or state.Reloading then
		return
	end
	if not PlayerStateService:IsAlive(player) then
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

	local weapon = WeaponConfig[state.WeaponId]
	local now = os.clock()
	local interval = WeaponMath.fireIntervalSeconds(weapon.RoundsPerMinute)
	if now - state.LastFireClock < interval * FIRE_INTERVAL_TOLERANCE then
		return
	end
	if state.Magazine <= 0 then
		return
	end

	state.LastFireClock = now
	state.Magazine -= 1

	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local spread = WeaponMath.spreadDegrees(weapon.SpreadDegrees, isAds == true, isMoving, isAirborne)
	local shotDirection = applySpread(directionVector.Unit, spread, random)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(originVector, shotDirection * weapon.MaxRangeStuds, params)

	local feedback = {
		Hit = false,
		Precision = false,
		ShieldBroken = false,
		Eliminated = false,
		Position = if result then result.Position else originVector + shotDirection * weapon.MaxRangeStuds,
	}

	if result then
		local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
		local victim = hitCharacter and Players:GetPlayerFromCharacter(hitCharacter)
		if victim and victim ~= player then
			local distance = (result.Position - originVector).Magnitude
			local falloff = WeaponMath.falloffScale(
				weapon.FalloffStartStuds,
				weapon.FalloffEndStuds,
				weapon.FalloffMinDamageScale,
				distance
			)
			local isPrecision = result.Instance.Name == "Head"
			local damage = WeaponMath.damage(weapon.BodyDamage, weapon.PrecisionMultiplier, isPrecision, falloff)

			local damageResult = PlayerStateService:ApplyDamage(victim, damage, weapon.Slot, player)
			if damageResult then
				feedback.Hit = true
				feedback.Precision = isPrecision
				feedback.ShieldBroken = damageResult.ShieldBroken
				feedback.Eliminated = damageResult.Eliminated
			end
		end
	end

	combatFeedback:FireClient(player, feedback)
	replicate(player)
end

local function onReloadRequest(player: Player)
	local state = states[player]
	if not state or state.Reloading then
		return
	end
	if not PlayerStateService:IsAlive(player) then
		return
	end

	local weapon = WeaponConfig[state.WeaponId]
	if state.Magazine >= weapon.MagazineSize or state.Reserve <= 0 then
		return
	end

	state.Reloading = true
	replicate(player)

	local generation = state.Generation
	task.delay(weapon.ReloadSeconds, function()
		local current = states[player]
		if not current or current.Generation ~= generation or not current.Reloading then
			return
		end
		local needed = weapon.MagazineSize - current.Magazine
		local transferred = math.min(needed, current.Reserve)
		current.Magazine += transferred
		current.Reserve -= transferred
		current.Reloading = false
		replicate(player)
	end)
end

function WeaponService.Init(_self: any)
	weaponStateChanged = RemoteUtil.getEvent(RemoteNames.WeaponStateChanged)
	combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)
	local fireRequest = RemoteUtil.getEvent(RemoteNames.FireWeaponRequest)
	local reloadRequest = RemoteUtil.getEvent(RemoteNames.ReloadRequest)

	fireRequest.OnServerEvent:Connect(onFireRequest)
	reloadRequest.OnServerEvent:Connect(onReloadRequest)
end

function WeaponService.Start(_self: any)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			resetLoadout(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return WeaponService
