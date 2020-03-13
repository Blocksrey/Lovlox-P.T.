local Vector3 = require("lovlox/types/Vector3")

local meta = {}
meta.__index = meta

function meta.__tostring(self)
	local o = self.Origin
	local d = self.Direction
	local ox, oy, oz = o.x, o.y, o.z
	local dx, dy, dz = d.x, d.y, d.z
	return "{"..tostring(o).."}, {"..tostring(d).."}"
end

function meta.ClosestPoint(self, point)
	local unit = self.Unit
	return unit.Direction:Dot(point - self.Origin)
end

function meta.Distance(self, point)
	return (self:ClosestPoint(point) - point).Magnitude
end

local function new0(origin, direction)
	local self = {}

	self.Origin    = origin    or Vector3.new()
	self.Direction = direction or Vector3.new()

	setmetatable(self, meta)

	return self
end

local function new1(origin, direction)
	local ray = new0(origin, direction)

	ray.Unit = new0(ray.Origin, ray.Direction.Unit)

	return ray
end

local Ray = {}

Ray.new = new1

return Ray