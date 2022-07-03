local Connection = require("lovlox/type/RBXScriptConnection")

local newcon = Connection.new
local insert = table.insert

local meta = {}
meta.__index = meta

local Signal = {}

function Signal.new()
	local self = {}
	self.connections = {}
	setmetatable(self, meta)
	return self
end

function meta.__call(self, ...)
	for index, connection in next, self.connections do
		if connection.func then
			connection.func(...)
		end
	end
end

function meta.Connect(self, func)
	local connection = newcon(func)
	insert(self.connections, connection)
	return connection
end

meta.connect = meta.Connect

return Signal