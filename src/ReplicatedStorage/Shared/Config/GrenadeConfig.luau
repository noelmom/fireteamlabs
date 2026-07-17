--!strict
-- Grenade rules (MASTERPLAN.md section 14).

local GrenadeConfig = {
	PerRound = 1, -- hard maximum; no in-round regeneration, no carry between rounds

	Frag = {
		FuseSeconds = 1.6,
		ExplosionRadiusStuds = 14,
		MaxDamage = 110,
		MinDamage = 20, -- at radius edge after falloff
		ThrowSpeed = 80,
	},
}

return GrenadeConfig
