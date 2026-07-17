--!strict
-- Placeholder audio (issue #23) using engine-shipped rbxasset sounds only,
-- so nothing depends on marketplace assets. When real sound design lands,
-- swap SoundIds here and record external assets in ASSET_MANIFEST.md.

export type SoundDef = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
	SpeedJitter: number?, -- random +/- applied per play
	RollOffMaxDistance: number?, -- only for 3D positional sounds
}

local AudioConfig: { [string]: { [string]: SoundDef } } = {
	-- Per-weapon fire sounds (issue #8). Looked up by WeaponId, falling back to
	-- Weapon.Fire / Weapon.RemoteFire.
	WeaponFire = {
		AutoRifle = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.6,
			PlaybackSpeed = 0.72,
			SpeedJitter = 0.06,
		},
		Shotgun = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.8,
			PlaybackSpeed = 0.42,
			SpeedJitter = 0.04,
		},
		RocketLauncher = { SoundId = "rbxasset://sounds/bass.wav", Volume = 0.75, PlaybackSpeed = 0.9 },
	},
	WeaponRemoteFire = {
		AutoRifle = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.5,
			PlaybackSpeed = 0.7,
			SpeedJitter = 0.05,
			RollOffMaxDistance = 250,
		},
		Shotgun = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.7,
			PlaybackSpeed = 0.42,
			RollOffMaxDistance = 260,
		},
		RocketLauncher = {
			SoundId = "rbxasset://sounds/bass.wav",
			Volume = 0.7,
			PlaybackSpeed = 0.85,
			RollOffMaxDistance = 320,
		},
	},

	Weapon = {
		Fire = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.6,
			PlaybackSpeed = 0.72,
			SpeedJitter = 0.06,
		},
		RemoteFire = {
			SoundId = "rbxasset://sounds/paintball.wav",
			Volume = 0.5,
			PlaybackSpeed = 0.7,
			SpeedJitter = 0.05,
			RollOffMaxDistance = 250,
		},
		EmptyClick = {
			SoundId = "rbxasset://sounds/button.wav",
			Volume = 0.4,
			PlaybackSpeed = 1.5,
		},
		Reload = {
			SoundId = "rbxasset://sounds/unsheath.wav",
			Volume = 0.5,
			PlaybackSpeed = 0.85,
		},
	},

	Feedback = {
		Hit = {
			SoundId = "rbxasset://sounds/electronicpingshort.wav",
			Volume = 0.35,
			PlaybackSpeed = 1.0,
		},
		PrecisionHit = {
			SoundId = "rbxasset://sounds/electronicpingshort.wav",
			Volume = 0.4,
			PlaybackSpeed = 1.35,
		},
		Elimination = {
			SoundId = "rbxasset://sounds/bass.wav",
			Volume = 0.6,
			PlaybackSpeed = 1.25,
		},
		OwnShieldBreak = {
			SoundId = "rbxasset://sounds/glassbreak.wav",
			Volume = 0.5,
			PlaybackSpeed = 1.0,
		},
	},
}

return AudioConfig
