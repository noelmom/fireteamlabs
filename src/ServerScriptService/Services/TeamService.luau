--!strict
-- Owns logical team membership and balanced assignment (issue #3). Joining
-- players go to the smaller team; between matches the roster can be rebalanced
-- so team sizes differ by at most one. Physical spawn sides (side rotation)
-- remain MapService's concern; this service only decides Alpha vs Bravo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamAssignment = require(ReplicatedStorage.Shared.Utility.TeamAssignment)

type TeamId = TeamAssignment.TeamId

local TeamService = {
	Name = "TeamService",
}

local teamOf: { [Player]: TeamId } = {}

local function counts(): (number, number)
	local alpha, bravo = 0, 0
	for _, team in teamOf do
		if team == "Alpha" then
			alpha += 1
		else
			bravo += 1
		end
	end
	return alpha, bravo
end

function TeamService.GetTeam(_self: any, player: Player): TeamId?
	return teamOf[player]
end

-- Assigns a balanced team if the player has none; returns the current team.
function TeamService.EnsureTeam(_self: any, player: Player): TeamId
	local existing = teamOf[player]
	if existing then
		return existing
	end
	local alpha, bravo = counts()
	local team = TeamAssignment.pickTeam(alpha, bravo)
	teamOf[player] = team
	return team
end

function TeamService.CountByTeam(_self: any): (number, number)
	return counts()
end

-- Evens out team sizes to differ by at most one by moving players off the
-- larger team. Only safe to call between matches (it can change a player's
-- team, and therefore their spawn side).
function TeamService.Rebalance(_self: any)
	for _, player in Players:GetPlayers() do
		TeamService:EnsureTeam(player)
	end

	local alpha, bravo = counts()
	while math.abs(alpha - bravo) > 1 do
		local fromTeam: TeamId = if alpha > bravo then "Alpha" else "Bravo"
		local toTeam: TeamId = if alpha > bravo then "Bravo" else "Alpha"
		local moved = false
		for _, player in Players:GetPlayers() do
			if teamOf[player] == fromTeam then
				teamOf[player] = toTeam
				moved = true
				break
			end
		end
		if not moved then
			break
		end
		alpha, bravo = counts()
	end
end

function TeamService.Start(_self: any)
	for _, player in Players:GetPlayers() do
		TeamService:EnsureTeam(player)
	end
	Players.PlayerAdded:Connect(function(player)
		TeamService:EnsureTeam(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		teamOf[player] = nil
	end)
end

return TeamService
