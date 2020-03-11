local Signal = require("lovlox/Signal")


local world = {}

world.parts = {}

world.partadded = Signal.new()

function world.newpart(part)
	local index = #world.parts + 1
	world.parts[index] = part
	world.partadded(part)
	return part
end



local ptree = {}

local function rectoidtouch(p0, p1, s0, s1)
	local p0x, p0y, p0z = p0.x, p0.y, p0.z
	local p1x, p1y, p1z = p1.x, p1.y, p1.z
	local s0x, s0y, s0z = s0.x, s0.y, s0.z	
	local s1x, s1y, s1z = s1.x, s1.y, s1.z

	local nx0 = p0x - 1/2*s0x
	local px0 = p0x + 1/2*s0x
	local ny0 = p0y - 1/2*s0y
	local py0 = p0y + 1/2*s0y
	local nz0 = p0z - 1/2*s0z
	local pz0 = p0z + 1/2*s0z

	local nx1 = p1x - 1/2*s1x
	local px1 = p1x + 1/2*s1x
	local ny1 = p1y - 1/2*s1y
	local py1 = p1y + 1/2*s1y
	local nz1 = p1z - 1/2*s1z
	local pz1 = p1z + 1/2*s1z

	local x = nx0 < px1 and px0 < nx1
	local y = ny0 < py1 and py0 < ny1
	local z = nz0 < pz1 and pz0 < nz1

	return x and y and z
end

local function add()
end

local function search()
end

local rectoids = {}

local function rectoid(pos, siz)
	local self = {}
	self.p = pos
	self.s = size
	return self
end

local function rectoidfrompart(part)
	local p  = part.CFrame.Position
	local ss = part.Size.Magnitude
	local s  = Vector3.new(ss, ss, ss)
	return rectoid(p, s)
end

local function findonregion(pos, siz)

end

world.partadded:Connect(function(part)
	print("ASD")
	table.insert(rectoids, rectoidfrompart(part))
end)





return world

