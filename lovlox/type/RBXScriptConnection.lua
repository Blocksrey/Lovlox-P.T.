local meta = {}
meta.__index = meta

function meta.Disconnect(self)
	self.func = nil
end

local Connection = {}

function Connection.new(func)
	local self = {}
	self.func = func
	setmetatable(self, meta)
	return self
end

return Connection