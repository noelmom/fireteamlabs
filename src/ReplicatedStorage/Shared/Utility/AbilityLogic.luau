--!strict
-- Pure class-ability cooldown logic (no Roblox APIs) so it runs under lune in
-- CI (issue #10). Times use a shared clock (server time on the server; the
-- synced clock on the client).

local AbilityLogic = {}

-- True once the cooldown has elapsed.
function AbilityLogic.isReady(now: number, cooldownEndTime: number): boolean
	return now >= cooldownEndTime
end

-- Seconds left on the cooldown, clamped to >= 0.
function AbilityLogic.cooldownRemaining(now: number, cooldownEndTime: number): number
	return math.max(0, cooldownEndTime - now)
end

return AbilityLogic
