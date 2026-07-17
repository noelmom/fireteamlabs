--!strict
-- Class definitions (MASTERPLAN.md section 15).
-- Classes differ only in their charged melee ability (F). They must never
-- change health, shield, movement, hitboxes, weapon access, or grenade count.

local ClassConfig = {
	AbilityCooldownSeconds = 25,

	Classes = {
		Specter = {
			DisplayName = "Specter",
			Role = "Agile skirmisher",
			Ability = {
				Name = "Flechette",
				-- Charged mono-edge throwing blade: physical projectile with travel time.
				BodyDamage = 80,
				PrecisionDamage = 120,
				ProjectileSpeed = 90,
				ProjectileDropStudsPerSecond = 20,
			},
		},

		Conduit = {
			DisplayName = "Conduit",
			Role = "Energy specialist",
			Ability = {
				Name = "Surge Bolt",
				-- Charged superheated plasma bolt: short-to-medium range projectile.
				DirectDamage = 70,
				BurnTicks = 4,
				BurnDamagePerTick = 5,
				BurnTickIntervalSeconds = 0.5,
				ProjectileSpeed = 70,
			},
		},

		Bulwark = {
			DisplayName = "Bulwark",
			Role = "Heavy breacher",
			Ability = {
				Name = "Kinetic Ram",
				-- Charged forward slam: server-validated lunge that cannot pass through walls.
				Damage = 100,
				LungeStuds = 12,
				MissRecoverySeconds = 1.0,
			},
		},
	},
}

return ClassConfig
