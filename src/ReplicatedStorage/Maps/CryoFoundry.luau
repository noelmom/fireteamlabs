--!strict
-- Cryo Foundry blockout (issue #41) — the first Island X sector, redesigned
-- from earlyartwork/map-concepts/cryo-foundry-redesign-idea2.png. A 128x128
-- symmetrical arena with three walkable layers (ground 0, mid 8, high 16):
--
--   * Mirrored North/South elevated spawns (side rotation stays fair). The
--     logical spawn sides keep the names Alpha (North) and Bravo (South) so
--     MapService's side rotation is unchanged.
--   * A sunken center ring — the overtime zone — holding the single Heavy
--     pickup (high risk, exposed from the mid-level bridges and high ground).
--   * Two equidistant side ledges carrying the Special pickups (contested).
--   * Three N-S lanes, mid-level East/West bridges, ramps between layers, and
--     tall central spires that break the direct spawn-to-spawn sightline.
--
-- Marker parts (found by name): SpawnAlpha1..5 / SpawnBravo1..5,
-- SpecialAmmoSpawnA / SpecialAmmoSpawnB, HeavyAmmoSpawn, OvertimeZoneMarker,
-- KillVolume. Geometry is mirrored across Z=0 (N/S) and X=0 (E/W) so side
-- timings are equal by construction.

local CryoFoundry = {}

local HALF = 64
local Y_GROUND, Y_MID, Y_HIGH = 0, 8, 16

local FLOOR = Color3.fromRGB(196, 214, 226)
local STRUCT = Color3.fromRGB(150, 162, 176)
local DARK = Color3.fromRGB(96, 108, 124)
local ALPHA_TINT = Color3.fromRGB(120, 150, 200)
local BRAVO_TINT = Color3.fromRGB(200, 140, 120)
local SPECIAL_MARK = Color3.fromRGB(120, 220, 120)
local HEAVY_MARK = Color3.fromRGB(230, 170, 60)
local ZONE_MARK = Color3.fromRGB(90, 180, 255)

type PartProps = {
	Name: string?,
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	CanCollide: boolean?,
	Parent: Instance,
}

local function part(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.Name or "Block"
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Color = props.Color or STRUCT
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.CanCollide = props.CanCollide ~= false
	p.Anchored = true
	p.Parent = props.Parent
	return p
end

-- A walkable ramp connecting a low point to a high point in a vertical plane.
local function ramp(lowPos: Vector3, highPos: Vector3, width: number, parent: Instance)
	local mid = (lowPos + highPos) / 2
	local length = (highPos - lowPos).Magnitude
	local p = Instance.new("Part")
	p.Name = "Ramp"
	p.Size = Vector3.new(width, 1, length)
	p.CFrame = CFrame.lookAt(mid, highPos)
	p.Color = DARK
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function marker(name: string, position: Vector3, color: Color3, parent: Instance)
	part({
		Name = name,
		Size = Vector3.new(3, 1, 3),
		CFrame = CFrame.new(position),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
		Parent = parent,
	})
end

-- One team's approach: high spawn -> ramp -> mid platform -> ramp -> ground.
-- sign = -1 for North (Alpha), +1 for South (Bravo).
local function buildApproach(model: Model, sign: number, sideName: string, tint: Color3)
	local spawnZ = sign * 54
	part({
		Name = sideName .. "SpawnPlatform",
		Size = Vector3.new(46, 2, 16),
		CFrame = CFrame.new(0, Y_HIGH, spawnZ),
		Color = tint,
		Parent = model,
	})
	part({
		Name = sideName .. "SpawnWall",
		Size = Vector3.new(52, 16, 2),
		CFrame = CFrame.new(0, Y_HIGH + 8, sign * 62),
		Parent = model,
	})
	for index = 1, 5 do
		marker(`Spawn{sideName}{index}`, Vector3.new((index - 3) * 9, Y_HIGH + 1.5, spawnZ), tint, model)
	end

	-- High spawn down to the mid platform.
	ramp(Vector3.new(0, Y_MID, sign * 42), Vector3.new(0, Y_HIGH, sign * 48), 14, model)

	-- Mid high-ground platform overlooking the center.
	part({
		Name = sideName .. "Platform",
		Size = Vector3.new(36, 2, 14),
		CFrame = CFrame.new(0, Y_MID, sign * 38),
		Parent = model,
	})
	-- Two side ramps from the mid platform down to the ground lanes.
	for _, xSign in { -1, 1 } do
		ramp(Vector3.new(xSign * 14, Y_GROUND, sign * 28), Vector3.new(xSign * 14, Y_MID, sign * 34), 8, model)
	end

	-- Tall sightline breaker between platform and center (breaks the spawn line).
	part({
		Name = "CenterSpire",
		Size = Vector3.new(10, 22, 4),
		CFrame = CFrame.new(0, 11, sign * 20),
		Color = STRUCT,
		Parent = model,
	})
end

-- One side ledge (mid level) carrying a Special pickup, plus a bridge toward
-- the center and a ramp down to the ground. sign = -1 West, +1 East.
local function buildLedge(model: Model, sign: number, ledgeName: string, specialMarkerName: string)
	part({
		Name = ledgeName,
		Size = Vector3.new(18, 2, 30),
		CFrame = CFrame.new(sign * 52, Y_MID, 0),
		Parent = model,
	})
	marker(specialMarkerName, Vector3.new(sign * 52, Y_MID + 1.5, 0), SPECIAL_MARK, model)

	-- Mid-level bridge from the ledge toward the center ring.
	part({
		Name = ledgeName .. "Bridge",
		Size = Vector3.new(26, 1.5, 12),
		CFrame = CFrame.new(sign * 30, Y_MID, 0),
		Color = DARK,
		Parent = model,
	})
	-- Ramp from the ledge down to the ground flank.
	ramp(Vector3.new(sign * 58, Y_GROUND, sign * 18), Vector3.new(sign * 52, Y_MID, sign * 12), 8, model)
end

local function buildCenter(model: Model)
	-- Ground-level ring floor (kept open; contested from above).
	part({
		Name = "CenterRing",
		Size = Vector3.new(30, 1, 30),
		CFrame = CFrame.new(0, 0.5, 0),
		Color = FLOOR,
		Parent = model,
	})
	-- Low ring lip for a touch of cover at ground level.
	for _, xz in { Vector3.new(0, 0, -16), Vector3.new(0, 0, 16), Vector3.new(-16, 0, 0), Vector3.new(16, 0, 0) } do
		local along = if xz.X == 0 then Vector3.new(18, 3, 2) else Vector3.new(2, 3, 18)
		part({ Name = "RingLip", Size = along, CFrame = CFrame.new(xz.X, 1.5, xz.Z), Color = DARK, Parent = model })
	end

	marker("OvertimeZoneMarker", Vector3.new(0, 0.6, 0), ZONE_MARK, model)
	-- Overtime marker doubles the visual; enlarge it flat over the ring.
	local zone = model:FindFirstChild("OvertimeZoneMarker") :: BasePart
	zone.Size = Vector3.new(24, 1, 24)
	zone.Transparency = 0.85

	marker("HeavyAmmoSpawn", Vector3.new(0, 1.4, 0), HEAVY_MARK, model)
end

-- Mirrored cover (crates, low walls) building the three lanes and flank routes.
local function buildCover(model: Model)
	-- Lane-dividing walls at |x| = 24, segmented with gaps, mid-height cover.
	for _, xSign in { -1, 1 } do
		for _, z in { -30, 0, 30 } do
			part({
				Name = "LaneWall",
				Size = Vector3.new(2, 6, 16),
				CFrame = CFrame.new(xSign * 24, 3, z),
				Parent = model,
			})
		end
	end

	-- Crates mirrored across both axes.
	local crateSpots = {
		Vector3.new(38, 2, 26),
		Vector3.new(12, 2, 30),
		Vector3.new(40, 2, 0),
		Vector3.new(20, 2, 10),
	}
	for _, spot in crateSpots do
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				part({
					Name = "Crate",
					Size = Vector3.new(4, 4, 4),
					CFrame = CFrame.new(sx * spot.X, spot.Y, sz * spot.Z),
					Color = DARK,
					Parent = model,
				})
			end
		end
	end
end

function CryoFoundry.build(): Model
	local model = Instance.new("Model")
	model.Name = "CryoFoundry"

	part({
		Name = "Floor",
		Size = Vector3.new(HALF * 2, 4, HALF * 2),
		CFrame = CFrame.new(0, -2, 0),
		Color = FLOOR,
		Parent = model,
	})
	for _, wall in
		{
			{ Vector3.new(2, 60, HALF * 2), CFrame.new(HALF, 30, 0) },
			{ Vector3.new(2, 60, HALF * 2), CFrame.new(-HALF, 30, 0) },
			{ Vector3.new(HALF * 2, 60, 2), CFrame.new(0, 30, HALF) },
			{ Vector3.new(HALF * 2, 60, 2), CFrame.new(0, 30, -HALF) },
		}
	do
		part({ Name = "Perimeter", Size = wall[1] :: Vector3, CFrame = wall[2] :: CFrame, Parent = model })
	end

	buildApproach(model, -1, "Alpha", ALPHA_TINT)
	buildApproach(model, 1, "Bravo", BRAVO_TINT)
	buildLedge(model, -1, "CrystalLedge", "SpecialAmmoSpawnA")
	buildLedge(model, 1, "GlacierLedge", "SpecialAmmoSpawnB")
	buildCenter(model)
	buildCover(model)

	part({
		Name = "KillVolume",
		Size = Vector3.new(400, 2, 400),
		CFrame = CFrame.new(0, -40, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})

	return model
end

-- Collects spawn CFrames for a physical side ("Alpha" = North, "Bravo" = South).
function CryoFoundry.getSpawns(map: Model, side: string): { CFrame }
	local spawns = {}
	local prefix = "Spawn" .. side
	for _, child in map:GetChildren() do
		if child:IsA("BasePart") and child.Name:sub(1, #prefix) == prefix and #child.Name > #prefix then
			table.insert(spawns, child.CFrame)
		end
	end
	table.sort(spawns, function(a, b)
		return a.Position.X < b.Position.X
	end)
	return spawns
end

return CryoFoundry
