--!strict
-- Cryo Foundry graybox (issue #11) — the first Island X sector, per
-- MASTERPLAN.md sections 6 and 16. Geometry is generated mirrored across
-- X = 0 so side timings to center and both special positions are equal by
-- construction. All marker parts are found by name:
--   SpawnAlpha1..5 / SpawnBravo1..5, SpecialAmmoSpawnA/B,
--   HeavyAmmoSpawn, OvertimeZoneMarker, KillVolume.

local CryoFoundry = {}

local GRAY = Color3.fromRGB(140, 148, 158)
local FROST = Color3.fromRGB(170, 196, 214)
local ALPHA_TINT = Color3.fromRGB(120, 150, 200)
local BRAVO_TINT = Color3.fromRGB(200, 140, 120)

type PartProps = {
	Name: string?,
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Transparency: number?,
	CanCollide: boolean?,
	Parent: Instance,
}

local function part(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.Name or "GrayboxPart"
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Color = props.Color or GRAY
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.CanCollide = props.CanCollide ~= false
	p.Anchored = true
	p.Parent = props.Parent
	return p
end

local function wedge(size: Vector3, cframe: CFrame, parent: Instance)
	local w = Instance.new("WedgePart")
	w.Size = size
	w.CFrame = cframe
	w.Color = GRAY
	w.Material = Enum.Material.SmoothPlastic
	w.Anchored = true
	w.Parent = parent
end

-- Builds one team side (negative X); mirrored for the other side.
local function buildSide(model: Model, sign: number, teamName: string, tint: Color3)
	-- Five spawn markers, spaced across Z.
	for index = 1, 5 do
		local z = (index - 3) * 14
		part({
			Name = `Spawn{teamName}{index}`,
			Size = Vector3.new(4, 1, 4),
			CFrame = CFrame.new(sign * 72, 0.5, z),
			Color = tint,
			Transparency = 0.5,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Spawn cover wall: blocks direct sightlines into the spawn area;
	-- exits flow around |Z| > 20.
	part({
		Name = teamName .. "SpawnWall",
		Size = Vector3.new(2, 10, 40),
		CFrame = CFrame.new(sign * 58, 5, 0),
		Parent = model,
	})

	-- Mirrored cover: crates and low walls between spawn and mid.
	local crates = {
		Vector3.new(sign * 42, 2, -22),
		Vector3.new(sign * 42, 2, 22),
		Vector3.new(sign * 28, 2, 0),
		Vector3.new(sign * 22, 2, -38),
		Vector3.new(sign * 22, 2, 38),
	}
	for _, position in crates do
		part({
			Name = "Crate",
			Size = Vector3.new(4, 4, 4),
			CFrame = CFrame.new(position),
			Parent = model,
		})
	end

	part({
		Name = "LowWall",
		Size = Vector3.new(10, 3, 2),
		CFrame = CFrame.new(sign * 14, 1.5, -20),
		Parent = model,
	})
	part({
		Name = "LowWall",
		Size = Vector3.new(10, 3, 2),
		CFrame = CFrame.new(sign * 14, 1.5, 20),
		Parent = model,
	})

	-- Ramp up the central core, one per side for equal access.
	wedge(
		Vector3.new(10, 6, 12),
		CFrame.new(sign * 15, 3, 0) * CFrame.Angles(0, sign > 0 and -math.pi / 2 or math.pi / 2, 0),
		model
	)
end

function CryoFoundry.build(): Model
	local model = Instance.new("Model")
	model.Name = "CryoFoundry"

	-- Floor and perimeter.
	part({
		Name = "Floor",
		Size = Vector3.new(170, 4, 110),
		CFrame = CFrame.new(0, -2, 0),
		Color = FROST,
		Parent = model,
	})
	part({ Name = "WallEast", Size = Vector3.new(2, 60, 110), CFrame = CFrame.new(85, 30, 0), Parent = model })
	part({ Name = "WallWest", Size = Vector3.new(2, 60, 110), CFrame = CFrame.new(-85, 30, 0), Parent = model })
	part({ Name = "WallNorth", Size = Vector3.new(170, 60, 2), CFrame = CFrame.new(0, 30, -55), Parent = model })
	part({ Name = "WallSouth", Size = Vector3.new(170, 60, 2), CFrame = CFrame.new(0, 30, 55), Parent = model })

	-- Central core: contested high ground holding heavy ammo.
	part({
		Name = "FoundryCore",
		Size = Vector3.new(18, 6, 18),
		CFrame = CFrame.new(0, 3, 0),
		Parent = model,
	})
	part({
		Name = "HeavyAmmoSpawn",
		Size = Vector3.new(3, 1, 3),
		CFrame = CFrame.new(0, 6.5, 0),
		Color = Color3.fromRGB(230, 170, 60),
		Transparency = 0.4,
		CanCollide = false,
		Parent = model,
	})
	part({
		Name = "OvertimeZoneMarker",
		Size = Vector3.new(24, 1, 24),
		CFrame = CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(90, 180, 255),
		Transparency = 0.85,
		CanCollide = false,
		Parent = model,
	})

	-- Special ammo pads on the center line — equidistant from both teams.
	part({
		Name = "SpecialAmmoSpawnA",
		Size = Vector3.new(3, 1, 3),
		CFrame = CFrame.new(0, 0.5, -40),
		Color = Color3.fromRGB(120, 220, 120),
		Transparency = 0.4,
		CanCollide = false,
		Parent = model,
	})
	part({
		Name = "SpecialAmmoSpawnB",
		Size = Vector3.new(3, 1, 3),
		CFrame = CFrame.new(0, 0.5, 40),
		Color = Color3.fromRGB(120, 220, 120),
		Transparency = 0.4,
		CanCollide = false,
		Parent = model,
	})

	buildSide(model, -1, "Alpha", ALPHA_TINT)
	buildSide(model, 1, "Bravo", BRAVO_TINT)

	-- Safety net far below the playable space.
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

-- Collects spawn CFrames for a team from a built map model.
function CryoFoundry.getSpawns(map: Model, teamName: string): { CFrame }
	local spawns = {}
	for _, child in map:GetChildren() do
		if child:IsA("BasePart") and child.Name:sub(1, 5 + #teamName) == "Spawn" .. teamName then
			table.insert(spawns, child.CFrame)
		end
	end
	table.sort(spawns, function(a, b)
		return a.Position.Z < b.Position.Z
	end)
	return spawns
end

return CryoFoundry
