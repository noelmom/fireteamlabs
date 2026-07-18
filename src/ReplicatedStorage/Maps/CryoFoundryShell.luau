--!strict
-- Cryo Foundry structural-kit cladding. First step is a CALIBRATION pass: it
-- lays a small floor patch plus one of every structural piece at known
-- coordinates so a Studio screenshot reveals the true meters->studs scale, the
-- Blender->Roblox axis/orientation, and each piece's pivot. Once those are
-- confirmed, this expands to full floor/wall cladding over the graybox (which
-- stays as invisible collision).
--
-- Cosmetic + best-effort (pcall); never touches spawns, markers, or collision.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Maps.CryoFoundryKit)

local CryoFoundryShell = {}

local SPM: number = Kit.StudsPerMeter

-- Load a kit piece once, scale meters->studs, disable collision, cache as a
-- reusable template. Returns nil on failure.
local templates: { [string]: Model } = {}
local function template(name: string): Model?
	if templates[name] then
		return templates[name]
	end
	local def = Kit.Pieces[name]
	if not def then
		return nil
	end
	local ok, container = pcall(function()
		return InsertService:LoadAsset(def.assetId)
	end)
	if not ok or not container then
		warn(`[CryoFoundryShell] load {name} ({def.assetId}) failed: {container}`)
		return nil
	end

	local prop = container:FindFirstChildWhichIsA("Model") or container:FindFirstChildWhichIsA("BasePart")
	if not prop then
		container:Destroy()
		return nil
	end
	local model: Model
	if prop:IsA("Model") then
		model = prop
	else
		model = Instance.new("Model")
		prop.Parent = model
	end
	model.Parent = nil
	container:Destroy()

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	-- Normalize by the actual imported bounding box: make the piece's longest
	-- side equal its real-world longest side (meters) x StudsPerMeter. Robust to
	-- whatever unit scale / axis orientation Roblox used on import.
	local ext = model:GetExtentsSize()
	local importedMax = math.max(ext.X, ext.Y, ext.Z)
	local realMax = math.max(def.sizeMeters.X, def.sizeMeters.Y, def.sizeMeters.Z)
	if importedMax > 0 then
		model:ScaleTo((realMax * SPM) / importedMax)
	end
	model.Name = name
	templates[name] = model
	return model
end

local function placeClone(name: string, parent: Instance, cframe: CFrame): Model?
	local t = template(name)
	if not t then
		return nil
	end
	local clone = t:Clone()
	clone:PivotTo(cframe)
	clone.Parent = parent
	return clone
end

-- Calibration set: a floor patch + a labelled row of every structural piece.
function CryoFoundryShell.calibrate(map: Model)
	local shell = Instance.new("Folder")
	shell.Name = "KitCalibration"
	shell.Parent = map

	-- Floor patch (6x6 tiles) offset to the North-East quadrant so it sits
	-- beside the graybox without hiding the center. Judge tile scale + seams.
	local tile = 2 * SPM
	local originX, originZ = 12, 12
	for i = 0, 5 do
		for j = 0, 5 do
			placeClone("FloorSolid", shell, CFrame.new(originX + i * tile, 0.2, originZ + j * tile))
		end
	end

	-- One of every piece in a row along -Z, spaced 8 studs, for scale/axis read.
	local row = {
		"WallPanel",
		"WallHalf",
		"Doorway",
		"Pillar",
		"FloorGrate",
		"CeilingPanel",
	}
	for index, name in row do
		placeClone(name, shell, CFrame.new(-30 + (index - 1) * 9, 0, 28))
	end
end

return CryoFoundryShell
