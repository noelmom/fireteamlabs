--!strict
-- Builds the active map and places characters at team spawns (issue #11).
-- Team *membership* is owned by TeamService (#3); MapService decides *where*
-- each team spawns and supports per-round side rotation (#2). MatchService
-- decides *when* players spawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CryoFoundry = require(ReplicatedStorage.Maps.CryoFoundry)
local TeamService = require(ServerScriptService.Services.TeamService)

type TeamId = "Alpha" | "Bravo"

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
