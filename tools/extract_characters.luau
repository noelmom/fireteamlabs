--!strict
-- Extracts the three operator rigs (Specter/Conduit/Bulwark) from a saved
-- Studio place file into src/ReplicatedStorage/Characters/<Class>.rbxm so
-- Rojo builds ship them. The rigs are produced in Studio by the 3D Importer +
-- Avatar Auto-Setup (see ASSET_MANIFEST.md); this script just moves them from
-- the place's Workspace into the repo.
--
-- Usage: lune run tools/extract_characters.luau -- <path-to-place.rbxl>

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

-- lune passes a literal "--" through in some invocations; skip it.
local placePath = process.args[1] ~= "--" and process.args[1] or process.args[2]
assert(placePath, "usage: lune run tools/extract_characters.luau <place.rbxl>")

local game = roblox.deserializePlace(fs.readFile(placePath))
local workspaceService = game:GetService("Workspace")

local outDir = "src/ReplicatedStorage/Characters"
if not fs.isDir(outDir) then
	fs.writeDir(outDir)
end

for _, className in { "Specter", "Conduit", "Bulwark" } do
	local rig = workspaceService:FindFirstChild(className)
	assert(rig, `rig '{className}' not found in {placePath} Workspace`)
	local outPath = `{outDir}/{className}.rbxm`
	fs.writeFile(outPath, roblox.serializeModel({ rig }))
	print(`wrote {outPath}`)
end

print("done")
