--!strict
-- Weapon definitions (MASTERPLAN.md section 11).
-- Vertical slice ships one weapon per slot; remaining archetypes are defined
-- when their feature issues open. Stats here are initial tuning targets.

export type WeaponSlot = "Primary" | "Special" | "Heavy" | "Knife"

local WeaponConfig = {
	-- Vertical slice loadout
	AutoRifle = {
		Slot = "Primary" :: WeaponSlot,
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
	},

	Shotgun = {
		Slot = "Special" :: WeaponSlot,
		DisplayName = "Shotgun",
		Pellets = 8,
		PelletDamage = 14,
		PrecisionMultiplier = 1.0,
		RoundsPerMinute = 70,
		MagazineSize = 5,
		ReloadSecondsPerShell = 0.55,
		FalloffStartStuds = 10,
		FalloffEndStuds = 25,
		FalloffMinDamageScale = 0.3,
	},

	RocketLauncher = {
		Slot = "Heavy" :: WeaponSlot,
		DisplayName = "Rocket Launcher",
		DirectDamage = 220,
		SplashRadiusStuds = 12,
		SplashMaxDamage = 150,
		SplashMinDamage = 40,
		RoundsPerMinute = 40,
		MagazineSize = 1,
		ReloadSeconds = 3.0,
		ProjectileSpeed = 110,
	},

	-- Deferred archetypes (do not implement before their issues open):
	-- BurstRifle, HandCannon (Primary); SniperRifle, ChargedEnergyRifle (Special);
	-- HeavyMachineGun (Heavy).
}

return WeaponConfig
