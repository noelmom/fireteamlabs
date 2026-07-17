--!strict
-- Client side of class abilities (issue #10): F casts the current class ability,
-- a stub class picker switches class, and an indicator shows the ability name
-- and cooldown. The lunge (Bulwark) is applied here since the client owns its
-- character's physics; the server stays authoritative for damage and cooldown.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClassConfig = require(ReplicatedStorage.Shared.Config.ClassConfig)
local RemoteNames = require(ReplicatedStorage.Remotes.RemoteNames)
local RemoteUtil = require(ReplicatedStorage.Shared.Utility.RemoteUtil)
local AbilityLogic = require(ReplicatedStorage.Shared.Utility.AbilityLogic)
local InputController = require(script.Parent.InputController)

local LUNGE_SPEED = 62
local LUNGE_UP = 8
local CLASS_ORDER = { "Specter", "Conduit", "Bulwark" }

local ClassController = {
	Name = "ClassController",
}

local abilityName = "Flechette"
local cooldownEnd = 0
local currentClassId = "Specter"

local indicator: TextLabel
local classButtons: { [string]: TextButton } = {}

local ACTIVE_COLOR = Color3.fromRGB(90, 180, 255)
local IDLE_COLOR = Color3.fromRGB(40, 46, 56)

local function buildGui()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "ClassHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Ability indicator, bottom-center.
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -24)
	panel.Size = UDim2.fromOffset(200, 34)
	panel.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
	panel.BackgroundTransparency = 0.35
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = panel

	indicator = Instance.new("TextLabel")
	indicator.Size = UDim2.fromScale(1, 1)
	indicator.BackgroundTransparency = 1
	indicator.Font = Enum.Font.GothamBold
	indicator.TextSize = 14
	indicator.TextColor3 = Color3.fromRGB(236, 241, 246)
	indicator.Text = "[F] Flechette"
	indicator.Parent = panel

	-- Class picker stub, top-left.
	local picker = Instance.new("Frame")
	picker.Position = UDim2.fromOffset(24, 84)
	picker.Size = UDim2.fromOffset(120, 3 * 30 + 8)
	picker.BackgroundTransparency = 1
	picker.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = picker

	local setClass = RemoteUtil.getEvent(RemoteNames.SetClassRequest)
	for _, classId in CLASS_ORDER do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(120, 30)
		button.BackgroundColor3 = IDLE_COLOR
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 13
		button.TextColor3 = Color3.fromRGB(220, 226, 232)
		button.Text = ClassConfig.Classes[classId].DisplayName
		button.Parent = picker
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 5)
		bc.Parent = button
		button.Activated:Connect(function()
			setClass:FireServer(classId)
		end)
		classButtons[classId] = button
	end

	gui.Parent = playerGui
end

local function refreshButtons()
	for classId, button in classButtons do
		button.BackgroundColor3 = if classId == currentClassId then ACTIVE_COLOR else IDLE_COLOR
	end
end

local function render()
	local remaining = AbilityLogic.cooldownRemaining(workspace:GetServerTimeNow(), cooldownEnd)
	if remaining > 0 then
		indicator.Text = `[F] {abilityName}   {math.ceil(remaining)}s`
		indicator.TextColor3 = Color3.fromRGB(150, 160, 172)
	else
		indicator.Text = `[F] {abilityName}   READY`
		indicator.TextColor3 = Color3.fromRGB(120, 226, 150)
	end
end

local function applyLunge(payload: { Direction: Vector3, Studs: number })
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	root.AssemblyLinearVelocity = payload.Direction * LUNGE_SPEED + Vector3.new(0, LUNGE_UP, 0)
end

function ClassController.Start(_self: any)
	buildGui()

	local useAbility = RemoteUtil.getEvent(RemoteNames.UseAbilityRequest)
	local abilityStateChanged = RemoteUtil.getEvent(RemoteNames.AbilityStateChanged)
	local abilityEffect = RemoteUtil.getEvent(RemoteNames.AbilityEffect)

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
			refreshButtons()
			render()
		end
	)

	abilityEffect.OnClientEvent:Connect(function(payload: { Kind: string, Direction: Vector3, Studs: number })
		if payload.Kind == "Lunge" then
			applyLunge(payload)
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return ClassController
