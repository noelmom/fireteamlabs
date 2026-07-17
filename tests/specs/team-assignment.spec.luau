--!strict
-- Tests for issue #3: balanced assignment and match sizing
-- (MASTERPLAN.md sections 7-8, 22).

local TeamAssignment = require("../../src/ReplicatedStorage/Shared/Utility/TeamAssignment")

local function assertEq(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

return {
	["joiners fill the smaller team, ties to Alpha"] = function()
		assertEq(TeamAssignment.pickTeam(0, 0), "Alpha", "empty")
		assertEq(TeamAssignment.pickTeam(1, 0), "Bravo", "alpha ahead")
		assertEq(TeamAssignment.pickTeam(1, 1), "Alpha", "tie")
		assertEq(TeamAssignment.pickTeam(2, 3), "Alpha", "bravo ahead")
		assertEq(TeamAssignment.pickTeam(3, 1), "Bravo", "alpha further ahead")
	end,

	["match sizing picks the largest supported size that fits"] = function()
		local sizes = { 1, 3 }
		assertEq(TeamAssignment.selectTeamSize(1, sizes), nil, "too few")
		assertEq(TeamAssignment.selectTeamSize(2, sizes), 1, "1v1")
		assertEq(TeamAssignment.selectTeamSize(5, sizes), 1, "still 1v1")
		assertEq(TeamAssignment.selectTeamSize(6, sizes), 3, "3v3")
		assertEq(TeamAssignment.selectTeamSize(9, sizes), 3, "3v3 with spare")
	end,

	["match sizing is order-independent"] = function()
		assertEq(TeamAssignment.selectTeamSize(6, { 3, 1 }), 3, "unsorted sizes")
	end,
}
