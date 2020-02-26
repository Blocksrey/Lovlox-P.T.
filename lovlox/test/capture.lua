local v3         = Vector3.new
local nv3        = v3()
local dot        = nv3.Dot
local cf         = CFrame.new
local ncf        = cf()
local components = ncf.components
local faa        = CFrame.fromAxisAngle
local acos       = math.acos
local insert     = table.insert

local reflectaxis = v3(0, 0, 1)

--math functions
local function fromaxisangle(v)
	local m = v.Magnitude
	return m > 0 and faa(v, m) or ncf
end

local function toaxisangle(m)
	local x, y, z, xx, yx, zx, xy, yy, zy, xz, yz, zz = components(m)
	local c = acos(1/2*(xx + yy + zz - 1))/((zy - yz)*(zy - yz) + (xz - zx)*(xz - zx) + (yx - xy)*(yx - xy))^(1/2)
	return v3(
		c*(zy - yz),
		c*(xz - zx),
		c*(yx - xy)
	)
end

local function vecreflect(vec, norm)
	return vec - 2*dot(vec, norm)*norm
end

local function orireflect(orientation, axis)
	local axisangle = toaxisangle(orientation)
	local reflectedaxisangle = vecreflect(axisangle, axis)
	local reflectedorientation = fromaxisangle(reflectedaxisangle)
	return reflectedorientation	
end

local function recurse(parent, table)
	for index, value in next, parent:GetChildren() do
		if value:IsA("BasePart") then
			insert(table, value)
		end
		recurse(value, table)
	end
	return table
end

local function dostring(classname, ...)
	local fin = classname..".new("
	local tab = {...}
	local len = #tab
	for ind = 1, len - 1 do
		fin = fin..tab[ind]..", "
	end
	fin = fin..tab[len]..")"
	return fin
end

local function v3unp(v3)
	return v3.x, v3.y, v3.z
end

local function c3unp(c3)
	return c3.r, c3.g, c3.b
end

local cfunp = components

local function captureworld()
	print("\nreturn {")
	local parts = recurse(workspace, {})
	for index = 1, #parts do
		local part = parts[index]
		local pos = dostring("vec3", v3unp(vecreflect(part.CFrame.Position, reflectaxis)))
		local ori = dostring("mat3", select(4, cfunp(orireflect(part.CFrame, reflectaxis))))
		local siz = dostring("vec3", v3unp(part.Size))
		local col = dostring("vec3", c3unp(part.Color))
		print("{"..pos..", "..ori..", "..siz..", "..col.."};")
	end
	print("}\n")
end

return captureworld