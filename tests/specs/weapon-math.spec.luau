--!strict
-- Tests for issue #7: damage falloff, precision hits, fire-rate validation
-- (MASTERPLAN.md sections 11, 22).

local WeaponMath = require("../../src/ReplicatedStorage/Shared/Utility/WeaponMath")

local function assertNear(actual: number, expected: number, label: string)
	if math.abs(actual - expected) > 1e-6 then
		error(`{label}: expected {expected}, got {actual}`)
	end
end

return {
	["no falloff inside falloff start"] = function()
		assertNear(WeaponMath.falloffScale(40, 90, 0.6, 10), 1, "close range")
		assertNear(WeaponMath.falloffScale(40, 90, 0.6, 40), 1, "at start")
	end,

	["falloff is linear between start and end"] = function()
		assertNear(WeaponMath.falloffScale(40, 90, 0.6, 65), 0.8, "midpoint")
	end,

	["falloff clamps at minimum past end"] = function()
		assertNear(WeaponMath.falloffScale(40, 90, 0.6, 90), 0.6, "at end")
		assertNear(WeaponMath.falloffScale(40, 90, 0.6, 300), 0.6, "far past end")
	end,

	["precision multiplies damage after falloff"] = function()
		assertNear(WeaponMath.damage(18, 1.5, true, 1), 27, "precision close")
		assertNear(WeaponMath.damage(18, 1.5, false, 1), 18, "body close")
		assertNear(WeaponMath.damage(18, 1.5, true, 0.6), 16.2, "precision far")
	end,

	["fire interval derives from rounds per minute"] = function()
		assertNear(WeaponMath.fireIntervalSeconds(600), 0.1, "600 rpm")
		assertNear(WeaponMath.fireIntervalSeconds(40), 1.5, "40 rpm")
	end,

	["spread stacks movement and airborne penalties"] = function()
		local spread = { HipBase = 1.4, AdsBase = 0.35, MovingAdd = 0.9, AirborneAdd = 2.2 }
		assertNear(WeaponMath.spreadDegrees(spread, false, false, false), 1.4, "hip standing")
		assertNear(WeaponMath.spreadDegrees(spread, true, false, false), 0.35, "ads standing")
		assertNear(WeaponMath.spreadDegrees(spread, false, true, true), 4.5, "hip moving airborne")
	end,
}
