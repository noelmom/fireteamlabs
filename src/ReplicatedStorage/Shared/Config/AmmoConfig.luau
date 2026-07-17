--!strict
-- Special and heavy ammo economy (MASTERPLAN.md section 13).

local AmmoConfig = {
	Special = {
		MapLocations = 2, -- competitively equivalent positions
		FirstSpawnSeconds = 20,
		RespawnSeconds = 30,
		GrantedAmmo = 8,
		MaxCarry = 16,
	},

	Heavy = {
		MapLocations = 1, -- central high-risk position
		FirstSpawnSeconds = 45,
		SpawnsPerRound = 1,
		GrantedAmmo = 2,
		MaxCarry = 4,
	},

	-- Survivors retain special/heavy ammo between rounds; eliminated players reset.
	EliminatedResetSpecial = 0,
	EliminatedResetHeavy = 0,
}

return AmmoConfig
