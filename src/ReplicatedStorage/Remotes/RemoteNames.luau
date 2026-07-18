--!strict
-- Names of RemoteEvents/RemoteFunctions created by the server at startup.
-- All remotes are server-authoritative: clients send requests, the server
-- validates and decides (MASTERPLAN.md section 20).

local RemoteNames = {
	-- Client -> Server requests
	FireWeaponRequest = "FireWeaponRequest",
	ReloadRequest = "ReloadRequest",
	EquipSlotRequest = "EquipSlotRequest",
	UseAbilityRequest = "UseAbilityRequest",
	SetClassRequest = "SetClassRequest",
	ThrowGrenadeRequest = "ThrowGrenadeRequest",
	InteractRequest = "InteractRequest",

	-- Server -> Client state
	MatchStateChanged = "MatchStateChanged",
	PlayerStateChanged = "PlayerStateChanged",
	WeaponStateChanged = "WeaponStateChanged",
	WeaponFiredBroadcast = "WeaponFiredBroadcast",
	AbilityStateChanged = "AbilityStateChanged",
	AbilityEffect = "AbilityEffect",
	CombatFeedback = "CombatFeedback",
	EliminationBroadcast = "EliminationBroadcast",
}

return RemoteNames
