--!strict
-- Test entry point, run in CI and locally with: lune run tests/run.luau
-- Tests reference GitHub issues per MASTERPLAN.md section 22.

local specs = {
	require("./specs/damage-math.spec"),
}

local passed = 0
local failed = 0

for _, spec in specs do
	for name, test in spec do
		local ok, err = pcall(test)
		if ok then
			passed += 1
			print(`PASS {name}`)
		else
			failed += 1
			print(`FAIL {name}: {err}`)
		end
	end
end

print(`{passed} passed, {failed} failed`)
if failed > 0 then
	error("test suite failed")
end
