local meta = {}
meta.__index = meta

local function new(x, y, z)
	local self = {}

	self.type = "Vector3"
	
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0

	return setmetatable(self, meta)
end

function meta.Dot(a, b)
	return a.x*b.x + a.y*b.y + a.z*b.z
end

function meta.Cross(a, b)
	return new(
		a.y*b.z - a.z*b.y,
		a.z*b.x - a.x*b.z,
		a.x*b.y - a.y*b.x
	)
end

function meta.__add(a, b)
	return new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function meta.__sub(a, b)
	return new(a.x - b.x, a.y - b.y, a.z - b.z)
end

function meta.__mul(a, b)
	return new(a.x*b.x, a.y*b.y, a.z*b.z)
end

function meta.__div(a, b)
	return new(a.x/b.x, a.y/b.y, a.z/b.z)
end

function meta.__unm(self)
	return new(-self.x, -self.y, -self.z)
end

function meta.__tostring(self)
	return self.x.." "..self.y.." "..self.z
end

local Vector3 = {}

Vector3.new = new

return Vector3
