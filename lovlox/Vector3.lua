local meta = {}
meta.__index = meta

local function old(x, y, z)
	local self = {}

	self.type = "Vector3"
	
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0

	return setmetatable(self, meta)
end

local function new(x, y, z)
	local v = old(x, y, z)
	local x, y, z = v.x, v.y, v.z
	v.magnitude = (x*x + y*y + z*z)^(1/2)
	v.unit = old(x/v.magnitude, y/v.magnitude, z/v.magnitude)
	return v
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
	if type(a) ~= "number" then
		if type(b) == "number" then
			return new(a.x*b, a.y*b, a.z*b)
		elseif b.type == "Vector3" then
			return new(a.x*b.x, a.y*b.y, a.z*b.z)
		end
	else
		return new(a*b.x, a*b.y, a*b.z)
	end
end

function meta.__div(a, b)
	if type(a) ~= "number" then
		if type(b) == "number" then
			return new(a.x/b, a.y/b, a.z/b)
		elseif b.type == "Vector3" then
			return new(a.x/b.x, a.y/b.y, a.z/b.z)
		end
	else
		--return new(a*b.x, a*b.y, a*b.z)
	end
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
