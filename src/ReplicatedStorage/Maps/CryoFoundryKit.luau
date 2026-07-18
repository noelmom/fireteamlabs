--!strict
-- Iceworld structural kit: uploaded Roblox asset IDs + native sizes (meters).
--
-- The kit is modelled at real metric scale (2 m module grid); the arena is in
-- studs. `StudsPerMeter` scales the kit into the map. We scale uniformly with
-- Model:ScaleTo (axis-agnostic) so proportions hold regardless of the
-- Blender->fbx->Roblox axis mapping. Pieces are Model assets uploaded via the
-- Open Cloud Assets API (owner 11301809536); sources in
-- assets/environment-kit/iceworld/. See ASSET_MANIFEST.md.

export type KitPiece = {
	assetId: number,
	sizeMeters: Vector3,
}

local CryoFoundryKit = {
	-- 0.28 m/stud is Roblox's human scale; tune this one number to fix kit scale.
	StudsPerMeter = 1 / 0.28,

	Pieces = {
		FloorSolid = { assetId = 96083800617355, sizeMeters = Vector3.new(2, 2, 0.17) },
		FloorGrate = { assetId = 76564344019597, sizeMeters = Vector3.new(2, 2, 0.10) },
		WallPanel = { assetId = 124740759406418, sizeMeters = Vector3.new(2, 0.25, 3) },
		WallHalf = { assetId = 98719020810195, sizeMeters = Vector3.new(2.04, 0.27, 1.22) },
		Doorway = { assetId = 112092694066189, sizeMeters = Vector3.new(2, 0.32, 3) },
		CeilingPanel = { assetId = 84855467486912, sizeMeters = Vector3.new(2, 2, 0.2) },
		Pillar = { assetId = 80081726829826, sizeMeters = Vector3.new(0.62, 0.62, 3) },
	} :: { [string]: KitPiece },
}

return CryoFoundryKit
