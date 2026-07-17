--!strict
-- Client side of class abilities (issue #10; pre-round picker #38). During prep
-- phases (not combat-live) a card picker lets you choose a class; it hides once
-- the round goes live and your pick locks. F casts the current ability, the
-- indicator shows its cooldown, and the Bulwark lunge is applied here since the
-- client owns its character's physics (the server stays authoritative for
-- damage, cooldown, and class locking).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClassConfig = require(ReplicatedStorage.Shared.Config.ClassConfig)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)
local AbilityLogic = require(ReplicatedStorage.Shared.Utility.AbilityLogic)
local MatchLogic = require(ReplicatedStorage.Shared.Utility.MatchLogic)
local InputController = require(script.Parent.InputController)

local LUNGE_SPEED = 62
local LUNGE_UP = 8
local CLASS_ORDER = { "Specter", "Conduit", "Bulwark" }

local ACCENT = Color3.fromRGB(90, 180, 255)
local CARD_BG = Color3.fromRGB(14, 18, 26)
local CARD_STROKE = Color3.fromRGB(48, 56, 68)
local TEXT = Color3.fromRGB(236, 241, 246)
local MUTED = Color3.fromRGB(150, 160, 172)

local ClassController = {
	Name = "ClassController",
}

local abilityName = "Flechette"
local cooldownEnd = 0
local currentClassId = "Specter"

local indicator: TextLabel
local picker: Frame
local cardStrokes: { [string]: UIStroke } = {}
local cardBackers: { [string]: Frame } = {}

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

local function buildCard(parent: Instance, classId: string, onPick: () -> ())
	local class = ClassConfig.Classes[classId]

	local card = new("TextButton", {
		Size = UDim2.fromOffset(180, 208),
		BackgroundColor3 = CARD_BG,
		BackgroundTransparency = 0.15,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
	local stroke = new("UIStroke", { Color = CARD_STROKE, Thickness = 1.5, Parent = card })
	new("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = card,
	})
	cardStrokes[classId] = stroke
	cardBackers[classId] = card

	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = string.upper(class.DisplayName),
		TextSize = 20,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	new("TextLabel", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = class.Role,
		TextSize = 12,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	new("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = CARD_STROKE,
		BorderSizePixel = 0,
		Parent = card,
	})
	new("TextLabel", {
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = class.Ability.Name,
		TextSize = 15,
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	new("TextLabel", {
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = class.Summary,
		TextSize = 13,
		TextColor3 = MUTED,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	card.Activated:Connect(onPick)
end

local function refreshCards()
	for classId, stroke in cardStrokes do
		local selected = classId == currentClassId
		stroke.Color = if selected then ACCENT else CARD_STROKE
		stroke.Thickness = if selected then 2.5 else 1.5
		cardBackers[classId].BackgroundTransparency = if selected then 0 else 0.15
	end
end

local function buildGui()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = new("ScreenGui", {
		Name = "ClassHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = playerGui,
	})

	-- Ability indicator, bottom-center.
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(210, 34),
		BackgroundColor3 = Color3.fromRGB(10, 14, 20),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = gui,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = panel })
	indicator = new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = TEXT,
		Text = "[F] Flechette",
		Parent = panel,
	})

	-- Pre-round picker, upper-center.
	picker = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(576, 244),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "SELECT CLASS — locks when the round begins",
		TextSize = 15,
		TextColor3 = TEXT,
		Parent = picker,
	})
	local row = new("Frame", {
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 208),
		BackgroundTransparency = 1,
		Parent = picker,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 18),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = row,
	})

	local setClass = RemoteUtil.getEvent(RemoteNames.SetClassRequest)
	for _, classId in CLASS_ORDER do
		buildCard(row, classId, function()
			setClass:FireServer(classId)
		end)
	end
	refreshCards()
end

local function render()
	local remaining = AbilityLogic.cooldownRemaining(workspace:GetServerTimeNow(), cooldownEnd)
	if remaining > 0 then
		indicator.Text = `[F] {abilityName}   {math.ceil(remaining)}s`
		indicator.TextColor3 = MUTED
	else
		indicator.Text = `[F] {abilityName}   READY`
		indicator.TextColor3 = Color3.fromRGB(120, 226, 150)
	end
end

local function applyLunge(payload: { Direction: Vector3 })
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.AssemblyLinearVelocity = payload.Direction * LUNGE_SPEED + Vector3.new(0, LUNGE_UP, 0)
	end
end

function ClassController.Start(_self: any)
	buildGui()

	local useAbility = RemoteUtil.getEvent(RemoteNames.UseAbilityRequest)
	local abilityStateChanged = RemoteUtil.getEvent(RemoteNames.AbilityStateChanged)
	local abilityEffect = RemoteUtil.getEvent(RemoteNames.AbilityEffect)
	local matchStateChanged = RemoteUtil.getEvent(RemoteNames.MatchStateChanged)

	InputController:BindAction("ClassAbility", function(began)
		if not began then
			return
		end
		local camera = workspace.CurrentCamera
		if camera then
			useAbility:FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
		end
	end)

	abilityStateChanged.OnClientEvent:Connect(
		function(state: { ClassId: string, AbilityName: string, CooldownEnd: number })
			currentClassId = state.ClassId
			abilityName = state.AbilityName
			cooldownEnd = state.CooldownEnd
			refreshCards()
			render()
		end
	)

	matchStateChanged.OnClientEvent:Connect(function(state: { Phase: string, RoundPhase: string })
		-- Pick during any prep phase; the picker hides once combat is live.
		picker.Visible = not MatchLogic.isCombatLive(state.Phase, state.RoundPhase)
	end)

	abilityEffect.OnClientEvent:Connect(function(payload: { Kind: string, Direction: Vector3 })
		if payload.Kind == "Lunge" then
			applyLunge(payload)
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return ClassController
