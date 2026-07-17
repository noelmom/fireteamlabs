--!strict
-- Client entry point. Will own the input abstraction, camera/FOV handling,
-- viewmodel, and HUD wiring (MASTERPLAN.md section 10).

print("[ClientBootstrap] Fireteam Labs client started")

-- TODO(#issue): central input abstraction reading Shared/Constants/Keybinds,
-- so gamepad, mobile, and rebinding can be added without touching gameplay.
