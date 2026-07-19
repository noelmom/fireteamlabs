--!strict
-- Cryo Foundry art-dressing pass: loads the uploaded hero props/set-dressing
-- (CryoFoundryProps) into the graybox, scales + places them, lights the cyan
-- energy elements, and sets the cryo atmosphere. Purely cosmetic — never moves
-- spawns, markers, collision walls, or anything gameplay reads.
--
-- Best-effort: each prop load is wrapped in pcall so a missing/unreplicated
-- asset just logs and is skipped; the playable graybox always remains.

local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Props = require(ReplicatedStorage.Maps.CryoFoundryProps)

local CryoFoundryDressing = {}

local CYAN = Color3.fromRGB(90, 210, 255)

-- Loads a prop asset, scales it to its target height, anchors it, and returns
-- the ready Model (or nil on failure).
local function loadProp(name: string): Model?
	local def = Props[name]
	if not def then
		return nil
	end
	local ok, container = pcall(function()
		return InsertService:LoadAsset(def.assetId)
	end)
	if not ok or not container then
		warn(`[CryoFoundryDressing] could not load {name} ({def.assetId}): {container}`)
		return nil
	end

	-- LoadAsset returns a container Model; the prop is its first child model/part.
	local prop: Instance? = container:FindFirstChildWhichIsA("Model") or container:FindFirstChildWhichIsA("BasePart")
	if not prop then
		container:Destroy()
		return nil
	end
	prop.Parent = nil
	container:Destroy()

	local model: Model
	if prop:IsA("Model") then
		model = prop
	else
		model = Instance.new("Model")
		prop.Parent = model
	end

	-- Anchor everything so props hold their placement.
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end

	-- Scale by the actual imported bounding box: make the model's LONGEST side
	-- equal targetHeightStuds. Using the max axis (not .Y) is robust to whatever
	-- orientation Roblox imported the mesh in, so a sideways import can't blow
	-- the scale up.
	local ext = model:GetExtentsSize()
	local importedMax = math.max(ext.X, ext.Y, ext.Z)
	if importedMax > 0 then
		model:ScaleTo(def.targetHeightStuds / importedMax)
	end

	if def.glow then
		local anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if anchor then
			local light = Instance.new("PointLight")
			light.Color = CYAN
			-- Tuned against the clad arena: the reactor reads as the hero accent
			-- without flooding the whole map cyan (it hangs ~26 studs up).
			light.Brightness = if name == "ReactorCore" then 2.2 else 2.5
			light.Range = if name == "ReactorCore" then 42 else 16
			light.Parent = anchor
		end
	end

	model.Name = name
	return model
end

-- Places a prop with its base resting at baseY (floor y=0 when omitted),
-- facing yawDegrees.
local function place(map: Model, name: string, x: number, z: number, yawDegrees: number, baseY: number?)
	local model = loadProp(name)
	if not model then
		return
	end
	local height = model:GetExtentsSize().Y
	model:PivotTo(CFrame.new(x, (baseY or 0) + height / 2, z) * CFrame.Angles(0, math.rad(yawDegrees), 0))
	model.Parent = map
end

-- Cryo Foundry ice skybox (assets/skybox/cryo-foundry, uploaded 2026-07-18).
local SKYBOX = {
	SkyboxFt = "rbxassetid://112941011438684",
	SkyboxBk = "rbxassetid://118398685869389",
	SkyboxLf = "rbxassetid://88010926208180",
	SkyboxRt = "rbxassetid://78391958742982",
	SkyboxUp = "rbxassetid://114947433908939",
	SkyboxDn = "rbxassetid://135271670707680",
}

-- Cryo mood: cold fog, blue-tinted atmosphere, subtle color grade.
local function applyAtmosphere()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	for face, id in SKYBOX do
		(sky :: any)[face] = id
	end
	sky.SunAngularSize = 8
	sky.MoonAngularSize = 0

	Lighting.ClockTime = 15
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(84, 96, 110)
	Lighting.Ambient = Color3.fromRGB(58, 66, 80)
	Lighting.FogColor = Color3.fromRGB(150, 170, 190)
	Lighting.FogStart = 40
	Lighting.FogEnd = 240

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmo = Instance.new("Atmosphere")
		atmo.Density = 0.42
		atmo.Offset = 0.1
		atmo.Color = Color3.fromRGB(190, 205, 220)
		atmo.Decay = Color3.fromRGB(110, 140, 170)
		atmo.Glare = 0.1
		atmo.Haze = 1.6
		atmo.Parent = Lighting
	end

	local grade = Lighting:FindFirstChild("CryoGrade") :: ColorCorrectionEffect?
	if not grade then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "CryoGrade"
		grade.Parent = Lighting
	end
	grade.TintColor = Color3.fromRGB(210, 226, 240)
	grade.Saturation = -0.05
	grade.Contrast = 0.1
	grade.Brightness = 0.01

	-- Post effects for the AAA read (visual pass #57): restrained bloom on the
	-- neon/emissive accents and soft sun rays through the cold haze.
	if not Lighting:FindFirstChild("CryoBloom") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "CryoBloom"
		bloom.Intensity = 0.4
		bloom.Size = 32
		bloom.Threshold = 1.1
		bloom.Parent = Lighting
	end
	if not Lighting:FindFirstChild("CryoSunRays") then
		local rays = Instance.new("SunRaysEffect")
		rays.Name = "CryoSunRays"
		rays.Intensity = 0.06
		rays.Spread = 0.6
		rays.Parent = Lighting
	end
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.25
end

-- Snowy mountain ring + snowfield outside the arena walls, so the skybox
-- horizon meets real geometry (FY_ICEWORLD concept). Deterministic layout.
local function buildTerrain()
	local terrain = workspace.Terrain
	local rng = Random.new(20260718)

	-- Snowfield apron in four bands AROUND the arena footprint. A single block
	-- over the whole area would sit coplanar with the arena floor (top y=0) and
	-- z-fight through it, so the interior |x|,|z| <= HALF stays clear.
	local HALF = 64
	local REACH = 420
	local band = REACH - HALF
	local mid = HALF + band / 2
	local span = REACH * 2
	terrain:FillBlock(CFrame.new(0, -6, -mid), Vector3.new(span, 12, band), Enum.Material.Snow)
	terrain:FillBlock(CFrame.new(0, -6, mid), Vector3.new(span, 12, band), Enum.Material.Snow)
	terrain:FillBlock(CFrame.new(-mid, -6, 0), Vector3.new(band, 12, HALF * 2), Enum.Material.Snow)
	terrain:FillBlock(CFrame.new(mid, -6, 0), Vector3.new(band, 12, HALF * 2), Enum.Material.Snow)

	-- Mountain ring: overlapping rock cones capped with snow.
	for index = 1, 26 do
		local angle = (index / 26) * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local radius = rng:NextNumber(240, 360)
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local height = rng:NextNumber(70, 200)
		local width = rng:NextNumber(60, 130)
		terrain:FillBall(Vector3.new(x, height * 0.25, z), width, Enum.Material.Rock)
		terrain:FillBall(Vector3.new(x, height * 0.55, z), width * 0.7, Enum.Material.Rock)
		terrain:FillBall(Vector3.new(x, height * 0.85, z), width * 0.45, Enum.Material.Glacier)
		terrain:FillBall(Vector3.new(x, height, z), width * 0.3, Enum.Material.Snow)
	end
end

-- Fabric banners on the fortress walls (concept accent): team-blue on the
-- Alpha half, red on the Bravo half.
local ALPHA_BANNER = Color3.fromRGB(48, 96, 200)
local BRAVO_BANNER = Color3.fromRGB(168, 34, 34)

local function buildBanners(map: Model)
	local function banner(x: number, z: number, yawDegrees: number, color: Color3)
		local part = Instance.new("Part")
		part.Name = "Banner"
		part.Size = Vector3.new(4.2, 13, 0.3)
		part.CFrame = CFrame.new(x, 22, z)
			* CFrame.Angles(0, math.rad(yawDegrees), 0)
			* CFrame.Angles(math.rad(2.5), 0, 0)
		part.Color = color
		part.Material = Enum.Material.Fabric
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = true
		part.Parent = map
	end
	for _, x in { -40, -20, 20, 40 } do
		banner(x, -62.4, 0, ALPHA_BANNER)
		banner(x, 62.4, 180, BRAVO_BANNER)
	end
	for _, z in { -40, 40 } do
		banner(-63.4, z, 90, if z < 0 then ALPHA_BANNER else BRAVO_BANNER)
		banner(63.4, z, 270, if z < 0 then ALPHA_BANNER else BRAVO_BANNER)
	end
end

-- Warm interior accents at the wall pillars to break the cyan monotone
-- (the concept's orange glow pockets).
local function buildWarmAccents(map: Model)
	local function accent(x: number, z: number)
		local part = Instance.new("Part")
		part.Name = "WarmAccent"
		part.Size = Vector3.new(0.6, 2.4, 0.25)
		part.CFrame = CFrame.new(x, 7.5, z)
		part.Color = Color3.fromRGB(255, 150, 70)
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = map
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 160, 84)
		light.Brightness = 1.6
		light.Range = 22
		light.Parent = part
	end
	for _, x in { -60, 60 } do
		for _, z in { -30, 30 } do
			accent(x + (x < 0 and 1.2 or -1.2), z)
		end
	end
	for _, z in { -62, 62 } do
		for _, x in { -52, 52 } do
			accent(x, z + (z < 0 and 1.2 or -1.2))
		end
	end
end

-- Dresses the built graybox. Positions are a symmetric first pass (mirrored
-- across X=0 / Z=0 like the arena) and are meant to be tuned in Studio.
function CryoFoundryDressing.dress(map: Model)
	applyAtmosphere()
	buildTerrain()
	buildBanners(map)
	buildWarmAccents(map)

	-- Centerpiece: reactor core suspended over the sunken center ring. Grounding
	-- it at the origin buried the HeavyAmmoSpawn marker (and the middle of the
	-- overtime zone) inside its collision, so it hangs at base y=26 — above every
	-- walkable layer (high is 16) and above bridge-to-pickup sightlines — keeping
	-- the center open as the blockout requires while staying the symmetric
	-- centerpiece.
	place(map, "ReactorCore", 0, 0, 0, 26)

	-- Coolant tanks at the four corners of the center ring, facing inward.
	-- At |x|=|z|=20 they clear the LaneWall segments at |x|=24 (the earlier
	-- |22| placement clipped the tank bounds into the wall corners).
	place(map, "CoolantTank", 20, 20, 225)
	place(map, "CoolantTank", -20, 20, 135)
	place(map, "CoolantTank", 20, -20, 315)
	place(map, "CoolantTank", -20, -20, 45)

	-- Control consoles flanking the center, on the East/West axis, facing in.
	place(map, "ControlConsole", 30, 0, 90)
	place(map, "ControlConsole", -30, 0, 270)

	-- Pipe manifolds against the East/West perimeter walls (Z-mirrored).
	place(map, "PipeManifold", 58, 40, 90)
	place(map, "PipeManifold", 58, -40, 90)
	place(map, "PipeManifold", -58, 40, 270)
	place(map, "PipeManifold", -58, -40, 270)
end

return CryoFoundryDressing
