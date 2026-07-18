--!strict
-- Cryo Foundry hero props & set-dressing: Roblox asset IDs + import metadata.
--
-- These are Meshy-generated meshes uploaded to Roblox via the Open Cloud Assets
-- API (owner userId 11301809536). Each is a Model asset loaded server-side with
-- InsertService:LoadAsset. `scale` is the target height in studs (the source
-- meshes are ~1.9 studs tall at import); `glow` marks the cyan energy element
-- that gets an emissive material + light in the dressing pass.
--
-- Sources live in assets/props/cryo-foundry/. See ASSET_MANIFEST.md.

export type PropDef = {
	assetId: number,
	targetHeightStuds: number,
	glow: boolean,
}

local CryoFoundryProps: { [string]: PropDef } = {
	ReactorCore = { assetId = 76349369397288, targetHeightStuds = 15, glow = true },
	CoolantTank = { assetId = 97824920640367, targetHeightStuds = 5.5, glow = true },
	ControlConsole = { assetId = 100259194132302, targetHeightStuds = 3.2, glow = true },
	PipeManifold = { assetId = 138014456441050, targetHeightStuds = 4.5, glow = false },
}

return CryoFoundryProps
