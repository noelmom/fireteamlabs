--!strict
-- Core in-game HUD (issue #12): separated shield/health bars, ammo, crosshair
-- with hitmarker, and the match banner (score, timer, phase, overtime capture).
-- Driven entirely by the PlayerStateChanged, WeaponStateChanged, CombatFeedback,
-- and MatchStateChanged remotes (MASTERPLAN.md section 9).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local HudController = {
	Name = "HudController",
}

-- Theme (sci-fi facility: dark translucent panels, cyan accents).
local PANEL_BG = Color3.fromRGB(10, 14, 20)
local PANEL_TRANSPARENCY = 0.35
local TRACK_COLOR = Color3.fromRGB(38, 46, 56)
local SHIELD_COLOR = Color3.fromRGB(90, 190, 255)
local HEALTH_COLOR = Color3.fromRGB(120, 226, 150)
local LOW_HEALTH_COLOR = Color3.fromRGB(255, 92, 92)
local TEXT_COLOR = Color3.fromRGB(236, 241, 246)
local MUTED_COLOR = Color3.fromRGB(150, 160, 172)
local ALPHA_COLOR = Color3.fromRGB(96, 156, 255)
local BRAVO_COLOR = Color3.fromRGB(255, 122, 92)

local BAR_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LOW_HEALTH_FRACTION = 0.3

type PlayerState = { Shield: number, Health: number, MaxShield: number, MaxHealth: number, Alive: boolean }
type WeaponState = { WeaponId: string, Magazine: number, Reserve: number, Reloading: boolean }
type Feedback = { Hit: boolean, Precision: boolean?, Eliminated: boolean? }
type MatchState = {
	Phase: string,
	RoundPhase: string,
	Scores: { Alpha: number, Bravo: number },
	PhaseEndTime: number?,
	RoundResult: string?,
	MatchWinner: string?,
	WinTarget: number,
	TeamSize: number,
	CaptureTeam: string?,
	CaptureProgress: number,
}

-- Element references, assigned during build.
local shieldFill: Frame
local healthFill: Frame
local shieldValue: TextLabel
local healthValue: TextLabel
local ammoMag: TextLabel
local ammoReserve: TextLabel
local weaponName: TextLabel
local hitmarker: TextLabel
local scoreLabel: TextLabel
local phaseLabel: TextLabel
local captureBar: Frame
local captureFill: Frame

local latestMatch: MatchState? = nil

local function new(className: string, props: { [string]: any }): any
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(inst :: any)[key] = value
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius: number, parent: Instance)
	new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

-- Shield above health, each its own colour + label, so the two are never
-- confused (MASTERPLAN.md section 9).
local function buildDurability(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -24),
		Size = UDim2.fromOffset(300, 74),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = panel,
	})

	local function bar(yOffset: number, name: string, color: Color3): (Frame, TextLabel)
		local row = new("Frame", {
			Position = UDim2.fromOffset(0, yOffset),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Parent = panel,
		})
		new("TextLabel", {
			Size = UDim2.fromOffset(52, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = name,
			TextSize = 12,
			TextColor3 = MUTED_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local track = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, 0),
			Size = UDim2.new(1, -104, 0, 12),
			BackgroundColor3 = TRACK_COLOR,
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(6, track)
		local fill = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = track,
		})
		corner(6, fill)
		local value = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "100",
			TextSize = 15,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		return fill, value
	end

	shieldFill, shieldValue = bar(0, "SHIELD", SHIELD_COLOR)
	healthFill, healthValue = bar(30, "HEALTH", HEALTH_COLOR)
end

local function buildAmmo(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(190, 74),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)

	weaponName = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(160, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 12,
		TextColor3 = MUTED_COLOR,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	ammoMag = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -70, 1, -10),
		Size = UDim2.fromOffset(90, 44),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "0",
		TextSize = 40,
		TextColor3 = TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	ammoReserve = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.fromOffset(60, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "/ 0",
		TextSize = 18,
		TextColor3 = MUTED_COLOR,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
end

local function buildReticle(gui: Instance)
	local size = 3
	local function tick(props: { [string]: any })
		props.BackgroundColor3 = TEXT_COLOR
		props.BorderSizePixel = 0
		props.AnchorPoint = Vector2.new(0.5, 0.5)
		props.Parent = gui
		new("Frame", props)
	end
	-- Four ticks around a center gap.
	tick({ Position = UDim2.new(0.5, 0, 0.5, -10), Size = UDim2.fromOffset(2, 8) })
	tick({ Position = UDim2.new(0.5, 0, 0.5, 10), Size = UDim2.fromOffset(2, 8) })
	tick({ Position = UDim2.new(0.5, -10, 0.5, 0), Size = UDim2.fromOffset(8, 2) })
	tick({ Position = UDim2.new(0.5, 10, 0.5, 0), Size = UDim2.fromOffset(8, 2) })
	tick({ Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size) })

	hitmarker = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "✕",
		TextSize = 26,
		TextColor3 = TEXT_COLOR,
		TextTransparency = 1,
		Parent = gui,
	})
end

local function buildBanner(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(420, 62),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)

	scoreLabel = new("TextLabel", {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Waiting for players…",
		TextSize = 20,
		TextColor3 = TEXT_COLOR,
		Parent = panel,
	})
	phaseLabel = new("TextLabel", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 13,
		TextColor3 = MUTED_COLOR,
		Parent = panel,
	})

	captureBar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.fromOffset(280, 5),
		BackgroundColor3 = TRACK_COLOR,
		BorderSizePixel = 0,
		Visible = false,
		Parent = panel,
	})
	corner(3, captureBar)
	captureFill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = SHIELD_COLOR,
		BorderSizePixel = 0,
		Parent = captureBar,
	})
	corner(3, captureFill)
end

local function updateDurability(state: PlayerState)
	local shieldFraction = if state.MaxShield > 0 then state.Shield / state.MaxShield else 0
	local healthFraction = if state.MaxHealth > 0 then state.Health / state.MaxHealth else 0

	TweenService:Create(shieldFill, BAR_TWEEN, { Size = UDim2.fromScale(shieldFraction, 1) }):Play()
	TweenService:Create(healthFill, BAR_TWEEN, { Size = UDim2.fromScale(healthFraction, 1) }):Play()
	shieldValue.Text = tostring(math.ceil(state.Shield))
	healthValue.Text = tostring(math.ceil(state.Health))

	healthFill.BackgroundColor3 = if healthFraction <= LOW_HEALTH_FRACTION then LOW_HEALTH_COLOR else HEALTH_COLOR
	healthValue.TextColor3 = if healthFraction <= LOW_HEALTH_FRACTION then LOW_HEALTH_COLOR else TEXT_COLOR
end

local function updateAmmo(state: WeaponState)
	weaponName.Text = string.upper(state.WeaponId)
	if state.Magazine < 0 then
		-- Melee (unlimited): no magazine/reserve.
		ammoMag.Text = "∞"
		ammoReserve.Text = ""
	elseif state.Reloading then
		ammoMag.Text = "···"
		ammoReserve.Text = "RELOAD"
	else
		ammoMag.Text = tostring(state.Magazine)
		ammoReserve.Text = `/ {state.Reserve}`
	end
end

local function flashHitmarker(feedback: Feedback)
	if feedback.Eliminated then
		hitmarker.TextColor3 = Color3.fromRGB(255, 92, 92)
	elseif feedback.Precision then
		hitmarker.TextColor3 = Color3.fromRGB(255, 214, 92)
	else
		hitmarker.TextColor3 = TEXT_COLOR
	end
	hitmarker.TextTransparency = 0
	hitmarker.TextSize = if feedback.Eliminated then 34 else 26
	TweenService:Create(hitmarker, TweenInfo.new(0.22), { TextTransparency = 1 }):Play()
end

local function teamColor(team: string?): Color3
	if team == "Alpha" then
		return ALPHA_COLOR
	elseif team == "Bravo" then
		return BRAVO_COLOR
	end
	return TEXT_COLOR
end

local function phaseText(state: MatchState): string
	if state.Phase == "WaitingForPlayers" then
		return "WAITING FOR PLAYERS"
	elseif state.Phase == "PostMatch" then
		return `MATCH OVER — {string.upper(state.MatchWinner or "?")} WINS`
	end

	local phase = state.RoundPhase
	if phase == "PreRound" then
		return "GET READY"
	elseif phase == "Active" then
		return "ROUND LIVE"
	elseif phase == "Overtime" then
		if state.CaptureTeam then
			return `OVERTIME — {string.upper(state.CaptureTeam)} CAPTURING {math.floor(state.CaptureProgress * 100)}%`
		end
		return "OVERTIME — CONTEST THE ZONE"
	elseif phase == "PostRound" then
		local result = state.RoundResult
		if result == "Draw" then
			return "ROUND DRAW"
		elseif result then
			return `ROUND TO {string.upper(result)}`
		end
	end
	return ""
end

local function renderMatch()
	local state = latestMatch
	if not state then
		return
	end

	if state.Phase == "WaitingForPlayers" then
		scoreLabel.Text = "Waiting for players…"
	else
		scoreLabel.Text = `ALPHA  {state.Scores.Alpha}   —   {state.Scores.Bravo}  BRAVO`
	end

	local text = phaseText(state)
	if state.PhaseEndTime and state.Phase == "InProgress" then
		local remaining = math.max(0, state.PhaseEndTime - workspace:GetServerTimeNow())
		text ..= `   ·   {string.format("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))}`
	end
	if state.Phase ~= "WaitingForPlayers" and state.TeamSize > 0 then
		text ..= `   ·   {state.TeamSize}v{state.TeamSize}`
	end
	phaseLabel.Text = text

	local inOvertime = state.RoundPhase == "Overtime" and state.Phase == "InProgress"
	captureBar.Visible = inOvertime
	if inOvertime then
		captureFill.BackgroundColor3 = teamColor(state.CaptureTeam)
		TweenService:Create(captureFill, BAR_TWEEN, { Size = UDim2.fromScale(state.CaptureProgress, 1) }):Play()
	end
end

function HudController.Start(_self: any)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = new("ScreenGui", {
		Name = "FireteamHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	buildReticle(gui)
	buildDurability(gui)
	buildAmmo(gui)
	buildBanner(gui)

	local playerStateChanged = RemoteUtil.getEvent(RemoteNames.PlayerStateChanged)
	local weaponStateChanged = RemoteUtil.getEvent(RemoteNames.WeaponStateChanged)
	local combatFeedback = RemoteUtil.getEvent(RemoteNames.CombatFeedback)
	local matchStateChanged = RemoteUtil.getEvent(RemoteNames.MatchStateChanged)

	playerStateChanged.OnClientEvent:Connect(function(state: PlayerState)
		updateDurability(state)
	end)
	weaponStateChanged.OnClientEvent:Connect(function(state: WeaponState)
		updateAmmo(state)
	end)
	combatFeedback.OnClientEvent:Connect(function(feedback: Feedback)
		if feedback.Hit then
			flashHitmarker(feedback)
		end
	end)
	matchStateChanged.OnClientEvent:Connect(function(state: MatchState)
		latestMatch = state
		renderMatch()
	end)

	-- Keep the round timer ticking between state updates.
	RunService.RenderStepped:Connect(renderMatch)
end

return HudController
