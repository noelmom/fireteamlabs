--!strict
-- Double jump (issue #26). One extra mid-air jump, reset on landing. Edge-
-- triggered off InputController's Jump action (fires once per key-down, never
-- while held), so holding jump can't auto-repeat. The air jump is only allowed
-- once the character is airborne (Freefall), so the initial ground jump — which
-- Roblox's default controller still handles — never consumes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local InputController = require(script.Parent.InputController)

local Movement = GameConfig.Movement

local JumpController = {
	Name = "JumpController",
}

local airborne = false
local airJumpsUsed = 0

local function watchCharacter(character: Model)
	airborne = false
	airJumpsUsed = 0

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.StateChanged:Connect(function(_old, new)
		if new == Enum.HumanoidStateType.Freefall then
			airborne = true
		elseif
			new == Enum.HumanoidStateType.Landed
			or new == Enum.HumanoidStateType.Running
			or new == Enum.HumanoidStateType.RunningNoPhysics
		then
			airborne = false
			airJumpsUsed = 0
		end
	end)
end

function JumpController.Start(_self: any)
	InputController:BindAction("Jump", function(began)
		if not began or not airborne or airJumpsUsed >= Movement.MaxAirJumps then
			return
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		airJumpsUsed += 1
		local velocity = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, Movement.DoubleJumpVelocity, velocity.Z)
	end)

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
end

return JumpController
