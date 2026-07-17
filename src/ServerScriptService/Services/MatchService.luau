--!strict
-- Owns the match lifecycle: team-based spawning, round phases, scoring,
-- overtime, and match completion (MASTERPLAN.md section 8; Vertical Slice
-- Amendment). Vertical-slice scope: casual play, first team to 7 round wins.
--
-- This service is the single owner of character loading. CharacterAutoLoads
-- is disabled so that "no respawns during an active round" actually holds:
-- players spawn together at each round start and eliminated players stay down
-- until the next round. Between matches, players free-roam for testing.
--
-- Round decisions (who won, match winner, side rotation) are pure functions in
-- Shared/Utility/MatchLogic; everything here is timing, spawning, and state.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MatchLogic = require(ReplicatedStorage.Shared.Utility.MatchLogic)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local MapService = require(ServerScriptService.Services.MapService)
local PlayerStateService = require(ServerScriptService.Services.PlayerStateService)

local Match = GameConfig.Match

type TeamId = MatchLogic.TeamId
type RoundResult = MatchLogic.RoundResult

type State = {
	MatchId: string,
	Phase: string, -- MatchPhase: WaitingForPlayers | InProgress | PostMatch
	RoundNumber: number,
	RoundPhase: string, -- RoundPhase: PreRound | Active | Overtime | PostRound
	Scores: { Alpha: number, Bravo: number },
	PhaseEndTime: number?, -- workspace:GetServerTimeNow() at which a timed phase ends
	RoundResult: RoundResult?,
	MatchWinner: TeamId?,
	WinTarget: number,
}

local MatchService = {
	Name = "MatchService",
}

local state: State = {
	MatchId = "",
	Phase = "WaitingForPlayers",
	RoundNumber = 0,
	RoundPhase = "PreRound",
	Scores = { Alpha = 0, Bravo = 0 },
	PhaseEndTime = nil,
	RoundResult = nil,
	MatchWinner = nil,
	WinTarget = Match.RoundWinTarget,
}

local matchGeneration = 0
local roster: { Player } = {}
local matchStateChanged: RemoteEvent

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function replicate()
	-- Keep the authoritative combat gate in lockstep with what clients see, so
	-- damage is impossible before a round goes live (issue #28).
	PlayerStateService:SetCombatEnabled(MatchLogic.isCombatLive(state.Phase, state.RoundPhase))

	matchStateChanged:FireAllClients({
		MatchId = state.MatchId,
		Phase = state.Phase,
		RoundNumber = state.RoundNumber,
		RoundPhase = state.RoundPhase,
		Scores = { Alpha = state.Scores.Alpha, Bravo = state.Scores.Bravo },
		PhaseEndTime = state.PhaseEndTime,
		RoundResult = state.RoundResult,
		MatchWinner = state.MatchWinner,
		WinTarget = state.WinTarget,
	})
end

function MatchService.GetState(_self: any): State
	return state
end

-- Interruptible wait: returns false if the match generation changed (aborted).
local function waitPhase(seconds: number, generation: number): boolean
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if matchGeneration ~= generation then
			return false
		end
		task.wait()
	end
	return matchGeneration == generation
end

local function connectedTeamCount(team: TeamId): number
	local count = 0
	for _, player in Players:GetPlayers() do
		if MapService:GetTeam(player) == team then
			count += 1
		end
	end
	return count
end

local function canStartMatch(): boolean
	local min = Match.MinPlayersPerTeamToStart
	return connectedTeamCount("Alpha") >= min and connectedTeamCount("Bravo") >= min
end

local function rosterAliveCount(team: TeamId): number
	local count = 0
	for _, player in roster do
		if
			player:IsDescendantOf(Players)
			and MapService:GetTeam(player) == team
			and PlayerStateService:IsAlive(player)
		then
			count += 1
		end
	end
	return count
end

local function rosterConnectedCount(team: TeamId): number
	local count = 0
	for _, player in roster do
		if player:IsDescendantOf(Players) and MapService:GetTeam(player) == team then
			count += 1
		end
	end
	return count
end

local function loadAll(players: { Player })
	for _, player in players do
		if player:IsDescendantOf(Players) then
			player:LoadCharacter()
		end
	end
end

-- Waits until every rostered, connected player has a living character, or the
-- ready timeout elapses. Prevents Active from reading a half-spawned roster as
-- an instant elimination.
local function waitForReady(generation: number)
	local deadline = os.clock() + Match.RoundReadyTimeoutSeconds
	while os.clock() < deadline do
		if matchGeneration ~= generation then
			return
		end
		local ready = true
		for _, player in roster do
			if player:IsDescendantOf(Players) and not PlayerStateService:IsAlive(player) then
				ready = false
				break
			end
		end
		if ready then
			return
		end
		task.wait()
	end
end

local function runActivePhase(generation: number): RoundResult
	state.RoundPhase = "Active"
	state.PhaseEndTime = serverNow() + Match.RoundTimerSeconds
	replicate()

	local deadline = os.clock() + Match.RoundTimerSeconds
	while os.clock() < deadline do
		if matchGeneration ~= generation then
			return "Draw"
		end
		local result = MatchLogic.resolveElimination(rosterAliveCount("Alpha"), rosterAliveCount("Bravo"))
		if result then
			return result
		end
		task.wait()
	end

	-- Timer expired. If someone is already down it's decided; otherwise both
	-- teams survived and we go to overtime.
	local expiredResult = MatchLogic.resolveElimination(rosterAliveCount("Alpha"), rosterAliveCount("Bravo"))
	if expiredResult then
		return expiredResult
	end

	state.RoundPhase = "Overtime"
	state.PhaseEndTime = serverNow() + Match.Overtime.CaptureSeconds
	replicate()

	local otDeadline = os.clock() + Match.Overtime.CaptureSeconds
	while os.clock() < otDeadline do
		if matchGeneration ~= generation then
			return "Draw"
		end
		local result = MatchLogic.resolveElimination(rosterAliveCount("Alpha"), rosterAliveCount("Bravo"))
		if result then
			return result
		end
		task.wait()
	end

	-- TODO(#4): contested capture zone decides overtime. Until then it draws.
	return "Draw"
end

local function runRound(generation: number): RoundResult?
	state.RoundNumber += 1

	-- Side rotation for this round (MASTERPLAN.md section 8).
	MapService:SetTeamSides(
		MatchLogic.sideForTeam("Alpha", state.RoundNumber, Match.TeamSideRotation),
		MatchLogic.sideForTeam("Bravo", state.RoundNumber, Match.TeamSideRotation)
	)

	-- PreRound: spawn the whole roster together, then count down.
	state.RoundPhase = "PreRound"
	state.RoundResult = nil
	state.PhaseEndTime = nil
	replicate()

	loadAll(roster)
	waitForReady(generation)
	if matchGeneration ~= generation then
		return nil
	end

	state.PhaseEndTime = serverNow() + Match.PreRoundCountdownSeconds
	replicate()
	if not waitPhase(Match.PreRoundCountdownSeconds, generation) then
		return nil
	end

	local result = runActivePhase(generation)
	if matchGeneration ~= generation then
		return nil
	end

	-- Apply the single round result exactly once (no duplicate scoring: one
	-- coroutine, one result per round).
	state.Scores = MatchLogic.awardRound(state.Scores, result)
	state.RoundResult = result

	state.RoundPhase = "PostRound"
	state.PhaseEndTime = serverNow() + Match.PostRoundSeconds
	replicate()
	waitPhase(Match.PostRoundSeconds, generation)

	return result
end

local function runMatch()
	matchGeneration += 1
	local generation = matchGeneration

	roster = {}
	for _, player in Players:GetPlayers() do
		MapService:EnsureTeam(player)
		table.insert(roster, player)
	end

	state.MatchId = HttpService:GenerateGUID(false)
	state.Phase = "InProgress"
	state.Scores = { Alpha = 0, Bravo = 0 }
	state.RoundNumber = 0
	state.MatchWinner = nil
	state.RoundResult = nil
	replicate()

	while matchGeneration == generation do
		-- A team with no connected players can't contest a round; abort.
		if rosterConnectedCount("Alpha") == 0 or rosterConnectedCount("Bravo") == 0 then
			break
		end

		runRound(generation)
		if matchGeneration ~= generation then
			break
		end

		local winner = MatchLogic.matchWinner(state.Scores, state.WinTarget)
		if winner then
			state.MatchWinner = winner
			break
		end
	end

	if matchGeneration == generation and state.MatchWinner then
		state.Phase = "PostMatch"
		state.RoundPhase = "PostRound"
		state.PhaseEndTime = serverNow() + Match.PostRoundSeconds * 2
		replicate()
		waitPhase(Match.PostRoundSeconds * 2, generation)
	end
end

local function enterWaitingForPlayers()
	state.Phase = "WaitingForPlayers"
	state.RoundNumber = 0
	state.RoundPhase = "PreRound"
	state.Scores = { Alpha = 0, Bravo = 0 }
	state.RoundResult = nil
	state.MatchWinner = nil
	state.PhaseEndTime = nil
	replicate()

	-- Clean slate free-roam so combat is testable before a match forms.
	loadAll(Players:GetPlayers())
end

function MatchService.Init(_self: any)
	-- This service is the sole character loader (see file header).
	Players.CharacterAutoLoads = false
	matchStateChanged = RemoteUtil.getEvent(RemoteNames.MatchStateChanged)
end

function MatchService.Start(_self: any)
	-- Free-roam respawn while waiting; spawn joiners.
	local function watchCharacter(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			task.delay(3, function()
				if state.Phase == "WaitingForPlayers" and player:IsDescendantOf(Players) then
					player:LoadCharacter()
				end
			end)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			watchCharacter(player, character)
		end)
		if state.Phase == "WaitingForPlayers" then
			player:LoadCharacter()
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if state.Phase ~= "InProgress" then
			return
		end
		local team = MapService:GetTeam(player)
		if not team then
			return
		end
		-- If this drop empties a team, the match can't continue.
		local remaining = 0
		for _, other in roster do
			if other ~= player and other:IsDescendantOf(Players) and MapService:GetTeam(other) == team then
				remaining += 1
			end
		end
		if remaining == 0 then
			matchGeneration += 1 -- abort back to WaitingForPlayers
		end
	end)

	-- Main control loop: wait for enough players, run a match, repeat.
	task.spawn(function()
		while true do
			enterWaitingForPlayers()
			while not canStartMatch() do
				-- Spawn any player still without a character (joiners).
				for _, player in Players:GetPlayers() do
					if not player.Character then
						player:LoadCharacter()
					end
				end
				task.wait(0.5)
			end
			runMatch()
		end
	end)
end

return MatchService
