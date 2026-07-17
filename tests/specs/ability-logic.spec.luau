--!strict
-- Tests for issue #10: class ability cooldown (MASTERPLAN.md sections 15, 22).

local AbilityLogic = require("../../src/ReplicatedStorage/Shared/Utility/AbilityLogic")

local function assertEq(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

return {
	["ability is on cooldown until the end time"] = function()
		assertEq(AbilityLogic.isReady(100, 125), false, "mid cooldown")
		assertEq(AbilityLogic.isReady(125, 125), true, "exactly ready")
		assertEq(AbilityLogic.isReady(130, 125), true, "past ready")
	end,

	["cooldown remaining clamps at zero"] = function()
		assertEq(AbilityLogic.cooldownRemaining(100, 125), 25, "25s left")
		assertEq(AbilityLogic.cooldownRemaining(120, 125), 5, "5s left")
		assertEq(AbilityLogic.cooldownRemaining(130, 125), 0, "already ready")
	end,
}
