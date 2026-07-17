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

		-- Seconds to wait for all rostered players to have a live character
		-- before a round's elimination checks begin.
		RoundReadyTimeoutSeconds = 5,
		-- Once enough players are present, wait this long for more to settle so a
		-- burst of joiners forms the largest match they can fill (e.g. 3v3), then
		-- start (issue #3).
		MatchStartGraceSeconds = 3,

		Overtime = {
			-- Activates when the round timer expires with both teams alive (#4).
			-- Seconds of uncontested presence in the central zone to capture it.
			CaptureSeconds = 8,
			ZoneRadiusStuds = 12,
			-- Hard cap on overtime length so a mutual standoff can't run forever.
			MaxDurationSeconds = 45,
			-- If the cap is hit with no capture, the round is a draw.
			DrawOnTimeout = true,
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

		Validation = {
			-- Server-side speed enforcement (issue #6).
			CheckIntervalSeconds = 0.5,
			ToleranceMultiplier = 1.35, -- headroom for physics jitter and jumps
			ViolationLimit = 3, -- consecutive violations before correction
		},
	},

	Playlists = {
		-- Vertical slice scope: casual 1v1 and 3v3 only.
		TeamSizes = { 1, 3 },
	},
}

return GameConfig
