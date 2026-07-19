--!strict
-- Cryo Foundry structural-kit cladding (visual-direction pivot). The
-- calibration pass confirmed the kit imports at exact metric scale (2 m module
-- = 7.14 studs), upright, with base-center pivots, but with bare untextured
-- geometry — so each piece gets an engine PBR material + color here.
--
-- clad() skins the graybox: kit floor tiles/wall panels/pillars over the big
-- surfaces (cosmetic clones, CanCollide false — the graybox keeps collision),
-- plus a material restyle of the remaining graybox parts so uncladded
-- geometry reads as the same cold industrial space instead of SmoothPlastic.
--
-- Cosmetic + best-effort (pcall); never touches spawns, markers, or collision.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IceworldMaterials = require(ReplicatedStorage.Maps.IceworldMaterials)
local Kit = require(ReplicatedStorage.Maps.CryoFoundryKit)

local CryoFoundryShell = {}

local SPM: number = Kit.StudsPerMeter
local TILE = 2 * SPM -- 2 m module = 7.14 studs

-- Engine materials per piece: the kit ships untextured, so surface character
-- comes from Roblox PBR materials over the kit's beveled geometry.
-- Alternate floor-tile shade: a two-tone checker makes the 2 m module grid
-- read at a glance where single-color concrete looks like one smooth slab.
local FLOOR_ALT_COLOR = Color3.fromRGB(139, 150, 164)

type Style = { Material: Enum.Material, Color: Color3, Variant: string? }
local PIECE_STYLE: { [string]: Style } = {
	FloorSolid = {
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(190, 198, 207),
		Variant = "iceworld_concrete_floor",
	},
	FloorGrate = {
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(140, 150, 162),
		Variant = "iceworld_deck_grate",
	},
	WallPanel = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(168, 178, 190),
		Variant = "iceworld_metal_panel",
	},
	WallHalf = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(150, 160, 172),
		Variant = "iceworld_metal_panel",
	},
	Doorway = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(130, 140, 152),
		Variant = "iceworld_metal_panel",
	},
	Pillar = { Material = Enum.Material.Metal, Color = Color3.fromRGB(140, 148, 160), Variant = "iceworld_metal_panel" },
	CeilingPanel = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(160, 168, 180),
		Variant = "iceworld_metal_panel",
	},
}

-- Restyle for graybox parts that stay visible (by part Name). Color nil keeps
-- the blockout's color (team tints, floor shade) and only upgrades material.
local GRAYBOX_STYLE: { [string]: { Material: Enum.Material, Color: Color3?, Variant: string? } } = {
	Floor = {
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(170, 180, 192),
		Variant = "iceworld_concrete_floor",
	},
	Perimeter = {
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(150, 160, 175),
		Variant = "iceworld_fortress_stone",
	},
	CenterRing = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(140, 150, 164),
		Variant = "iceworld_metal_panel",
	},
	RingLip = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(110, 120, 134),
		Variant = "iceworld_metal_panel",
	},
	LaneWall = {
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(140, 150, 165),
		Variant = "iceworld_fortress_stone",
	},
	Crate = {
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(130, 142, 158),
		Variant = "iceworld_deck_grate",
	},
	CenterSpire = {
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(135, 145, 160),
		Variant = "iceworld_fortress_stone",
	},
	Ramp = {
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(150, 160, 172),
		Variant = "iceworld_concrete_floor",
	},
	AlphaSpawnPlatform = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	BravoSpawnPlatform = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	AlphaSpawnWall = { Material = Enum.Material.Slate, Variant = "iceworld_fortress_stone" },
	BravoSpawnWall = { Material = Enum.Material.Slate, Variant = "iceworld_fortress_stone" },
	AlphaPlatform = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	BravoPlatform = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	CrystalLedge = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	GlacierLedge = { Material = Enum.Material.Concrete, Variant = "iceworld_concrete_floor" },
	CrystalLedgeBridge = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(120, 130, 144),
		Variant = "iceworld_metal_panel",
	},
	GlacierLedgeBridge = {
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(120, 130, 144),
		Variant = "iceworld_metal_panel",
	},
}

-- Load a kit piece once, scale meters->studs, style, disable collision, cache
-- as a reusable template. Returns nil on failure.
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

	local style = PIECE_STYLE[name]
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			if style then
				d.Material = style.Material
				d.Color = style.Color
				if style.Variant then
					d.MaterialVariant = style.Variant
				end
			end
		end
	end
	-- Normalize by the actual imported bounding box: make the piece's longest
	-- side equal its real-world longest side (meters) x StudsPerMeter.
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

local function placeClone(name: string, parent: Instance, cframe: CFrame, color: Color3?): Model?
	local t = template(name)
	if not t then
		return nil
	end
	local clone = t:Clone()
	if color then
		for _, d in clone:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = color
			end
		end
	end
	clone:PivotTo(cframe)
	clone.Parent = parent
	return clone
end

-- Lays a rows x cols grid of flat pieces (FloorSolid/FloorGrate/CeilingPanel)
-- centered on (cx, cz) with the piece TOP flush at topY, so feet meet the
-- cosmetic surface exactly where the collision surface is.
local function layGrid(name: string, parent: Instance, cx: number, cz: number, topY: number, cols: number, rows: number)
	local def = Kit.Pieces[name]
	if not def then
		return
	end
	local thickness = math.min(def.sizeMeters.X, def.sizeMeters.Y, def.sizeMeters.Z) * SPM
	local baseY = topY - thickness
	local x0 = cx - (cols - 1) * TILE / 2
	local z0 = cz - (rows - 1) * TILE / 2
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			local color = if name == "FloorSolid" and (i + j) % 2 == 1 then FLOOR_ALT_COLOR else nil
			placeClone(name, parent, CFrame.new(x0 + i * TILE, baseY, z0 + j * TILE), color)
		end
	end
end

-- One row of wall panels along an axis. The panel pivot is base-center with
-- the face plane on the pivot; yawDegrees turns the face into the arena.
local function layWallRow(
	parent: Instance,
	fromX: number,
	fromZ: number,
	toX: number,
	toZ: number,
	baseY: number,
	yawDegrees: number,
	rows: number
)
	local from = Vector3.new(fromX, 0, fromZ)
	local to = Vector3.new(toX, 0, toZ)
	local span = (to - from).Magnitude
	local count = math.floor(span / TILE + 0.5)
	local dir = (to - from).Unit
	local yaw = CFrame.Angles(0, math.rad(yawDegrees), 0)
	for row = 0, rows - 1 do
		for i = 0, count - 1 do
			local pos = from + dir * (TILE / 2 + i * TILE)
			placeClone("WallPanel", parent, CFrame.new(pos.X, baseY + row * 3 * SPM, pos.Z) * yaw)
		end
	end
end

local function restyleGraybox(map: Model)
	for _, child in map:GetChildren() do
		if child:IsA("BasePart") then
			local style = GRAYBOX_STYLE[child.Name]
			if style then
				child.Material = style.Material
				if style.Color then
					child.Color = style.Color
				end
				if style.Variant then
					child.MaterialVariant = style.Variant
				end
			end
		end
	end
end

-- Skins the built graybox with the structural kit + graybox restyle.
function CryoFoundryShell.clad(map: Model)
	IceworldMaterials.ensure()

	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = map

	restyleGraybox(map)

	-- Ground floor: 17x17 module grid flush with the graybox floor top (y=0),
	-- skipping the tiles that would land inside the raised center ring.
	local half = 8 -- tiles each side of center
	for i = -half, half do
		for j = -half, half do
			local cx = i * TILE
			local cz = j * TILE
			if math.max(math.abs(cx), math.abs(cz)) + TILE / 2 > 15 then
				local def = Kit.Pieces.FloorSolid
				local thickness = def.sizeMeters.Z * SPM
				local color = if (i + j) % 2 == 1 then FLOOR_ALT_COLOR else nil
				placeClone("FloorSolid", shell, CFrame.new(cx, -thickness, cz), color)
			end
		end
	end

	-- Overtime ring deck: grates flush with the ring top (y=1).
	layGrid("FloorGrate", shell, 0, 0, 1, 4, 4)

	-- Perimeter walls: three rows of panels (0..32 studs) on each interior
	-- face; the graybox above is restyled dark so it reads as upper shadow.
	local inner = 64 - 1 - 0.1
	layWallRow(shell, -60, -inner, 60, -inner, 0, 0, 3) -- North (faces +Z)
	layWallRow(shell, -60, inner, 60, inner, 0, 180, 3) -- South (faces -Z)
	layWallRow(shell, -inner, -60, -inner, 60, 0, 90, 3) -- West (faces +X)
	layWallRow(shell, inner, -60, inner, 60, 0, 270, 3) -- East (faces -X)

	-- Spawn back walls: one row facing the arena.
	layWallRow(shell, -25, -61, 25, -61, 16, 0, 1)
	layWallRow(shell, -25, 61, 25, 61, 16, 180, 1)

	-- Corner + wall-center pillars for vertical rhythm.
	for _, x in { -60, 0, 60 } do
		for _, z in { -60, 60 } do
			placeClone("Pillar", shell, CFrame.new(x, 0, z))
		end
	end
	for _, x in { -60, 60 } do
		placeClone("Pillar", shell, CFrame.new(x, 0, 0))
	end

	-- Elevated decks: spawn platforms (top 17), mid platforms (top 9), side
	-- ledges (top 9) get solid tiles; bridges (top 8.75) get ceiling panels.
	for _, sign in { -1, 1 } do
		layGrid("FloorSolid", shell, 0, sign * 54, 17, 6, 2)
		layGrid("FloorSolid", shell, 0, sign * 38, 9, 5, 2)
		layGrid("FloorSolid", shell, sign * 52, 0, 9, 2, 4)
		layGrid("CeilingPanel", shell, sign * 30, 0, 8.75, 3, 1)
	end
end

return CryoFoundryShell
