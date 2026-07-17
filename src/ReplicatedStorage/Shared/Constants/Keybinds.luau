--!strict
-- Default keyboard bindings (MASTERPLAN.md section 10).
-- All input must flow through a central input abstraction so gamepad, mobile,
-- and rebinding can be added without touching gameplay code.

local Keybinds = {
	Jump = Enum.KeyCode.Space,
	Sprint = Enum.KeyCode.LeftShift,
	Crouch = Enum.KeyCode.LeftControl,
	Reload = Enum.KeyCode.R,
	SlotPrimary = Enum.KeyCode.One,
	SlotSpecial = Enum.KeyCode.Two,
	SlotHeavy = Enum.KeyCode.Three,
	SlotKnife = Enum.KeyCode.Four,
	Grenade = Enum.KeyCode.G,
	ClassAbility = Enum.KeyCode.F,
	Interact = Enum.KeyCode.E,
	CommWheel = Enum.KeyCode.B,
	Scoreboard = Enum.KeyCode.Tab,
}

return Keybinds
