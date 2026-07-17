--!strict
-- Centralized combat rules (MASTERPLAN.md section 12).
-- Damage may never depend on cosmetics, reticles, ELO, account age, or spending.

local CombatConfig = {
	-- Multiplier applied to damage dealt to shields, per source category.
	ShieldMultipliers = {
		Primary = 1.0,
		Special = 1.25,
		Heavy = 1.5,
		Knife = 1.0,
		Grenade = 1.0,
		ClassAbility = 1.0,
	},

	-- Knife weapon stats live in WeaponConfig.Knife (#9); its shield category is
	-- ShieldMultipliers.Knife above.
}

return CombatConfig
