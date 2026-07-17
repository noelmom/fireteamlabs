--!strict
-- Pure match/round decision logic (no Roblox APIs) so it runs under lune in
-- CI. Orchestration, timers, and replication live in MatchService; the rules
-- for who wins a round, who wins the match, and which physical side a team
-- spawns on live here (MASTERPLAN.md section 8).

local MatchLogic = {}

export type TeamId = "Alpha" | "Bravo"
export type RoundResult = "Alpha" | "Bravo" | "Draw"
export type Scores = { Alpha: number, Bravo: number }

local function otherTeam(team: TeamId): TeamId
	return if team == "Alpha" then "Bravo" else "Alpha"
end

MatchLogic.otherTeam = otherTeam

-- Resolves a round from the count of living players on each team.
-- Returns nil while both teams still have someone alive (round continues);
-- "Draw" only when both are wiped on the same tick.
function MatchLogic.resolveElimination(aliveAlpha: number, aliveBravo: number): RoundResult?
	local alphaOut = aliveAlpha <= 0
	local bravoOut = aliveBravo <= 0
	if alphaOut and bravoOut then
		return "Draw"
	elseif bravoOut then
		return "Alpha"
	elseif alphaOut then
		return "Bravo"
	end
	return nil
end

-- Returns a new score table with the round result applied (Draw scores none).
function MatchLogic.awardRound(scores: Scores, result: RoundResult): Scores
	local next: Scores = { Alpha = scores.Alpha, Bravo = scores.Bravo }
	if result == "Alpha" or result == "Bravo" then
		next[result] += 1
	end
	return next
end

-- First team to reach the target wins. Rounds are scored one at a time, so
-- both teams can never cross the target on the same round.
function MatchLogic.matchWinner(scores: Scores, target: number): TeamId?
	if scores.Alpha >= target then
		return "Alpha"
	elseif scores.Bravo >= target then
		return "Bravo"
	end
	return nil
end

-- True once either team is one round from winning.
function MatchLogic.isMatchPoint(scores: Scores, target: number): boolean
	return scores.Alpha == target - 1 or scores.Bravo == target - 1
end

-- Whether damage/combat is live for the given match + round phase. Combat is
-- on during free-roam (no match) and during the live round (Active/Overtime),
-- and off during the pre-round countdown, post-round, and post-match. Server
-- and client share this one rule so the gate can never drift (issue #28).
function MatchLogic.isCombatLive(phase: string, roundPhase: string): boolean
	if phase == "WaitingForPlayers" then
		return true
	elseif phase ~= "InProgress" then
		return false
	end
	return roundPhase == "Active" or roundPhase == "Overtime"
end

-- Advances overtime zone capture by one step (issue #4). With exactly one team
-- alone in the zone, its progress accumulates; a different sole team resets
-- progress and takes over; contested (both present) or empty (neither) pauses
-- progress. Returns the owning team, the new progress, and the winning team
-- once progress reaches captureSeconds.
function MatchLogic.stepCapture(
	owner: TeamId?,
	progress: number,
	alphaInZone: number,
	bravoInZone: number,
	deltaSeconds: number,
	captureSeconds: number
): (TeamId?, number, TeamId?)
	local sole: TeamId? = nil
	if alphaInZone > 0 and bravoInZone == 0 then
		sole = "Alpha"
	elseif bravoInZone > 0 and alphaInZone == 0 then
		sole = "Bravo"
	end

	if sole == nil then
		-- Contested or empty: hold progress and owner.
		return owner, progress, nil
	end

	local newOwner = owner
	local newProgress = progress
	if owner ~= sole then
		newOwner = sole
		newProgress = 0
	end
	newProgress += deltaSeconds

	local winner: TeamId? = if newProgress >= captureSeconds then sole else nil
	return newOwner, newProgress, winner
end

-- Which physical spawn side a team uses for a given round. With rotation on,
-- sides swap every round (round 1 = home, round 2 = swapped, ...).
function MatchLogic.sideForTeam(team: TeamId, roundNumber: number, rotationEnabled: boolean): TeamId
	if not rotationEnabled then
		return team
	end
	local swapped = (roundNumber % 2) == 0
	return if swapped then otherTeam(team) else team
end

return MatchLogic
