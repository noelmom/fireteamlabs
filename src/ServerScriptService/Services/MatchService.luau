--!strict
-- Owns the match lifecycle: team assignment, round phases, scoring, overtime,
-- and match completion (MASTERPLAN.md section 8, Vertical Slice Amendment).
--
-- Vertical slice scope: casual 1v1 and 3v3, first to 7 round wins.

local MatchService = {
	Name = "MatchService",
}

function MatchService:Init()
	-- TODO(#issue): create remotes, build team containers, register player
	-- added/removing hooks.
end

function MatchService:Start()
	-- TODO(#issue): implement the round state machine:
	-- WaitingForPlayers -> PreRound (8s) -> Active (90s) -> Overtime | PostRound
	-- First team to GameConfig.Match.RoundWinTarget wins the match.
end

return MatchService
