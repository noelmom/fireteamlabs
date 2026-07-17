--!strict
-- Client entry point. Loads every controller module, then runs the same
-- two-phase Init/Start lifecycle the server uses.

local controllersFolder = script.Parent:WaitForChild("Controllers")

type Controller = {
	Name: string,
	Init: ((self: Controller) -> ())?,
	Start: ((self: Controller) -> ())?,
}

local controllers: { Controller } = {}

for _, child in controllersFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		local controller = require(child) :: Controller
		controller.Name = child.Name
		table.insert(controllers, controller)
	end
end

table.sort(controllers, function(a, b)
	return a.Name < b.Name
end)

for _, controller in controllers do
	if controller.Init then
		controller:Init()
	end
end

for _, controller in controllers do
	if controller.Start then
		controller:Start()
	end
end

print(`[ClientBootstrap] {#controllers} controllers started`)
