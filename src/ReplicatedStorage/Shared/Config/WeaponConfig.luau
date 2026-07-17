--!strict
-- Weapon definitions (MASTERPLAN.md section 11).
-- Vertical slice ships one weapon per slot; remaining archetypes are defined
-- when their feature issues open. Stats here are initial tuning targets.

export type WeaponSlot = "Primary" | "Special" | "Heavy" | "Knife"

local WeaponConfig = {
	-- Vertical slice loadout
	AutoRifle = {
		Slot = "Primary" :: WeaponSlot,
		Type = "Hitscan",
		DisplayName = "Auto Rifle",
		BodyDamage = 18,
		PrecisionMultiplier = 1.5,
		RoundsPerMinute = 600,
		MagazineSize = 30,
		ReserveAmmo = 120,
		ReloadSeconds = 2.2,
		FalloffStartStuds = 40,
		FalloffEndStuds = 90,
		FalloffMinDamageScale = 0.6,
		MaxRangeStuds = 300,
		AdsFov = 65,
		SpreadDegrees = {
			HipBase = 1.4,
			AdsBase = 0.35,
			MovingAdd = 0.9,
			AirborneAdd = 2.2,
		},
	},

	Shotgun = {
		Slot = "Special" :: WeaponSlot,
		Type = "Shotgun",
		DisplayName = "Shotgun",
		Pellets = 8,
		PelletDamage = 14,
		PrecisionMultiplier = 1.15,
		RoundsPerMinute = 70,
		MagazineSize = 5,
		ReserveAmmo = 20,
		ReloadSeconds = 2.6,
		FalloffStartStuds = 10,
		FalloffEndStuds = 28,
		FalloffMinDamageScale = 0.25,
		MaxRangeStuds = 120,
		AdsFov = 70,
		SpreadDegrees = {
			-- Cone half-angle applied per pellet.
			HipBase = 4.5,
			AdsBase = 2.6,
			MovingAdd = 1.0,
			AirborneAdd = 2.0,
		},
	},

	RocketLauncher = {
		Slot = "Heavy" :: WeaponSlot,
		Type = "Projectile",
		DisplayName = "Rocket Launcher",
		DirectDamage = 220,
		SplashRadiusStuds = 14,
		SplashMaxDamage = 110,
		SplashMinDamage = 30,
		RoundsPerMinute = 40,
		MagazineSize = 1,
		ReserveAmmo = 4,
		ReloadSeconds = 3.0,
		AdsFov = 72,
		ProjectileSpeed = 110,
		ProjectileLifetimeSeconds = 4,
		MaxRangeStuds = 500,
	},

	Knife = {
		Slot = "Knife" :: WeaponSlot,
		Type = "Melee",
		DisplayName = "Knife",
		-- Unlimited use; no magazine. Server validates range and swing timing (#9).
		Damage = 70,
		RangeStuds = 6,
		SwingDelaySeconds = 0.5, -- base cadence between swings
		MissRecoverySeconds = 0.7, -- extra delay added after a whiff
	},

	-- Deferred archetypes (do not implement before their issues open):
	-- BurstRifle, HandCannon (Primary); SniperRifle, ChargedEnergyRifle (Special);
	-- HeavyMachineGun (Heavy).
}

return WeaponConfig
