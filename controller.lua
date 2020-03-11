local vec3 = require("algebra/vec3")

local max = math.max

--modules
--local cast     = _G.require("cast")

local function projectnormal(p, d, v)
	return v + max(0, (p - v):dot(d))*d
end

local collider = {}

function collider.new(table)
	local self = {}
	
	--variables
	self.t = table.t or 0  --time
	self.p = table.p or vec3.null--position
	self.v = table.v or vec3.null--velocity
	
	--constants
	self.a = table.a or vec3.null--acceleration
	self.r = table.r or 0  --radius
	self.b = table.m or 0  --target velocity
	
	return self
end

function collider.update(self, t1)
	--variables
	local t0 = self.t
	local p0 = self.p
	local v0 = self.v
	
	--constants
	local a = self.a
	local r = self.r
	local b = self.b
	
	--calculation
	local td = t1 - t0
	
	--parabola
	local p1 = p0 + td*v0 + 1/2*td*td*a
	local v1 = v0 + td*a
	
	--spherecast
	--local ho, hp, hn = cast.spherecastcollideignore(p0, p1 - p0, r, {})
	--if #ho > 0 then
	--	p1 = hp
	--	for i = 1, #ho do
	--		local n = hn[i]
	--		v1 = projectnormal(nv3, n, v1)
	--	end
	--end
	
	--output
	self.t = t1
	self.p = p1
	self.v = v1
end

return collider