--!strict
-- Server-side movement speed enforcement (issue #6, MASTERPLAN.md section 20).
-- Clients own their character physics on Roblox, so the server samples
-- horizontal displacement and corrects characters that persistently exceed
-- the fastest legal speed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Movement = GameConfig.Movement
local Validation = Movement.Validation

type Sample = {
	LastPosition: Vector3,
	LastValidPosition: Vector3,
	Violations: number,
}

local MovementValidationService = {
	Name = "MovementValidationService",
}

local samples: { [Player]: Sample } = {}

local function maxLegalSpeed(): number
	return Movement.SprintSpeed * Validation.ToleranceMultiplier
end

local function check(deltaSeconds: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character.PrimaryPart
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			samples[player] = nil
			continue
		end

		local position = root.Position
		local sample = samples[player]
		if not sample then
			samples[player] = {
				LastPosition = position,
				LastValidPosition = position,
				Violations = 0,
			}
			continue
		end

		local displacement = position - sample.LastPosition
		local horizontal = Vector3.new(displacement.X, 0, displacement.Z)
		local speed = horizontal.Magnitude / deltaSeconds
		sample.LastPosition = position

		if speed > maxLegalSpeed() then
			sample.Violations += 1
			if sample.Violations >= Validation.ViolationLimit then
				warn(`[MovementValidation] correcting {player.Name}: {math.floor(speed)} studs/s`)
				root.CFrame = CFrame.new(sample.LastValidPosition)
				sample.Violations = 0
			end
		else
			sample.Violations = 0
			sample.LastValidPosition = position
		end
	end
end

function MovementValidationService.Start(_self: any)
	Players.PlayerRemoving:Connect(function(player)
		samples[player] = nil
	end)

	local accumulated = 0
	RunService.Heartbeat:Connect(function(deltaSeconds)
		accumulated += deltaSeconds
		if accumulated >= Validation.CheckIntervalSeconds then
			check(accumulated)
			accumulated = 0
		end
	end)
end

return MovementValidationService
