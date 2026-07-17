--!strict
-- Get-or-create access to remotes under ReplicatedStorage.Remotes.
-- The server creates instances at startup; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteUtil = {}

local function remotesFolder(): Instance
	return ReplicatedStorage:WaitForChild("Remotes")
end

function RemoteUtil.getEvent(name: string): RemoteEvent
	local folder = remotesFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: RemoteEvent
		end
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		return event
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return RemoteUtil
