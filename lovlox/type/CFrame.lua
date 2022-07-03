local Vector3 = require("lovlox/type/Vector3")

local cos   = math.cos
local sin   = math.sin
local atan2 = math.atan2
local asin  = math.asin

local CFrame = {}

local meta = {}
meta.__index = meta

local function new(x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz)
	local self = {}

	self.type = "CFrame"

	self.p        = Vector3.new(x, y, z)
	self.Position = self.p

	self.x = x or 0
	self.y = y or 0
	self.z = z or 0

	self.xx = xx or 1
	self.xy = xy or 0
	self.xz = xz or 0

	self.yx = yx or 0
	self.yy = yy or 1
	self.yz = yz or 0

	self.zx = zx or 0
	self.zy = zy or 0
	self.zz = zz or 1

	return setmetatable(self, meta)
end

function meta.components(self)
	return self.x, self.y, self.z, self.xx, self.yx, self.zx, self.xy, self.yy, self.zy, self.xz, self.yz, self.zz
end

function meta.Inverse(self)
	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = self:components()
	return new(-x-x*xx-x*xy-x*xz,-y-y*yx-y*yy-y*yz,-z-z*zx-z*zy-z*zz,xx,xy,xz,yx,yy,yz,zx,zy,zz)
end
meta.inverse = meta.Inverse

function meta.__tostring(self)
	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = self:components()
	return x.." "..y.." "..z.." "..xx.." "..yx.." "..zx.." "..xy.." "..yy.." "..zy.." "..xz.." "..yz.." "..zz
end

function meta.__add(a, b)
	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = a:components()
	return new(
		a.x + b.x, a.y + b.y, a.z + b.z,
		a.xx,      a.yx,      a.zx,
		a.xy,      a.yy,      a.zy,
		a.xz,      a.yz,      a.zz
	)
end

function meta.__sub(a, b)
	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = a:components()
	return new(
		a.x - b.x, a.y - b.y, a.z - b.z,
		a.xx,      a.yx,      a.zx,
		a.xy,      a.yy,      a.zy,
		a.xz,      a.yz,      a.zz
	)
end

function meta.__mul(c1,c2)
	if type(c1)=="table" and type(c2)=="table" and c1.type=="CFrame" and c2.type=="CFrame" then
		--print(c1)
		--print(c2)
		local ax,ay,az,axx,ayx,azx,axy,ayy,azy,axz,ayz,azz=c1:components()
		local bx,by,bz,bxx,byx,bzx,bxy,byy,bzy,bxz,byz,bzz=c2:components()
		return new(
			bx*axx+by*ayx+bz*azx+ax,bx*axy+by*ayy+bz*azy+ay,bx*axz+by*ayz+bz*azz+az,
			bxx*axx+bxy*ayx+bxz*azx,byx*axx+byy*ayx+byz*azx,bzx*axx+bzy*ayx+bzz*azx,
			bxx*axy+bxy*ayy+bxz*azy,byx*axy+byy*ayy+byz*azy,bzx*axy+bzy*ayy+bzz*azy,
			bxx*axz+bxy*ayz+bxz*azz,byx*axz+byy*ayz+byz*azz,bzx*axz+bzy*ayz+bzz*azz
		)
	else
		local v3,ax,ay,az,axx,ayx,azx,axy,ayy,azy,axz,ayz,azz
		if type(c1)=="table" and c1.type=="Vector3" then
			v3,ax,ay,az,axx,ayx,azx,axy,ayy,azy,axz,ayz,azz=c1,c2:components()
		elseif type(c2)=="table" and c2.type=="Vector3" then
			v3,ax,ay,az,axx,ayx,azx,axy,ayy,azy,axz,ayz,azz=c2,c1:components()
		else
			if type(c1)=="table" and c1.type=="CFrame" then
				error("Unexpected value near \"*\" at second argument: "..tostring(c2))
			else
				--error("Unexpected value near \"*\" at first argument: "..tostring(c1))
			end
		end
		return Vector3.new(ax+v3.x*axx+v3.y*ayx+v3.z*azx,ay+v3.x*axy+v3.y*ayy+v3.z*azy,az+v3.x*axz+v3.y*ayz+v3.z*azz)
	end
end

function meta.toWorldSpace(c,c1)
	return c*c1
end

function meta.toObjectSpace(c,c1)
	return c:inverse()*c1
end
	
function meta.pointToWorldSpace(c,v)
	return c*v
end
	
function meta.pointToObjectSpace(c,v)
	return c:inverse()*v
end

function meta.vectorToWorldSpace(c,v)
	return (c-c.p)*v
end
	
function meta.vectorToObjectSpace(c,v)
	local ci=c:inverse()
	return (ci-ci.p)*v
end

function meta.toEulerAnglesXYZ(c)--math credit goes to MrNicNac
	return atan2(-R12,R22),asin(R02),atan2(-R01,R00)
end

--[[
function meta.__index(c,i)
	local x,y,z,xx,yx,zx,xy,yy,zy,xz,yz,zz=c:components()
	if i=="p" then
		return Vector3.new(x,y,z)
	elseif i=="lookVector" then
		return -Vector3.new(zx,zy,zz)
	elseif i=="axes" then
		return {
			x=Vector3.new(xx,xy,xz),
			y=Vector3.new(yx,yy,yz),
			z=Vector3.new(zx,zy,zz)
		}
	elseif i=="unit" then
		local a=c.axes
		a.x=a.x.unit
		a.y=a.y.unit
		a.z=a.z.unit
		return CFrame.make(x,y,z,
		a.x.x,a.y.x,a.z.x,
		a.x.y,a.y.y,a.z.y,
		a.x.z,a.y.z,a.z.z)
	elseif i=="type" then
		return "CFrame"
	else
		return CFrame.methods[i]
	end
end
]]

--[[

	

}}
CFrame.metatable={
	__index=function(
	
	
	

}
__tostring=function(c)
		return concat({c:components()},", ")
	end,
CFrame.news=setmetatable({
	[0]=function()--blank
		return 0,0,0,
		1,0,0,
		0,1,0,
		0,0,1
	end,
	[1]=function(v3)--Origin
		return v3.x,v3.y,v3.z,
		1,0,0,
		0,1,0,
		0,0,1
	end,
	[2]=function(v3o,v3f)--Origin, Focus
		local u=(v3o-v3f).unit
		local s=sqrt(1-u.y^2)
		local r=-u.y/s
		return v3o.x,v3o.y,v3o.z,
		u.z/s,u.x*r,u.x,
		0,s,u.y,
		-u.x/s,u.z*r,u.z
	end,
	[3]=function(x,y,z)--x,y,z
		return x,y,z,
		1,0,0,
		0,1,0,
		0,0,1
	end,
	[7]=function(x,y,z,Q1,Q2,Q3,Q4)--quaternion
		local q1,q2,q3,q4=Q1/2,Q2/2,Q3/2,Q4/2
		return x,y,z,--idk lol wikipedia ftw en.wikipedia.org/wiki/Rotation_operator_(vector_space) almost all the way down the page or http://en.wikipedia.org/wiki/Rotation_matrix
		1-q1*q1-q4*q4,q2*q1-q3*q4,q3*q1+q2*q4,
		q1*q2+q3*q4,1-q2*q2-q4*q4,q3*q2-q1*q4,
		q1*q3-q2*q4,q2*q3+q1*q4,1-q3*q3-q4*q4
	end,
	


]]

CFrame.Angles=function(x,y,z)
	local xs,xc,ys,yc,zs,zc=sin(x),cos(x),sin(y),cos(y),sin(z),cos(z)
	return new(0,0,0,
	zc*yc,-zs*yc,ys,
	zc*ys*xs+zs*xc,zc*xc-zs*ys*xs,-yc*xs,
	zs*xs-zc*ys*xc,zs*ys*xc+zc*xs,yc*xc)
end
CFrame.fromEulerAnglesXYZ=CFrame.Angles

function CFrame.fromAxisAngle(u, a)
	u = u.Unit
	local x, y, z = u.x, u.y, u.z
	local c = cos(a)
	local s = sin(a)
	local t = 1 - c
	return new(0, 0, 0,
		t*x*x + c  , t*x*y - z*s   , t*x*z + y*s,
		t*x*y + z*s,  	t*y*y + c  , t*y*z - x*s,
		t*x*z - y*s,  	t*y*z + x*s, t*z*z + c
	)
end


CFrame.new = new

return CFrame