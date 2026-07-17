--!strict
-- Pure damage math (no Roblox APIs) so it can run under lune in CI.
-- Rules (MASTERPLAN.md sections 9 and 12): damage drains shield before
-- health, and the category shield multiplier applies only to the portion
-- absorbed by the shield. Overflow past a breaking shield hits health at
-- the raw, unmultiplied amount.

local DamageMath = {}

export type DamageBreakdown = {
	ShieldDamage: number, -- shield points removed
	HealthDamage: number, -- health points removed
	ShieldBroken: boolean,
}

function DamageMath.apply(
	shield: number,
	health: number,
	amount: number,
	shieldMultiplier: number
): (number, number, DamageBreakdown)
	assert(amount >= 0, "damage amount must be non-negative")
	assert(shieldMultiplier > 0, "shield multiplier must be positive")

	local newShield = shield
	local newHealth = health
	local breakdown: DamageBreakdown = {
		ShieldDamage = 0,
		HealthDamage = 0,
		ShieldBroken = false,
	}

	if amount == 0 then
		return newShield, newHealth, breakdown
	end

	if shield > 0 then
		local shieldDamage = amount * shieldMultiplier
		if shieldDamage < shield then
			newShield = shield - shieldDamage
			breakdown.ShieldDamage = shieldDamage
		else
			-- Shield breaks: only the raw amount needed to break it is
			-- consumed; the remainder carries to health unmultiplied.
			local rawAbsorbed = shield / shieldMultiplier
			local overflow = amount - rawAbsorbed
			newShield = 0
			newHealth = math.max(0, health - overflow)
			breakdown.ShieldDamage = shield
			breakdown.HealthDamage = health - newHealth
			breakdown.ShieldBroken = true
		end
	else
		newHealth = math.max(0, health - amount)
		breakdown.HealthDamage = health - newHealth
	end

	return newShield, newHealth, breakdown
end

-- Shield regeneration for one step; returns the new shield value.
function DamageMath.regenStep(
	shield: number,
	maxShield: number,
	ratePerSecond: number,
	deltaSeconds: number,
	secondsSinceDamage: number,
	delaySeconds: number
): number
	if secondsSinceDamage < delaySeconds or shield >= maxShield then
		return shield
	end
	return math.min(maxShield, shield + ratePerSecond * deltaSeconds)
end

return DamageMath
