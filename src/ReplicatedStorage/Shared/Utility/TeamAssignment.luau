--!strict
-- Pure team-formation logic (no Roblox APIs) so it runs under lune in CI
-- (issue #3). TeamService applies these decisions to live players.

local TeamAssignment = {}

export type TeamId = "Alpha" | "Bravo"

-- A joining player goes to the smaller team; ties go to Alpha. Keeps the two
-- teams within one player of each other as people come and go.
function TeamAssignment.pickTeam(alphaCount: number, bravoCount: number): TeamId
	if bravoCount < alphaCount then
		return "Bravo"
	end
	return "Alpha"
end

-- The largest supported team size whose full match (size per team) fits the
-- current player count, or nil if not even the smallest size can be filled.
-- e.g. supported {1, 3}: 2 players -> 1 (1v1), 6 -> 3 (3v3), 5 -> 1, 1 -> nil.
function TeamAssignment.selectTeamSize(playerCount: number, supportedSizes: { number }): number?
	local best: number? = nil
	for _, size in supportedSizes do
		if playerCount >= size * 2 and (best == nil or size > best) then
			best = size
		end
	end
	return best
end

return TeamAssignment
