--!strict
-- Match, durability, and movement configuration (MASTERPLAN.md sections 8-10).
-- All values are initial tuning targets; balance changes go through balance/* issues.

local GameConfig = {
	Match = {
		TeamCount = 2,
		PreRoundCountdownSeconds = 8,
		RoundTimerSeconds = 90,
		RoundWinTarget = 7,
		PostRoundSeconds = 5,
		RespawnsDuringRound = false,
		TeamSideRotation = true,

		Overtime = {
			-- Activates when the round timer expires with both teams alive.
			CaptureSeconds = 8,
			ZoneRadiusStuds = 12,
		},
	},

	Durability = {
		MaxShield = 100,
		MaxHealth = 100,

		ShieldRegenDelaySeconds = 6,
		ShieldRegenPerSecond = 40,
		HealthRegenEnabled = false,
		HealthRegenDelaySeconds = 10,
		HealthRegenPerSecond = 10,
	},

	Movement = {
		WalkSpeed = 16,
		SprintSpeed = 22,
		CrouchSpeed = 10,
		NormalFov = 80,
		SprintFov = 88,

		-- Experimental; must stay disabled for the vertical slice.
		SlideEnabled = false,
	},

	Playlists = {
		-- Vertical slice scope: casual 1v1 and 3v3 only.
		TeamSizes = { 1, 3 },
	},
}

return GameConfig
