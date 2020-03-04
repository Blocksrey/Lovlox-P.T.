local Signal = require("lovlox/Signal")

local cache  = {}
local meta   = {}
meta.__index = meta

function meta.Destroy(self)

end

function meta.Clone(self)
end

function meta.__index(self, index)
	return meta[index] or cache[self][index]
end

function meta.__newindex(self, index, value)
	local last = cache[self][index]
	if last ~= value then
		cache[self][index] = value
		cache[self].Changed(index)
	end
end

function meta.GetService(self, name)
	local serv = self[name]
	if serv then
		print("obtain service: "..name)
		return serv
	else
		print("no service: "..name)
		return nil
	end
end

function meta.__tostring(self)
	return self.ClassName
end

local object = {}

function object.new(props)
	local self = {}

	cache[self] = {}

	cache[self].ClassName = nil
	cache[self].Parent    = Parent
	cache[self].Changed   = Signal.new()

	for index, value in next, props or {} do
		cache[self][index] = value
		--print(index)
	end

	return setmetatable(self, meta)
end

return object