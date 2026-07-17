--!strict
-- Server entry point. Loads every service module, then runs the two-phase
-- lifecycle: Init on all services (safe to resolve dependencies), then Start.

local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")

type Service = {
	Name: string,
	Init: ((self: Service) -> ())?,
	Start: ((self: Service) -> ())?,
}

local services: { Service } = {}

for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		local service = require(child) :: Service
		service.Name = child.Name
		table.insert(services, service)
	end
end

table.sort(services, function(a, b)
	return a.Name < b.Name
end)

for _, service in services do
	if service.Init then
		service:Init()
	end
end

for _, service in services do
	if service.Start then
		service:Start()
	end
end

print(`[ServerBootstrap] {#services} services started`)
