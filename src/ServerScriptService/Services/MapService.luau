--!strict
-- Builds the active map and places characters at team spawns (issue #11).
-- Team assignment here is a join-order stopgap; real assignment and match
-- flow land with issues #3 and #2 in MatchService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CryoFoundry = require(ReplicatedStorage.Maps.CryoFoundry)

local MapService = {
	Name = "MapService",
}

local map: Model
local teamOf: { [Player]: string } = {}
local assignCounter = 0
local spawnCounter = 0

local function assignTeam(player: Player): string
	-- TODO(#3): replace join-order alternation with real team assignment.
	local team = if assignCounter % 2 == 0 then "Alpha" else "Bravo"
	assignCounter += 1
	teamOf[player] = team
	return team
end

local function placeAtSpawn(player: Player, character: Model)
	local team = teamOf[player] or assignTeam(player)
	local spawns = CryoFoundry.getSpawns(map, team)
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

function MapService.GetTeam(_self: any, player: Player): string?
	return teamOf[player]
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
	if player.Character then
		placeAtSpawn(player, player.Character)
	end
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
