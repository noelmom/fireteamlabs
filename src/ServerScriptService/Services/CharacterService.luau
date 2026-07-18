--!strict
-- Swaps each spawned default avatar for the player's class operator rig
-- (visual-direction pivot: realistic geared operators). The rigs are the
-- Meshy-generated, Avatar-Auto-Setup-rigged R15 models stored under
-- ReplicatedStorage.Characters (one per class id). Purely visual: health,
-- shields, movement, hitboxes, and weapons are untouched — the rig is a
-- standard R15 assembly the rest of the game already understands.
--
-- Best-effort: if a class rig is missing (asset failed to sync), the default
-- Roblox avatar is kept so the game stays playable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AbilityService = require(ServerScriptService.Services.AbilityService)

local CharacterService = {
	Name = "CharacterService",
}

-- Marks rigs this service spawned so their CharacterAdded pass is skipped.
local OPERATOR_ATTRIBUTE = "FireteamOperator"

local function rigFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("Characters") :: Folder?
end

local function applyOperator(player: Player, character: Model)
	if character:GetAttribute(OPERATOR_ATTRIBUTE) then
		return
	end
	local folder = rigFolder()
	if not folder then
		return
	end
	local classId = AbilityService:GetClass(player)
	local template = folder:FindFirstChild(classId)
	if not template or not template:IsA("Model") then
		return
	end

	-- Wait for the default character to be positioned (MapService pivots it to
	-- a team spawn after the engine settles), then take its place. The parent
	-- check must come after the frame wait: CharacterAdded fires before the
	-- character is parented to Workspace.
	local oldRoot = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not oldRoot then
		return
	end
	task.wait()
	if player.Character ~= character or not character.Parent then
		return -- already respawned/replaced meanwhile
	end

	local rig = template:Clone()
	rig.Name = player.Name
	rig:SetAttribute(OPERATOR_ATTRIBUTE, true)
	local rootPart = rig:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		rootPart.Anchored = false
	end

	local targetCFrame = oldRoot.CFrame
	player.Character = rig
	rig.Parent = workspace
	rig:PivotTo(targetCFrame)
	character:Destroy()
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		applyOperator(player, character)
	end)
end

function CharacterService.Start(_self: any)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		if player.Character then
			applyOperator(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return CharacterService
