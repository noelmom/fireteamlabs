--!strict
-- TEMPORARY match-state readout (issue #2). Shows phase, score, and a live
-- countdown at top-center so the round loop is visible in playtest. The real
-- HUD replaces this in issue #12.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

type MatchState = {
	Phase: string,
	RoundNumber: number,
	RoundPhase: string,
	Scores: { Alpha: number, Bravo: number },
	PhaseEndTime: number?,
	RoundResult: string?,
	MatchWinner: string?,
	WinTarget: number,
	TeamSize: number,
}

local MatchDebugController = {
	Name = "MatchDebugController",
}

local latest: MatchState? = nil
local scoreLabel: TextLabel
local statusLabel: TextLabel

local function buildGui()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchDebugHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local container = Instance.new("Frame")
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0, 8)
	container.Size = UDim2.fromOffset(360, 52)
	container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	container.BackgroundTransparency = 0.4
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container

	scoreLabel = Instance.new("TextLabel")
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Size = UDim2.new(1, 0, 0, 30)
	scoreLabel.Position = UDim2.fromOffset(0, 2)
	scoreLabel.Font = Enum.Font.GothamBold
	scoreLabel.TextSize = 22
	scoreLabel.TextColor3 = Color3.new(1, 1, 1)
	scoreLabel.Text = "Waiting for players…"
	scoreLabel.Parent = container

	statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Size = UDim2.new(1, 0, 0, 18)
	statusLabel.Position = UDim2.fromOffset(0, 32)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 13
	statusLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
	statusLabel.Text = ""
	statusLabel.Parent = container

	gui.Parent = playerGui
end

local function phaseLabel(state: MatchState): string
	if state.Phase == "WaitingForPlayers" then
		return "WAITING FOR PLAYERS"
	elseif state.Phase == "PostMatch" then
		local winner = state.MatchWinner or "?"
		return `MATCH OVER — {string.upper(winner)} WINS`
	end
	if state.RoundPhase == "PreRound" then
		return "GET READY"
	elseif state.RoundPhase == "Active" then
		return "ROUND LIVE"
	elseif state.RoundPhase == "Overtime" then
		return "OVERTIME"
	elseif state.RoundPhase == "PostRound" then
		local r = state.RoundResult
		if r == "Draw" then
			return "ROUND DRAW"
		elseif r then
			return `ROUND TO {string.upper(r)}`
		end
		return "ROUND OVER"
	end
	return state.RoundPhase
end

local function render()
	local state = latest
	if not state then
		return
	end

	if state.Phase == "WaitingForPlayers" then
		scoreLabel.Text = "Waiting for players…"
	else
		local mode = `{state.TeamSize}v{state.TeamSize}`
		scoreLabel.Text =
			`ALPHA  {state.Scores.Alpha}  —  {state.Scores.Bravo}  BRAVO   ({mode}, first to {state.WinTarget})`
	end

	local status = phaseLabel(state)
	if state.PhaseEndTime and state.Phase == "InProgress" then
		local remaining = math.max(0, state.PhaseEndTime - workspace:GetServerTimeNow())
		status ..= `   ·   {string.format("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))}`
	end
	statusLabel.Text = status
end

function MatchDebugController.Start(_self: any)
	buildGui()

	local matchStateChanged = RemoteUtil.getEvent(RemoteNames.MatchStateChanged)
	matchStateChanged.OnClientEvent:Connect(function(state: MatchState)
		latest = state
		render()
	end)

	-- Re-render every frame so the countdown ticks smoothly.
	RunService.RenderStepped:Connect(render)
end

return MatchDebugController
