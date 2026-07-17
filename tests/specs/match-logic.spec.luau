--!strict
-- Tests for issue #2: round resolution, scoring, match win, side rotation
-- (MASTERPLAN.md sections 8, 22).

local MatchLogic = require("../../src/ReplicatedStorage/Shared/Utility/MatchLogic")

local function assertEq(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

return {
	["round continues while both teams have someone alive"] = function()
		assertEq(MatchLogic.resolveElimination(3, 1), nil, "3v1")
		assertEq(MatchLogic.resolveElimination(1, 1), nil, "1v1")
	end,

	["a team wiped loses the round"] = function()
		assertEq(MatchLogic.resolveElimination(2, 0), "Alpha", "bravo wiped")
		assertEq(MatchLogic.resolveElimination(0, 2), "Bravo", "alpha wiped")
	end,

	["simultaneous wipe is a draw"] = function()
		assertEq(MatchLogic.resolveElimination(0, 0), "Draw", "double KO")
	end,

	["awarding a round increments only the winner"] = function()
		local scores = MatchLogic.awardRound({ Alpha = 2, Bravo = 3 }, "Alpha")
		assertEq(scores.Alpha, 3, "alpha")
		assertEq(scores.Bravo, 3, "bravo")
	end,

	["a draw awards no points"] = function()
		local scores = MatchLogic.awardRound({ Alpha = 4, Bravo = 4 }, "Draw")
		assertEq(scores.Alpha, 4, "alpha")
		assertEq(scores.Bravo, 4, "bravo")
	end,

	["awardRound does not mutate the input"] = function()
		local original = { Alpha = 1, Bravo = 1 }
		MatchLogic.awardRound(original, "Bravo")
		assertEq(original.Alpha, 1, "alpha untouched")
		assertEq(original.Bravo, 1, "bravo untouched")
	end,

	["match is won at the target"] = function()
		assertEq(MatchLogic.matchWinner({ Alpha = 7, Bravo = 5 }, 7), "Alpha", "alpha wins")
		assertEq(MatchLogic.matchWinner({ Alpha = 6, Bravo = 7 }, 7), "Bravo", "bravo wins")
		assertEq(MatchLogic.matchWinner({ Alpha = 6, Bravo = 6 }, 7), nil, "no winner yet")
	end,

	["match point detection"] = function()
		assertEq(MatchLogic.isMatchPoint({ Alpha = 6, Bravo = 3 }, 7), true, "alpha match point")
		assertEq(MatchLogic.isMatchPoint({ Alpha = 5, Bravo = 6 }, 7), true, "bravo match point")
		assertEq(MatchLogic.isMatchPoint({ Alpha = 5, Bravo = 5 }, 7), false, "not match point")
	end,

	["side rotation swaps on even rounds when enabled"] = function()
		assertEq(MatchLogic.sideForTeam("Alpha", 1, true), "Alpha", "round 1 home")
		assertEq(MatchLogic.sideForTeam("Alpha", 2, true), "Bravo", "round 2 swapped")
		assertEq(MatchLogic.sideForTeam("Bravo", 2, true), "Alpha", "round 2 swapped bravo")
		assertEq(MatchLogic.sideForTeam("Alpha", 2, false), "Alpha", "rotation disabled")
	end,
}
