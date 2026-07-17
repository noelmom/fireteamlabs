--!strict
-- Builds the active map, owns team membership, and places characters at team
-- spawns (issue #11). MatchService decides *when* players spawn (round flow,
-- issue #2); MapService decides *where* (which team spawn), and supports
-- per-round side rotation. Join-order team assignment is a stopgap until #3.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CryoFoundry = require(ReplicatedStorage.Maps.CryoFoundry)

type TeamId = "Alpha" | "Bravo"

local MapService = {
	Name = "MapService",
}

local map: Model
local teamOf: { [Player]: TeamId } = {}
local assignCounter = 0
local spawnCounter = 0

-- Maps a logical team to the physical spawn group it uses this round.
-- MatchService updates this each round for side rotation.
local sideOfTeam: { [TeamId]: TeamId } = { Alpha = "Alpha", Bravo = "Bravo" }

local function assignTeam(player: Player): TeamId
	-- TODO(#3): replace join-order alternation with real team assignment.
	local team: TeamId = if assignCounter % 2 == 0 then "Alpha" else "Bravo"
	assignCounter += 1
	teamOf[player] = team
	return team
end

local function placeAtSpawn(player: Player, character: Model)
	local team = teamOf[player] or assignTeam(player)
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

function MapService.GetTeam(_self: any, player: Player): TeamId?
	return teamOf[player]
end

-- Assigns a team if the player has none yet; always returns the current team.
function MapService.EnsureTeam(_self: any, player: Player): TeamId
	return teamOf[player] or assignTeam(player)
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
	assignTeam(player)
	player.CharacterAdded:Connect(function(character)
		placeAtSpawn(player, character)
	end)
end

function MapService.Start(_self: any)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		teamOf[player] = nil
	end)
end

return MapService
