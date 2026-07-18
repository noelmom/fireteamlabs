--!strict
-- HUD v2 (issue #57): layout and styling follow the UI-Game-Feel target
-- concepts in earlyartwork/ui-concepts/. Elements:
--   * Top center   — scoreboard: team blocks, scores, round number, timer,
--                    win-target line, per-round pips, overtime capture bar.
--   * Top right    — ping/FPS readout and the kill feed (EliminationBroadcast).
--   * Bottom left  — player status card: class portrait monogram, class name,
--                    shield/health bars.
--   * Bottom center— ability bar: class ability diamond (F) with cooldown,
--                    flanked by reserved slots (Q/E · G/T) for future systems.
--   * Bottom right — weapon panel: magazine, reserve, ammo pips, weapon name.
--   * Center       — crosshair, hitmarker, elimination banner.
-- Driven by PlayerStateChanged, WeaponStateChanged, CombatFeedback,
-- MatchStateChanged, AbilityStateChanged, and EliminationBroadcast.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AbilityLogic = require(ReplicatedStorage.Shared.Utility.AbilityLogic)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)

local HudController = {
	Name = "HudController",
}

-- Theme (concept: dark angular panels, team blue vs red, thin light type).
local PANEL_BG = Color3.fromRGB(8, 11, 16)
local PANEL_TRANSPARENCY = 0.25
local TRACK_COLOR = Color3.fromRGB(34, 41, 51)
local SHIELD_COLOR = Color3.fromRGB(74, 158, 255)
local HEALTH_COLOR = Color3.fromRGB(236, 241, 246)
local LOW_HEALTH_COLOR = Color3.fromRGB(255, 82, 82)
local TEXT_COLOR = Color3.fromRGB(236, 241, 246)
local MUTED_COLOR = Color3.fromRGB(142, 152, 164)
local ALPHA_COLOR = Color3.fromRGB(52, 118, 240)
local BRAVO_COLOR = Color3.fromRGB(214, 44, 44)
local READY_COLOR = Color3.fromRGB(120, 226, 150)
local ELIM_COLOR = Color3.fromRGB(255, 64, 64)

local BAR_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LOW_HEALTH_FRACTION = 0.3
local FEED_LIFETIME = 6
local FEED_MAX_ROWS = 4

type PlayerState = { Shield: number, Health: number, MaxShield: number, MaxHealth: number, Alive: boolean }
type WeaponState = { WeaponId: string, Magazine: number, Reserve: number, Reloading: boolean }
type Feedback = { Hit: boolean, Precision: boolean?, Eliminated: boolean? }
type AbilityState = { ClassId: string, AbilityName: string, CooldownEnd: number }
type Elimination = { Killer: string?, KillerTeam: string?, Victim: string, VictimTeam: string?, Category: string? }
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
	CaptureTeam: string?,
	CaptureProgress: number,
}

-- Element references, assigned during build.
local scoreAlphaBlock: Frame
local scoreBravoBlock: Frame
local scoreAlphaValue: TextLabel
local scoreBravoValue: TextLabel
local roundLabel: TextLabel
local timerLabel: TextLabel
local subLabel: TextLabel
local pipsRow: Frame
local alphaPips: { Frame } = {}
local bravoPips: { Frame } = {}
local captureBar: Frame
local captureFill: Frame

local netLabel: TextLabel
local feedColumn: Frame

local classMonogram: TextLabel
local classNameLabel: TextLabel
local shieldFill: Frame
local healthFill: Frame
local shieldValue: TextLabel
local healthValue: TextLabel

local abilityDiamond: Frame
local abilityInner: TextLabel
local abilityCooldownLabel: TextLabel

local ammoMag: TextLabel
local ammoReserve: TextLabel
local weaponName: TextLabel
local ammoPips: { Frame } = {}

local hitmarker: TextLabel
local elimBanner: Frame
local elimNameLabel: TextLabel

local latestMatch: MatchState? = nil
local latestAbility: AbilityState? = nil
local lastMagazineMax = 30

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

local function teamColor(team: string?): Color3
	if team == "Alpha" then
		return ALPHA_COLOR
	elseif team == "Bravo" then
		return BRAVO_COLOR
	end
	return TEXT_COLOR
end

-- ---------------------------------------------------------------- scoreboard

local function buildScoreboard(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(460, 64),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)

	local function teamBlock(side: "Alpha" | "Bravo"): (Frame, TextLabel)
		local isAlpha = side == "Alpha"
		local block = new("Frame", {
			AnchorPoint = Vector2.new(isAlpha and 1 or 0, 0),
			Position = isAlpha and UDim2.new(0.5, -74, 0, 6) or UDim2.new(0.5, 74, 0, 6),
			Size = UDim2.fromOffset(84, 40),
			BackgroundColor3 = teamColor(side),
			BorderSizePixel = 0,
			Visible = false,
			Parent = panel,
		})
		corner(6, block)
		-- Team monogram on the outer edge, score on the inner edge.
		new("TextLabel", {
			AnchorPoint = Vector2.new(isAlpha and 0 or 1, 0.5),
			Position = isAlpha and UDim2.new(0, 8, 0.5, 0) or UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(20, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = isAlpha and "▲" or "▼",
			TextSize = 15,
			TextColor3 = TEXT_COLOR,
			TextTransparency = 0.25,
			Parent = block,
		})
		local score = new("TextLabel", {
			AnchorPoint = Vector2.new(isAlpha and 1 or 0, 0.5),
			Position = isAlpha and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(34, 34),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = "0",
			TextSize = 30,
			TextColor3 = TEXT_COLOR,
			Parent = block,
		})
		return block, score
	end

	scoreAlphaBlock, scoreAlphaValue = teamBlock("Alpha")
	scoreBravoBlock, scoreBravoValue = teamBlock("Bravo")

	roundLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(140, 12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 10,
		TextColor3 = MUTED_COLOR,
		Parent = panel,
	})
	timerLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 17),
		Size = UDim2.fromOffset(140, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "",
		TextSize = 21,
		TextColor3 = TEXT_COLOR,
		Parent = panel,
	})
	subLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5),
		Size = UDim2.new(1, -16, 0, 12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "WAITING FOR PLAYERS",
		TextSize = 10,
		TextColor3 = MUTED_COLOR,
		Parent = panel,
	})

	-- Round pips under the panel: win progress toward WinTarget per team.
	pipsRow = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.fromOffset(200, 8),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = panel,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		Parent = pipsRow,
	})

	captureBar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
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

local function rebuildPips(winTarget: number)
	for _, pip in alphaPips do
		pip:Destroy()
	end
	for _, pip in bravoPips do
		pip:Destroy()
	end
	alphaPips = {}
	bravoPips = {}
	-- Alpha pips fill left-to-right, a divider, then Bravo's.
	for index = 1, winTarget do
		local pip = new("Frame", {
			Size = UDim2.fromOffset(14, 5),
			BackgroundColor3 = TRACK_COLOR,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = pipsRow,
		})
		corner(2, pip)
		alphaPips[index] = pip
	end
	new("Frame", {
		Size = UDim2.fromOffset(2, 8),
		BackgroundColor3 = MUTED_COLOR,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		LayoutOrder = 50,
		Parent = pipsRow,
	})
	for index = 1, winTarget do
		local pip = new("Frame", {
			Size = UDim2.fromOffset(14, 5),
			BackgroundColor3 = TRACK_COLOR,
			BorderSizePixel = 0,
			LayoutOrder = 50 + index,
			Parent = pipsRow,
		})
		corner(2, pip)
		bravoPips[index] = pip
	end
end

-- ------------------------------------------------------- ping/fps, kill feed

local function buildNetAndFeed(gui: Instance)
	netLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(160, 14),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 11,
		TextColor3 = MUTED_COLOR,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = gui,
	})

	feedColumn = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 30),
		Size = UDim2.fromOffset(280, 130),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = feedColumn,
	})
end

local feedSerial = 0
local function pushFeedRow(event: Elimination)
	feedSerial += 1
	local row = new("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		LayoutOrder = feedSerial,
		Parent = feedColumn,
	})
	corner(5, row)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = row,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = row,
	})
	local function label(text: string, color: Color3, bold: boolean)
		new("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 24),
			BackgroundTransparency = 1,
			Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
			Text = text,
			TextSize = 12,
			TextColor3 = color,
			Parent = row,
		})
	end
	if event.Killer then
		label(event.Killer, teamColor(event.KillerTeam), true)
		label("⚔", MUTED_COLOR, false)
	else
		label("☠", MUTED_COLOR, false)
	end
	label(event.Victim, teamColor(event.VictimTeam), true)

	-- Trim overflow, then fade this row out after its lifetime.
	local rows = {}
	for _, child in feedColumn:GetChildren() do
		if child:IsA("Frame") then
			table.insert(rows, child)
		end
	end
	table.sort(rows, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for index = 1, #rows - FEED_MAX_ROWS do
		rows[index]:Destroy()
	end
	task.delay(FEED_LIFETIME, function()
		if row.Parent then
			local tween = TweenService:Create(row, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			for _, child in row:GetDescendants() do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
				end
			end
			tween.Completed:Once(function()
				row:Destroy()
			end)
			tween:Play()
		end
	end)
end

-- --------------------------------------------------------- player status card

local function buildPlayerCard(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -24),
		Size = UDim2.fromOffset(320, 84),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)

	local portrait = new("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = TRACK_COLOR,
		BorderSizePixel = 0,
		Parent = panel,
	})
	corner(8, portrait)
	new("UIStroke", {
		Color = SHIELD_COLOR,
		Thickness = 1.5,
		Transparency = 0.35,
		Parent = portrait,
	})
	classMonogram = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "S",
		TextSize = 34,
		TextColor3 = TEXT_COLOR,
		Parent = portrait,
	})

	classNameLabel = new("TextLabel", {
		Position = UDim2.fromOffset(86, 10),
		Size = UDim2.fromOffset(200, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "SPECTER",
		TextSize = 14,
		TextColor3 = TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local function bar(yOffset: number, glyph: string, color: Color3): (Frame, TextLabel)
		local row = new("Frame", {
			Position = UDim2.fromOffset(86, yOffset),
			Size = UDim2.fromOffset(222, 18),
			BackgroundTransparency = 1,
			Parent = panel,
		})
		new("TextLabel", {
			Size = UDim2.fromOffset(16, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = glyph,
			TextSize = 13,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local value = new("TextLabel", {
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.fromOffset(34, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "100",
			TextSize = 13,
			TextColor3 = TEXT_COLOR,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local track = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(160, 9),
			BackgroundColor3 = TRACK_COLOR,
			BorderSizePixel = 0,
			Parent = row,
		})
		corner(4, track)
		local fill = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = track,
		})
		corner(4, fill)
		return fill, value
	end

	shieldFill, shieldValue = bar(32, "⛨", SHIELD_COLOR)
	healthFill, healthValue = bar(56, "＋", HEALTH_COLOR)
end

-- --------------------------------------------------------------- ability bar

local function buildAbilityBar(gui: Instance)
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.fromOffset(360, 84),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- Reserved slots for future equipment (concept: Q/E left, G/T right).
	local function reservedSlot(xOffset: number, key: string)
		local slot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, xOffset, 1, -6),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = PANEL_BG,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Parent = bar,
		})
		corner(7, slot)
		new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -4),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "•",
			TextSize = 16,
			TextColor3 = MUTED_COLOR,
			TextTransparency = 0.5,
			Parent = slot,
		})
		new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.fromOffset(20, 10),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = key,
			TextSize = 9,
			TextColor3 = MUTED_COLOR,
			TextTransparency = 0.35,
			Parent = slot,
		})
	end
	reservedSlot(-130, "Q")
	reservedSlot(-76, "E")
	reservedSlot(76, "G")
	reservedSlot(130, "T")

	-- Class ability diamond, center (concept's large X slot; bind stays F for
	-- now — see the keybind decision flagged in #57).
	abilityDiamond = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(58, 58),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Rotation = 45,
		Parent = bar,
	})
	corner(10, abilityDiamond)
	new("UIStroke", {
		Color = SHIELD_COLOR,
		Thickness = 1.5,
		Transparency = 0.2,
		Parent = abilityDiamond,
	})
	abilityInner = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Rotation = -45,
		Font = Enum.Font.GothamBlack,
		Text = "◈",
		TextSize = 24,
		TextColor3 = READY_COLOR,
		Parent = abilityDiamond,
	})
	abilityCooldownLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Rotation = -45,
		Font = Enum.Font.GothamBlack,
		Text = "",
		TextSize = 18,
		TextColor3 = TEXT_COLOR,
		Parent = abilityDiamond,
	})
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 16),
		Size = UDim2.fromOffset(30, 12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "F",
		TextSize = 11,
		TextColor3 = MUTED_COLOR,
		Parent = bar,
	})
end

-- -------------------------------------------------------------- weapon panel

local function buildWeaponPanel(gui: Instance)
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(280, 84),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = PANEL_TRANSPARENCY,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(8, panel)

	ammoMag = new("TextLabel", {
		Position = UDim2.fromOffset(16, 14),
		Size = UDim2.fromOffset(84, 46),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "0",
		TextSize = 42,
		TextColor3 = TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	ammoReserve = new("TextLabel", {
		Position = UDim2.fromOffset(104, 24),
		Size = UDim2.fromOffset(46, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "0",
		TextSize = 15,
		TextColor3 = MUTED_COLOR,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	-- Ammo pips: five thin bars showing magazine fill.
	local pipsHolder = new("Frame", {
		Position = UDim2.fromOffset(104, 46),
		Size = UDim2.fromOffset(52, 12),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 3),
		Parent = pipsHolder,
	})
	ammoPips = {}
	for index = 1, 5 do
		local pip = new("Frame", {
			Size = UDim2.fromOffset(6, 12),
			BackgroundColor3 = SHIELD_COLOR,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = pipsHolder,
		})
		corner(2, pip)
		ammoPips[index] = pip
	end

	weaponName = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -12),
		Size = UDim2.fromOffset(110, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 12,
		TextColor3 = MUTED_COLOR,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	-- Weapon silhouette placeholder until weapon icons exist.
	new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(110, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "▄▟█▛▬",
		TextSize = 18,
		TextColor3 = MUTED_COLOR,
		TextTransparency = 0.45,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
end

-- -------------------------------------------------- crosshair, elim banner

local function buildReticle(gui: Instance)
	local function tick(props: { [string]: any })
		props.BackgroundColor3 = TEXT_COLOR
		props.BorderSizePixel = 0
		props.AnchorPoint = Vector2.new(0.5, 0.5)
		props.Parent = gui
		new("Frame", props)
	end
	tick({ Position = UDim2.new(0.5, 0, 0.5, -9), Size = UDim2.fromOffset(2, 7) })
	tick({ Position = UDim2.new(0.5, 0, 0.5, 9), Size = UDim2.fromOffset(2, 7) })
	tick({ Position = UDim2.new(0.5, -9, 0.5, 0), Size = UDim2.fromOffset(7, 2) })
	tick({ Position = UDim2.new(0.5, 9, 0.5, 0), Size = UDim2.fromOffset(7, 2) })

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

local function buildElimBanner(gui: Instance)
	elimBanner = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.64),
		Size = UDim2.fromOffset(280, 64),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(40, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "☠",
		TextSize = 20,
		TextColor3 = TEXT_COLOR,
		Parent = elimBanner,
	})
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 24),
		Size = UDim2.fromOffset(280, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "YOU ELIMINATED",
		TextSize = 15,
		TextColor3 = ELIM_COLOR,
		Parent = elimBanner,
	})
	elimNameLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(280, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 14,
		TextColor3 = TEXT_COLOR,
		Parent = elimBanner,
	})
end

local elimBannerToken = 0
local function showElimBanner(victim: string)
	elimBannerToken += 1
	local token = elimBannerToken
	elimNameLabel.Text = victim
	elimBanner.Visible = true
	task.delay(2.2, function()
		if elimBannerToken == token then
			elimBanner.Visible = false
		end
	end)
end

-- ------------------------------------------------------------------ updates

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
		ammoMag.Text = "∞"
		ammoReserve.Text = ""
	elseif state.Reloading then
		ammoMag.Text = "···"
		ammoReserve.Text = "RELOAD"
	else
		ammoMag.Text = tostring(state.Magazine)
		ammoReserve.Text = tostring(state.Reserve)
		lastMagazineMax = math.max(lastMagazineMax, state.Magazine)
	end

	local fraction = if state.Magazine < 0 or lastMagazineMax == 0
		then 1
		else math.clamp(state.Magazine / lastMagazineMax, 0, 1)
	local lit = math.ceil(fraction * #ammoPips)
	for index, pip in ammoPips do
		pip.BackgroundTransparency = if index <= lit then 0 else 0.75
	end
end

local function updateAbility()
	local state = latestAbility
	if not state then
		return
	end
	classMonogram.Text = string.sub(state.ClassId, 1, 1)
	classNameLabel.Text = string.upper(state.ClassId)

	local remaining = AbilityLogic.cooldownRemaining(workspace:GetServerTimeNow(), state.CooldownEnd)
	if remaining > 0 then
		abilityInner.Visible = false
		abilityCooldownLabel.Text = tostring(math.ceil(remaining))
		abilityDiamond.BackgroundTransparency = 0.5
	else
		abilityInner.Visible = true
		abilityCooldownLabel.Text = ""
		abilityDiamond.BackgroundTransparency = 0.15
	end
end

local function flashHitmarker(feedback: Feedback)
	if feedback.Eliminated then
		hitmarker.TextColor3 = ELIM_COLOR
	elseif feedback.Precision then
		hitmarker.TextColor3 = Color3.fromRGB(255, 214, 92)
	else
		hitmarker.TextColor3 = TEXT_COLOR
	end
	hitmarker.TextTransparency = 0
	hitmarker.TextSize = if feedback.Eliminated then 34 else 26
	TweenService:Create(hitmarker, TweenInfo.new(0.22), { TextTransparency = 1 }):Play()
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
		return `ROUND LIVE · FIRST TO {state.WinTarget}`
	elseif phase == "Overtime" then
		if state.CaptureTeam then
			return `OVERTIME — {string.upper(state.CaptureTeam)} CAPTURING`
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

local knownWinTarget = 0
local function renderMatch()
	local state = latestMatch
	if not state then
		return
	end

	local waiting = state.Phase == "WaitingForPlayers"
	scoreAlphaBlock.Visible = not waiting
	scoreBravoBlock.Visible = not waiting
	pipsRow.Visible = not waiting and state.WinTarget > 0
	roundLabel.Text = if waiting or state.RoundNumber == 0 then "" else `ROUND {state.RoundNumber}`

	if not waiting then
		scoreAlphaValue.Text = tostring(state.Scores.Alpha)
		scoreBravoValue.Text = tostring(state.Scores.Bravo)
		if state.WinTarget ~= knownWinTarget and state.WinTarget > 0 then
			knownWinTarget = state.WinTarget
			rebuildPips(state.WinTarget)
		end
		for index, pip in alphaPips do
			pip.BackgroundColor3 = if index <= state.Scores.Alpha then ALPHA_COLOR else TRACK_COLOR
		end
		for index, pip in bravoPips do
			pip.BackgroundColor3 = if index <= state.Scores.Bravo then BRAVO_COLOR else TRACK_COLOR
		end
	end

	if state.PhaseEndTime and state.Phase == "InProgress" then
		local remaining = math.max(0, state.PhaseEndTime - workspace:GetServerTimeNow())
		timerLabel.Text = string.format("%d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
	elseif waiting then
		timerLabel.Text = "—"
	else
		timerLabel.Text = ""
	end

	local sub = phaseText(state)
	if not waiting and state.TeamSize > 0 then
		sub ..= ` · {state.TeamSize}v{state.TeamSize}`
	end
	subLabel.Text = sub

	local inOvertime = state.RoundPhase == "Overtime" and state.Phase == "InProgress"
	captureBar.Visible = inOvertime
	pipsRow.Visible = pipsRow.Visible and not inOvertime
	if inOvertime then
		captureFill.BackgroundColor3 = teamColor(state.CaptureTeam)
		TweenService:Create(captureFill, BAR_TWEEN, { Size = UDim2.fromScale(state.CaptureProgress, 1) }):Play()
	end

	updateAbility()
end

-- ------------------------------------------------------------------- wiring

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
	buildScoreboard(gui)
	buildNetAndFeed(gui)
	buildPlayerCard(gui)
	buildAbilityBar(gui)
	buildWeaponPanel(gui)
	buildElimBanner(gui)

	RemoteUtil.getEvent(RemoteNames.PlayerStateChanged).OnClientEvent:Connect(function(state: PlayerState)
		updateDurability(state)
	end)
	RemoteUtil.getEvent(RemoteNames.WeaponStateChanged).OnClientEvent:Connect(function(state: WeaponState)
		updateAmmo(state)
	end)
	RemoteUtil.getEvent(RemoteNames.CombatFeedback).OnClientEvent:Connect(function(feedback: Feedback)
		if feedback.Hit then
			flashHitmarker(feedback)
		end
	end)
	RemoteUtil.getEvent(RemoteNames.MatchStateChanged).OnClientEvent:Connect(function(state: MatchState)
		latestMatch = state
	end)
	RemoteUtil.getEvent(RemoteNames.AbilityStateChanged).OnClientEvent:Connect(function(state: AbilityState)
		latestAbility = state
	end)
	RemoteUtil.getEvent(RemoteNames.EliminationBroadcast).OnClientEvent:Connect(function(event: Elimination)
		pushFeedRow(event)
		if event.Killer == Players.LocalPlayer.Name and event.Victim ~= Players.LocalPlayer.Name then
			showElimBanner(event.Victim)
		end
	end)

	-- Tick the timer/cooldowns between remote updates; sample FPS/ping ~2 Hz.
	local frames = 0
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt: number)
		renderMatch()
		frames += 1
		elapsed += dt
		if elapsed >= 0.5 then
			local fps = math.floor(frames / elapsed + 0.5)
			local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000 + 0.5)
			netLabel.Text = `{ping}ms | {fps} FPS`
			frames = 0
			elapsed = 0
		end
	end)
end

return HudController
