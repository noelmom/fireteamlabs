--!strict
-- Pure quality-tier resolution (no Roblox APIs) so it runs under lune in CI.
-- QualityController applies the resolved settings to the client.

local QualityLogic = {}

export type Tier = "Low" | "Medium" | "High"

-- Whether a string names a real tier.
function QualityLogic.isValidTier(order: { string }, tier: string): boolean
	for _, name in order do
		if name == tier then
			return true
		end
	end
	return false
end

-- Resolves a user selection ("Auto" | a tier name | anything) to a concrete
-- tier. "Auto" -> autoTier; a valid tier -> itself; anything else -> fallback.
function QualityLogic.resolveTier(order: { string }, selection: string, autoTier: string, fallback: string): string
	if selection == "Auto" then
		return if QualityLogic.isValidTier(order, autoTier) then autoTier else fallback
	end
	if QualityLogic.isValidTier(order, selection) then
		return selection
	end
	return fallback
end

-- Steps a tier up or down within the ordered list, clamped at the ends. Used by
-- a settings toggle and by an adaptive downgrade if performance drops.
function QualityLogic.stepTier(order: { string }, tier: string, delta: number): string
	local index = 1
	for i, name in order do
		if name == tier then
			index = i
			break
		end
	end
	local target = math.clamp(index + delta, 1, #order)
	return order[target]
end

return QualityLogic
