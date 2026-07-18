--!strict
-- Builds the active map and places characters at team spawns (issue #11).
-- Team *membership* is owned by TeamService (#3); MapService decides *where*
-- each team spawns and supports per-round side rotation (#2). MatchService
-- decides *when* players spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CryoFoundry = require(ReplicatedStorage.Maps.CryoFoundry)
local CryoFoundryDressing = require(ReplicatedStorage.Maps.CryoFoundryDressing)
local TeamService = require(ServerScriptService.Services.TeamService)

type TeamId = "Alpha" | "Bravo"

local ZONE_IDLE_COLOR = Color3.fromRGB(90, 180, 255)
local ZONE_NEUTRAL_COLOR = Color3.fromRGB(210, 216, 224)
local ZONE_ALPHA_COLOR = Color3.fromRGB(90, 150, 255)
local ZONE_BRAVO_COLOR = Color3.fromRGB(255, 120, 90)

local MapService = {
	Name = "MapService",
}

local map: Model
local spawnCounter = 0

-- Maps a logical team to the physical spawn group it uses this round.
-- MatchService updates this each round for side rotation.
local sideOfTeam: { [TeamId]: TeamId } = { Alpha = "Alpha", Bravo = "Bravo" }

local function placeAtSpawn(player: Player, character: Model)
	local team = TeamService:EnsureTeam(player)
	local side = sideOfTeam[team]
	local spawns = CryoFoundry.getSpawns(map, side)
	if #spawns == 0 then
		return
	end
	spawnCounter += 1
	local spawn = spawns[(spawnCounter % #spawns) + 1]

	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		character:PivotTo(spawn + Vector3.new(0, 4, 0))
	end
end

function MapService.GetMap(_self: any): Model
	return map
end

-- Sets the physical spawn side each logical team uses (side rotation, #2).
function MapService.SetTeamSides(_self: any, alphaSide: TeamId, bravoSide: TeamId)
	sideOfTeam.Alpha = alphaSide
	sideOfTeam.Bravo = bravoSide
end

-- Center of the overtime capture zone (#4).
function MapService.GetOvertimeCenter(_self: any): Vector3
	local marker = map:FindFirstChild("OvertimeZoneMarker") :: BasePart?
	return if marker then marker.Position else Vector3.zero
end

-- Shows/hides the overtime zone and tints it by the capturing team (#4).
function MapService.SetZoneActive(_self: any, active: boolean, owner: TeamId?)
	local marker = map:FindFirstChild("OvertimeZoneMarker") :: BasePart?
	if not marker then
		return
	end
	if not active then
		marker.Transparency = 0.85
		marker.Color = ZONE_IDLE_COLOR
		return
	end
	marker.Transparency = 0.5
	if owner == "Alpha" then
		marker.Color = ZONE_ALPHA_COLOR
	elseif owner == "Bravo" then
		marker.Color = ZONE_BRAVO_COLOR
	else
		marker.Color = ZONE_NEUTRAL_COLOR
	end
end

function MapService.Init(_self: any)
	map = CryoFoundry.build()
	map.Parent = workspace

	local killVolume = map:FindFirstChild("KillVolume") :: BasePart
	killVolume.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)

	-- Cosmetic art-dressing pass (props + atmosphere). Runs async and is
	-- best-effort so asset loads never block or break the playable graybox.
	task.spawn(function()
		local ok, err = pcall(CryoFoundryDressing.dress, map)
		if not ok then
			warn(`[MapService] dressing pass failed: {err}`)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		placeAtSpawn(player, character)
	end)
end

function MapService.Start(_self: any)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return MapService
