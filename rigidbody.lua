local v3         = Vector3.new
local nv3        = v3()
local cross      = nv3.Cross
local cf         = CFrame.new
local ncf        = cf()
local components = ncf.components
local cffaa      = CFrame.fromAxisAngle

local cframe = require("cframe")

local function inverse(m)
	local _, _, _, xx, yx, zx, xy, yy, zy, xz, yz, zz = components(m)
	local x = xy*yz - xz*yy
	local y = xz*yx - xx*yz
	local z = xx*yy - xy*yx
	local d = x*zx + y*zy + z*zz
	return cf(
		0, 0, 0,
		(yy*zz - yz*zy)/d, (yz*zx - yx*zz)/d, (yx*zy - yy*zx)/d,
		(xz*zy - xy*zz)/d, (xx*zz - xz*zx)/d, (xy*zx - xx*zy)/d,
		x/d, y/d, z/d
	)
end

local rigidbody = {}

function rigidbody.new(table)
	local self = {}
	
	--variables
	self.t     = table.t     or 0  --time
	self.x     = table.x     or nv3--position
	self.v     = table.v     or nv3--transitional velocity
	self.o     = table.o     or ncf--orientation
	
	--constants
	self.Ft = table.Ft or {} --force table
	self.m  = table.m  or 0  --mass
	self.I  = table.I  or ncf--moment of inertia
	
	self.L = table.L
		or table.omega and self.o*self.I*inverse(self.o)*table.omega
		or nv3 --rotational velocity
		
	return self
end

function rigidbody.update(self, t1)
	local t0 = self.t
	local x0 = self.x
	local v0 = self.v
	local o0 = self.o
	local L0 = self.L
	
	local Ft = self.Ft
	local m  = self.m
	local I  = self.I
	
	local F   = nv3
	local tau = nv3
	
	for i = 1, #Ft do
		local self = self.Ft
		F = F + self.F
		tau = tau + cross(self.x - x0, self.F)
	end
	
	local a = F/m
	
	local dt = t1 - t0
	
	local x1 = x0 + dt*v0 + 1/2*dt*dt*a
	local v1 = v0 + dt*a
	
	local omega1 = o0*inverse(o0*I)*L0
	local L1 = L0 + dt*tau
	local o1 = cframe.axisangle(dt*omega1)*o0
	
	self.t     = t1
	self.L     = L1
	self.x     = x1
	self.v     = v1
	self.o     = o1
	self.omega = omega1
end

return rigidbody