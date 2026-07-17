--!strict
-- Tests for issue #5: shield-before-health and shield multipliers
-- (MASTERPLAN.md sections 9, 12, 22).

local DamageMath = require("../../src/ReplicatedStorage/Shared/Utility/DamageMath")

local function assertNear(actual: number, expected: number, label: string)
	if math.abs(actual - expected) > 1e-6 then
		error(`{label}: expected {expected}, got {actual}`)
	end
end

return {
	["damage drains shield before health"] = function()
		local shield, health, breakdown = DamageMath.apply(100, 100, 30, 1.0)
		assertNear(shield, 70, "shield")
		assertNear(health, 100, "health")
		assert(not breakdown.ShieldBroken, "shield should not break")
	end,

	["multiplier applies to shield damage only"] = function()
		-- Heavy (1.5x): 40 damage removes 60 shield, touches no health.
		local shield, health = DamageMath.apply(100, 100, 40, 1.5)
		assertNear(shield, 40, "shield")
		assertNear(health, 100, "health")
	end,

	["overflow past a breaking shield hits health unmultiplied"] = function()
		-- Heavy (1.5x) 80 damage vs 100 shield: 100/1.5 raw breaks the
		-- shield, remaining 80 - 66.66 hits health raw.
		local shield, health, breakdown = DamageMath.apply(100, 100, 80, 1.5)
		assertNear(shield, 0, "shield")
		assertNear(health, 100 - (80 - 100 / 1.5), "health")
		assert(breakdown.ShieldBroken, "shield should break")
	end,

	["exact shield break carries no overflow"] = function()
		local shield, health, breakdown = DamageMath.apply(100, 100, 80, 1.25)
		assertNear(shield, 0, "shield")
		assertNear(health, 100, "health")
		assert(breakdown.ShieldBroken, "shield should break")
	end,

	["no shield means raw damage to health"] = function()
		local shield, health = DamageMath.apply(0, 100, 55, 1.5)
		assertNear(shield, 0, "shield")
		assertNear(health, 45, "health")
	end,

	["health clamps at zero and reports elimination damage"] = function()
		local _, health, breakdown = DamageMath.apply(0, 30, 90, 1.0)
		assertNear(health, 0, "health")
		assertNear(breakdown.HealthDamage, 30, "health damage")
	end,

	["zero damage is a no-op"] = function()
		local shield, health, breakdown = DamageMath.apply(80, 90, 0, 1.5)
		assertNear(shield, 80, "shield")
		assertNear(health, 90, "health")
		assert(not breakdown.ShieldBroken, "no break")
	end,

	["regen waits for delay then ramps at rate"] = function()
		assertNear(DamageMath.regenStep(50, 100, 40, 0.1, 3, 6), 50, "before delay")
		assertNear(DamageMath.regenStep(50, 100, 40, 0.1, 7, 6), 54, "after delay")
		assertNear(DamageMath.regenStep(99, 100, 40, 0.1, 7, 6), 100, "clamps at max")
	end,
}
