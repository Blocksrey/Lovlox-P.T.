local v3         = Vector3.new
local nv3        = v3()
local dot        = nv3.Dot
local cf         = CFrame.new
local ncf        = cf()
local cfunp      = ncf.components
local insert     = table.insert
local frommatrix = CFrame.fromMatrix

local function v3unp(v3)
	return v3.x, v3.y, v3.z
end

local function c3unp(c3)
	return c3.r, c3.g, c3.b
end

local function shunp(sh)
	return
		sh == Enum.PartType.Ball     and "Ball"     or
		sh == Enum.PartType.Block    and "Block"    or
		sh == Enum.PartType.Cylinder and "Cylinder"
end

local function cfparts(cf)
	local
		px, py, pz,
		xx, yx, zx,
		xy, yy, zy,
		xz, yz, zz = cfunp(cf)
	
	local p = v3(px, py, pz)
	local x = v3(xx, xy, xz)
	local y = v3(yx, yy, yz)
	local z = v3(zx, zy, zz)
	
	return p, x, y, z
end

local function v3ref(vec, dir)
	return vec - 2*dot(vec, dir)*dir
end

local function cfref(ori, dir)
	local p, x, y, z = cfparts(ori)
	
	local v = v3ref(p, dir)
	local i = v3ref(x, dir)
	local j = v3ref(y, dir)
	local k = v3ref(z, dir)
	
	return frommatrix(v, i, j, k)
end

local function argstr(str, div, fin, ...)
	local tab = {...}
	local len = #tab
	for ind = 1, len - 1 do
		str = str..tab[ind]..div
	end
	return str..tab[len]..fin
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

local function captureworld(reflectaxis)
	local tab = recurse(workspace, {})
	print("\nreturn {\nParts = {")
	for ind = 1, #tab do
		local obj = tab[ind]
		local cf  = cfref(obj.CFrame, reflectaxis)
		local pos = argstr("vec3.new(", ", ", ")", v3unp(cf.Position))
		local ori = argstr("mat3.new(", ", ", ")", select(4, cfunp(cf)))
		local siz = argstr("vec3.new(", ", ", ")", v3unp(obj.Size))
		local col = argstr("vec3.new(", ", ", ")", c3unp(obj.Color))
		if obj.ClassName == "Part" then
			local sha = argstr('"', "", '"', shunp(obj.Shape))
			print(argstr("{", ", ", "};", pos, ori, siz, col, sha))
		end
	end
	print("};\nWedgeParts = {")
		for ind = 1, #tab do
		local obj = tab[ind]
		local cf  = cfref(obj.CFrame, reflectaxis)
		local pos = argstr("vec3.new(", ", ", ")", v3unp(cf.Position))
		local ori = argstr("mat3.new(", ", ", ")", select(4, cfunp(cf)))
		local siz = argstr("vec3.new(", ", ", ")", v3unp(obj.Size))
		local col = argstr("vec3.new(", ", ", ")", c3unp(obj.Color))
		if obj.ClassName == "WedgePart" then
			print(argstr("{", ", ", "};", pos, ori, siz, col))
		end
	end
	print("};\n}\n")
end

return captureworld