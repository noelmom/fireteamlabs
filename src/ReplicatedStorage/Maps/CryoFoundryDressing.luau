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
			light.Brightness = if name == "ReactorCore" then 6 else 2.5
			-- The reactor hangs ~26 studs up, so its light needs the engine max
			-- range for the cyan spill to still reach the pit floor below it.
			light.Range = if name == "ReactorCore" then 60 else 16
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

-- Cryo mood: cold fog, blue-tinted atmosphere, subtle color grade.
local function applyAtmosphere()
	Lighting.ClockTime = 15
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 84, 100)
	Lighting.Ambient = Color3.fromRGB(50, 60, 74)
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
	grade.TintColor = Color3.fromRGB(206, 224, 240)
	grade.Saturation = -0.08
	grade.Contrast = 0.06
	grade.Brightness = 0
end

-- Dresses the built graybox. Positions are a symmetric first pass (mirrored
-- across X=0 / Z=0 like the arena) and are meant to be tuned in Studio.
function CryoFoundryDressing.dress(map: Model)
	applyAtmosphere()

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
