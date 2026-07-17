--!strict
-- Pure weapon math (no Roblox APIs) so it runs under lune in CI.
-- Damage depends on distance falloff and hit location (MASTERPLAN.md
-- section 11); fire rate is enforced from rounds per minute.

local WeaponMath = {}

-- 1.0 up to falloff start, linear down to minScale at falloff end.
function WeaponMath.falloffScale(startStuds: number, endStuds: number, minScale: number, distance: number): number
	if distance <= startStuds then
		return 1
	end
	if distance >= endStuds then
		return minScale
	end
	local alpha = (distance - startStuds) / (endStuds - startStuds)
	return 1 + (minScale - 1) * alpha
end

function WeaponMath.damage(
	baseDamage: number,
	precisionMultiplier: number,
	isPrecision: boolean,
	falloff: number
): number
	local damage = baseDamage * falloff
	if isPrecision then
		damage *= precisionMultiplier
	end
	return damage
end

function WeaponMath.fireIntervalSeconds(roundsPerMinute: number): number
	assert(roundsPerMinute > 0, "roundsPerMinute must be positive")
	return 60 / roundsPerMinute
end

function WeaponMath.spreadDegrees(
	spread: { HipBase: number, AdsBase: number, MovingAdd: number, AirborneAdd: number },
	isAds: boolean,
	isMoving: boolean,
	isAirborne: boolean
): number
	local degrees = if isAds then spread.AdsBase else spread.HipBase
	if isMoving then
		degrees += spread.MovingAdd
	end
	if isAirborne then
		degrees += spread.AirborneAdd
	end
	return degrees
end

return WeaponMath
