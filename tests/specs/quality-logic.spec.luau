--!strict
-- Tests for the quality-tier resolution (visual-direction pivot).

local QualityLogic = require("../../src/ReplicatedStorage/Shared/Utility/QualityLogic")

local ORDER = { "Low", "Medium", "High" }

local function assertEq(actual: any, expected: any, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`)
	end
end

return {
	["valid tier detection"] = function()
		assertEq(QualityLogic.isValidTier(ORDER, "High"), true, "High valid")
		assertEq(QualityLogic.isValidTier(ORDER, "Ultra"), false, "Ultra invalid")
	end,

	["Auto resolves to the auto tier"] = function()
		assertEq(QualityLogic.resolveTier(ORDER, "Auto", "Medium", "Low"), "Medium", "auto -> medium")
	end,

	["Auto falls back when the auto tier is bogus"] = function()
		assertEq(QualityLogic.resolveTier(ORDER, "Auto", "Ultra", "Low"), "Low", "auto bad -> fallback")
	end,

	["an explicit valid tier is kept"] = function()
		assertEq(QualityLogic.resolveTier(ORDER, "High", "Medium", "Low"), "High", "explicit high")
	end,

	["an invalid selection falls back"] = function()
		assertEq(QualityLogic.resolveTier(ORDER, "Potato", "Medium", "Low"), "Low", "bad -> fallback")
	end,

	["stepping clamps at the ends"] = function()
		assertEq(QualityLogic.stepTier(ORDER, "Medium", 1), "High", "up")
		assertEq(QualityLogic.stepTier(ORDER, "High", 1), "High", "clamp high")
		assertEq(QualityLogic.stepTier(ORDER, "Medium", -1), "Low", "down")
		assertEq(QualityLogic.stepTier(ORDER, "Low", -1), "Low", "clamp low")
	end,
}
