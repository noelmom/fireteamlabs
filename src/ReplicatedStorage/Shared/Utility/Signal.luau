--!strict
-- Minimal typed signal for intra-server events between services.

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = typeof(setmetatable({} :: { _handlers: { [number]: (...any) -> () } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, handler: (...any) -> ()): Connection
	local handlers = self._handlers
	local key = #handlers + 1
	handlers[key] = handler
	return {
		Disconnect = function(_conn: Connection)
			handlers[key] = nil
		end,
	}
end

function Signal.Fire(self: Signal, ...: any)
	for _, handler in self._handlers do
		task.spawn(handler, ...)
	end
end

return Signal
