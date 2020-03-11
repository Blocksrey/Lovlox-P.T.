local v3 = Vector3.new
local nv = v3()
local dot = nv.Dot

local function hash2(a, b)
	return a + (a + b)*(a + b + 1)/2
end

local function newprotomesh(planes, connections)
	local faces = {}
	local edges = {}
	local verts = {}
	for i = 1, #planes do
		local rawplane = planes[i]
		faces[i] = {
			edges = {};
			p = rawplane[1];
			n = rawplane[2].unit;
		}
	end
	local firstvert = {}
	local function addfaceedges(f, e)
		local faceedges = faces[f].edges
		faceedges[#faceedges + 1] = e
	end
	local function addvertedges(v, e)
		local vertedges = verts[v].edges
		vertedges[#vertedges + 1] = e
	end
	local function tryedge(vindexa, findexa, findexb)
		if findexb < findexa then findexa, findexb = findexb, findexa end
		local edgehash = hash2(findexa, findexb)
		local vindexb = firstvert[edgehash]
		if vindexb then
			if vindexb < vindexa then vindexa, vindexb = vindexb, vindexa end
			local eindex = #edges + 1
			local va = verts[vindexa]
			local vb = verts[vindexb]
			local vap = va.v
			local vbp = vb.v
			local eap = (vap + vbp)/2
			local ead = (vbp - vap)/2
			edges[eindex] = {
				faces = {findexa, findexb};
				verts = {vindexa, vindexb};
				e = eap;
				l = ead;
			}
			addfaceedges(findexa, eindex)
			addfaceedges(findexb, eindex)
			addvertedges(vindexa, eindex)
			addvertedges(vindexb, eindex)
		else
			firstvert[edgehash] = vindexa
		end
	end
	for i = 1, #connections do
		local con = connections[i]
		local facea = faces[con[1]]
		local faceb = faces[con[2]]
		local facec = faces[con[3]]
		local a = facea.p
		local b = faceb.p
		local c = facec.p
		local u = facea.n
		local v = faceb.n
		local w = facec.n
		--keeping the old naming convention cause it's small
		local au = dot(a, u)
		local bv = dot(b, v)
		local cw = dot(c, w)
		local uu = dot(u, u)
		local uv = dot(u, v)
		local uw = dot(u, w)
		local vv = dot(v, v)
		local vw = dot(v, w)
		local ww = dot(w, w)
		local d = uu*vv*ww + 2*uv*uw*vw - uw*uw*vv - uu*vw*vw - uv*uv*ww
		local r = (cw*uv*vw - cw*uw*vv + bv*uw*vw - au*vw*vw - bv*uv*ww + au*vv*ww)/d
		local s = (cw*uv*uw - bv*uw*uw - cw*uu*vw + au*uw*vw + bv*uu*ww - au*uv*ww)/d
		local t = (bv*uv*uw - cw*uv*uv + cw*uu*vv - au*uw*vv - bv*uu*vw + au*uv*vw)/d
		verts[i] = {
			edges = {};
			v = r*u + s*v + t*w;
		}
		for j = 1, #con - 1 do
			for k = j + 1, #con do
				tryedge(i, con[j], con[k])
			end
		end
	end
	local mesh = {
		faces = faces;
		edges = edges;
		verts = verts;
	}
	return mesh
end

local function scalemesh(protomesh, size)
	local faces = protomesh.faces
	local edges = protomesh.edges
	local verts = protomesh.verts
	local newfaces = {}
	local newedges = {}
	local newverts = {}
	for i = 1, #faces do
		newfaces[i] = {}
	end
	for i = 1, #edges do
		newedges[i] = {}
	end
	for i = 1, #verts do
		newverts[i] = {}
	end
	for i = 1, #faces do
		local fa = faces[i]
		local fae = fa.edges
		local newfa = newfaces[i]
		local newfae = {}
		local newfaf = {}
		for j = 1, #fae do
			local ea = edges[fae[j]]
			local fai = ea.faces[1]
			local fbi = ea.faces[2]
			newfae[j] = newedges[fae[j]]
			newfaf[j] = newfaces[i == fai and fbi or fai]
		end
		newfa.edges = newfae
		newfa.faces = newfaf
		newfa.p = size*fa.p
		newfa.n = (fa.n/size).unit
	end
	for i = 1, #edges do
		local ea = edges[i]
		local eaf = ea.faces
		local eav = ea.verts
		local newea = newedges[i]
		newea.facea = newfaces[eaf[1]]
		newea.faceb = newfaces[eaf[2]]
		newea.verta = newverts[eav[1]]
		newea.vertb = newverts[eav[2]]
		newea.e = size*ea.e
		newea.l = size*ea.l
	end
	for i = 1, #verts do
		local va = verts[i]
		local vae = va.edges
		local newva = newverts[i]
		local newvae = {}
		for j = 1, #vae do
			newvae[j] = newedges[vae[i]]
		end
		newva.edges = newvae
		newva.v = size*va.v
	end
	local mesh = {
		faces = newfaces;
		edges = newedges;
		verts = newverts;
	}
	return mesh
end












--local str

local function refinevert(vert, radius, orig, dir)
	--str = str.."vert "
	--just return the fucking position and norm lol
	local v = vert.v
	local r = orig - v
	local dd = dot(dir, dir)
	local dr = dot(dir, r)
	local t = -dr/dd
	if t < 0 then t = 0
	elseif 1 < t then t = 1
	end
	local q = orig + t*dir
	local r = q - v
	local dist = r.magnitude
	if radius < dist then return end
	return v, r.unit
end

local function refineedge(edge, radius, orig, dir)
	--str = str.."edge "
	local e = edge.e
	local l = edge.l
	local r = orig - e
	local ll = dot(l, l)
	local ld = dot(l, dir)
	local lr = dot(l, r)
	local dd = dot(dir, dir)
	local dr = dot(dir, r)
	local det = ll*dd - ld*ld
	if det*det < 1e-6 then
		local s0 = lr/ll
		local s1 = (ld + lr)/ll
		if s1 < -1 then
			return refinevert(edge.verta, radius, orig, dir)
		elseif 1 < s0 then
			return refinevert(edge.vertb, radius, orig, dir)
		else
			local n = r - lr/ll*l
			return e, n.unit
		end
	else
		local t = (ld*lr - ll*dr)/det
		if t < 0 then t = 0
		elseif 1 < t then t = 1
		end
		local s = (t*ld + lr)/ll
		if s < -1 then
			return refinevert(edge.verta, radius, orig, dir)
		elseif s < 1 then
			local n = r + t*dir - s*l
			return e, n.unit
		else
			return refinevert(edge.vertb, radius, orig, dir)
		end
	end
end

local function refineface(face, radius, orig, dir)
	--str = str.."face "
	local facefaces = face.faces
	local faceedges = face.edges
	local a = face.p
	local u = face.n
	local du = dot(dir, u)
	if du*du < 1e-6 then
		--when it jitters this is why
		--once this is in it will be perfect
		--print("YO, ADD THIS LONG CASE")
	end
	local q = du < 0 and orig + dir or orig
	local facedist = dot(q - a, u)
	local maxdist2 = radius*radius - facedist*facedist
	local bestdist = 0
	local bestedge
	for i = 1, #faceedges do
		local edge = faceedges[i]
		local faceb = facefaces[i]
		local e = edge.e
		local v = faceb.n
		local uv = dot(u, v)
		local n = (v - uv*u).unit--this should be pre-computed
		local dist = dot(q - e, n)
		if bestdist < dist then
			--if maxdist2 < dist*dist then return end
			bestdist = dist
			bestedge = edge
		end
	end
	if bestedge then
		return refineedge(bestedge, radius, orig, dir)
	else
		return a, u
	end
end

--CORE PRINCIPLE
--This is a standard closest point to sphere operation
--except we extrude the shape in the direction -dir
local function getpushplane(mesh, radius, orig, dir)
	--str = "volume "
	local faces = mesh.faces
	local edges = mesh.edges
	local bestdist = -1/0
	local bestcell
	local bestfunc
	local bestnorm
	local bestpos
	local stop = orig + dir
	for i = 1, #faces do
		local face = faces[i]
		local p = face.p
		local n = face.n
		local dn = dot(n, dir)
		local dist
		if dn < 0 then
			dist = dot(n, stop - p)
		else
			dist = dot(n, orig - p)
		end
		if bestdist < dist then
			if radius < dist then return end
			bestdist = dist
			bestcell = face
			bestfunc = refineface
			bestnorm = n
			bestpos = p
		end
	end
	--local dd = dot(dir, dir)
	for i = 1, #edges do
		local edge = edges[i]
		local u = edge.facea.n
		local v = edge.faceb.n
		local du = dot(dir, u)
		local dv = dot(dir, v)
		--what if parallel
		--do a linearity check first in future
		if du*dv < 0 then--might want to be < -1e-3 or something
			local e = edge.e
			local n = (du < 0 and dv*u - du*v or du*v - dv*u).unit
			local dist = dot(n, orig - e)
			if bestdist < dist then
				if radius < dist then return end
				bestdist = dist
				bestcell = edge
				bestfunc = refineedge
				bestnorm = n
				bestpos = e
			end
		end
	end
	if bestdist < 0 then
		return bestpos, bestnorm
	else
		return bestfunc(bestcell, radius, orig, dir)
	end
end

local protobox = newprotomesh(
	{
		{v3(1/2, 0, 0), v3(1, 0, 0)},
		{v3(0, 1/2, 0), v3(0, 1, 0)},
		{v3(0, 0, 1/2), v3(0, 0, 1)},
		{v3(-1/2, 0, 0), v3(-1, 0, 0)},
		{v3(0, -1/2, 0), v3(0, -1, 0)},
		{v3(0, 0, -1/2), v3(0, 0, -1)},
	},{
		{1, 2, 3},
		{1, 2, 6},
		{1, 5, 3},
		{1, 5, 6},
		{4, 2, 3},
		{4, 2, 6},
		{4, 5, 3},
		{4, 5, 6},
	}
)

local protowedge = newprotomesh(
	{
		{v3(1/2, 0, 0), v3(1, 0, 0)},
		{v3(0, 0, 1/2), v3(0, 0, 1)},
		{v3(-1/2, 0, 0), v3(-1, 0, 0)},
		{v3(0, -1/2, 0), v3(0, -1, 0)},
		{v3(0, 0, 0), v3(0, 1, -1)},
	},{
		{1, 2, 4},
		{1, 2, 5},
		{1, 4, 5},
		{3, 2, 4},
		{3, 2, 5},
		{3, 4, 5},
	}
)

local protocorner = newprotomesh(
	{
		{v3(1/2, 0, 0), v3(1, 0, 0)},--right
		{v3(0, -1/2, 0), v3(0, -1, 0)},--bottom
		{v3(0, 0, -1/2), v3(0, 0, -1)},--front
		{v3(0, 0, 0), v3(0, 1, 1)},--top back
		{v3(0, 0, 0), v3(-1, 1, 0)},--top left
	},{
		{1, 2, 3},
		{1, 2, 4},
		{1, 3, 4, 5},
		{2, 3, 5},
		{2, 4, 5},
	}
)





--time to build the solver
--assume unit normals
--a b c are positions
--u v w are normals
--i is inset
--p is starting position
local function solve1(a, u, i, p)
	local au = dot(a, u) + i
	local pu = dot(p, u)
	local d = 1
	local t = (au - pu)/d
	return p + t*u
end

local function solve2(a, u, b, v, i, p)
	local au = dot(a, u) + i
	local bv = dot(b, v) + i
	local pu = dot(p, u)
	local pv = dot(p, v)
	local uv = dot(u, v)
	local d = 1 - uv*uv
	local s = (au - pu - (bv - pv)*uv)/d
	local t = (bv - pv - (au - pu)*uv)/d
	return p + s*u + t*v
end

local function solve3(a, u, b, v, c, w, i, p)--p inconsequential
	local au = dot(a, u) + i
	local bv = dot(b, v) + i
	local cw = dot(c, w) + i
	local uv = dot(u, v)
	local uw = dot(u, w)
	local vw = dot(v, w)
	local d = 1 + 2*uv*uw*vw - uw*uw - vw*vw - uv*uv
	local r = (cw*uv*vw - cw*uw + bv*uw*vw - au*vw*vw - bv*uv + au)/d
	local s = (cw*uv*uw - bv*uw*uw - cw*vw + au*uw*vw + bv - au*uv)/d
	local t = (bv*uv*uw - cw*uv*uv + cw - au*uw - bv*vw + au*uv*vw)/d
	return r*u + s*v + t*w
end

local function solve(poses, norms, radius, orig, dir)
	local oposes = {}
	for i = 1, #poses do
		local n = norms[i]
		local dn = dot(n, dir)
		if dn < 0 then
			oposes[i] = poses[i] - dir
		else
			oposes[i] = poses[i]
		end
	end
	local point = orig
	local besti
	local bestdist = 0
	for i = 1, #oposes do
		local p = oposes[i]
		local n = norms[i]
		local dist = dot(point - p, n) - radius
		if dist < bestdist then
			besti = i
			bestdist = dist
		end
	end
	if not besti then
		return point
	end
	local a = oposes[besti]
	local u = norms[besti]
	local point = solve1(a, u, radius, orig)
	local bestj
	local bestdist = 0
	for j = 1, #oposes do
		if j ~= besti then
			local p = oposes[j]
			local n = norms[j]
			local uv = dot(n, u)
			if 1e-3 < 1 - uv*uv then
				local dist = dot(point - p, n) - radius
				if dist < bestdist then
					bestj = j
					bestdist = dist
				end
			end
		end
	end
	if not bestj then
		return point, u
	end
	local b = oposes[bestj]
	local v = norms[bestj]
	local point = solve2(a, u, b, v, radius, orig)
	local bestk
	local bestdist = 0
	for k = 1, #oposes do
		if k ~= besti and k ~= bestj then
			local p = oposes[k]
			local n = norms[k]
			local uv = dot(u, v)
			local uw = dot(u, n)
			local vw = dot(v, n)
			if 1e-3 < 1 + 2*uv*uw*vw - uw*uw - vw*vw - uv*uv then
				local dist = dot(point - p, n) - radius
				if dist < bestdist then
					bestk = k
					bestdist = dist
				end
			end
		end
	end
	if not bestk then
		return point, u, v
	end
	local c = oposes[bestk]
	local w = norms[bestk]
	local point = solve3(a, u, b, v, c, w, radius, orig)
	local bestl--ok now we see if we have managed to solve it out of all planes
	local bestdist = 0
	for l = 1, #oposes do
		if l ~= besti and l ~= bestj and l ~= bestk then
			local p = oposes[l]
			local n = norms[l]
			local dist = dot(point - p, n) - radius
			if dist < bestdist then
				bestl = l
				bestdist = dist
			end
		end
	end
	if not bestl then
		return point, u, v, w
	end
	return point, u, v, w, true
end

--poses


local function vsolve1(u, p)
	local pu = dot(p, u)
	local d = 1
	local t = -pu/d
	return p + t*u
end

local function vsolve2(u, v, p)
	local pu = dot(p, u)
	local pv = dot(p, v)
	local uv = dot(u, v)
	local d = 1 - uv*uv
	local s = (pv*uv - pu)/d
	local t = (pu*uv - pv)/d
	return p + s*u + t*v
end

local function vsolve3(u, v, w, p)--arguments inconsequential
	return 0*p
end

local function vsolve(norms, p)
	local point = p
	local besti
	local bestdist = 0
	for i = 1, #norms do
		local n = norms[i]
		local dist = dot(point, n)
		if dist < bestdist then
			besti = i
			bestdist = dist
		end
	end
	if not besti then
		return point
	end
	local u = norms[besti]
	local point = vsolve1(u, p)
	local bestj
	local bestdist = 0
	for j = 1, #norms do
		local n = norms[j]
		local uv = dot(u, n)
		if 1e-6 < 1 - uv*uv then
			local dist = dot(point, n)
			if dist < bestdist then
				bestj = j
				bestdist = dist
			end
		end
	end
	if not bestj then
		return point, u
	end
	local v = norms[bestj]
	local point = vsolve2(u, v, p)
	local bestk
	local bestdist = 0
	for k = 1, #norms do
		local n = norms[k]
		local uv = dot(u, v)
		local uw = dot(u, n)
		local vw = dot(v, n)
		if 1e-6 < 1 + 2*uv*uw*vw - uw*uw - vw*vw - uv*uv then
			local dist = dot(point, n)
			if dist < bestdist then
				bestk = k
				bestdist = dist
			end
		end
	end
	if not bestk then
		return point, u, v
	end
	local w = norms[bestk]
	local point = vsolve3(u, v, w, p)
	return point, u, v, w
end



--this can be made better
local function pushsolve(p0, v0, a, p1, t)
	if
		v0 < 0 and p0 - v0*v0/(2*a) < p1
		or 0 <= v0 and p0 + v0*v0/(2*a) < p1
	then
		local t1 = ((2*v0*v0 + 4*a*(p1 - p0))^0.5 - v0)/a
		local ti = (a*t1 - v0)/(2*a)--time interchange
		if t < ti then
			return p0 + t*v0 + t*t/2*a,
				v0 + t*a
		elseif t < t1 then
			return p1 - (t - t1)*(t - t1)/2*a,
				-a*(t - t1)
		else
			return p1,
				0
		end
	else
		local t1 = ((2*v0*v0 - 4*a*(p1 - p0))^0.5 + v0)/a
		local ti = (a*t1 + v0)/(2*a)--time interchange
		if t < ti then
			return p0 + t*v0 - t*t/2*a,
				v0 - t*a
		elseif t < t1 then
			return p1 + (t - t1)*(t - t1)/2*a,
				a*(t - t1)
		else
			return p1,
				0
		end
	end
end

local e = 2.718281828459045

local function springsolve(s, d, p0, v0, p1, t)
	--if d < 1 then
	--elseif d == 1 then
		local ex = e^(-s*t)
		return (1 - ex*(s*t + 1))*p1 + ex*(s*t + 1)*p0 + ex*t*v0,
			ex*s*s*t*p1 - ex*s*s*t*p0 + ex*(1 - s*t)*v0
	--else
	--end
end




--okay let's just do this
local function getparts(radius, orig, dir, ignore)
	local lx, ly, lz = orig.x, orig.y, orig.z
	local ux, uy, uz = lx + dir.x, ly + dir.y, lz + dir.z
	if ux < lx then lx, ux = ux, lx end
	if uy < ly then ly, uy = uy, ly end
	if uz < lz then lz, uz = uz, lz end
	local region = Region3.new(
		v3(lx - radius, ly - radius, lz - radius),
		v3(ux + radius, uy + radius, uz + radius)
	)
	local parts = game.Workspace:FindPartsInRegion3WithIgnoreList(region, ignore, 1/0)
	local n = 1
	for i = 1, #parts do
		if not parts[n].CanCollide then
			parts[n] = parts[#parts]
			parts[#parts] = nil
		else
			n = n + 1
		end
	end
	return parts
end


local model = Instance.new("Model", game.Workspace)
local function makepart(color, size, cframe)
	local part = Instance.new("Part", model)
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	return part
end

local function makepoint(color, p)
	return makepart(color, Vector3.new(0.2, 0.2, 0.2), CFrame.new(p))
end

local function makeray(color, o, d)
	local m = d.magnitude
	return makepart(color, Vector3.new(0.1, 0.1, m), CFrame.new(o, o + d)*CFrame.new(0, 0, -m/2))
end

local function newinstancehash()
	local hash = {}
	
	local meta = {}
	function meta:__newindex(object, data)
		local connection
		connection = object:GetPropertyChangedSignal("Parent"):connect(function()
			if not object.Parent then
				connection:disconnect()
				hash[object] = nil
			end
		end)
	end
	
	return setmetatable(hash, meta)
end

local meshhash = newinstancehash()
local function getmesh(part)
	local size = part.Size
	local data = meshhash[part]
	local class = part.ClassName
	if data then
		if data.size ~= size then
			data.size = size
			local protomesh
			if class == "Part" then
				protomesh = protobox
			elseif class == "WedgePart" then
				protomesh = protowedge
			elseif class == "CornerWedgePart" then
				protomesh = protocorner
			else
				--print("needs", class)
				protomesh = protobox
			end
			data.mesh = scalemesh(protomesh, size)
		end
	else
		local protomesh
		if class == "Part" then
			protomesh = protobox
		elseif class == "WedgePart" then
			protomesh = protowedge
		elseif class == "CornerWedgePart" then
			protomesh = protocorner
		else
			--print("needs", class)
			protomesh = protobox
		end
		data = {
			mesh = scalemesh(protomesh, size);
			size = size;
		}
		--[[do
			local mesh = data.mesh
			local edges = mesh.edges
			for i = 1, #edges do
				local edge = edges[i]
				print(edge.l)
				makeray(Color3.new(0, 1, 0), part.CFrame*edge.e, part.CFrame:vectorToWorldSpace(edge.l))
			end
		end]]
		meshhash[part] = data
		--[[local connection
		connection = part:GetPropertyChangedSignal("Parent"):connect(function()
			if not part.Parent then
				connection:disconnect()
				meshhash[part] = nil
			end
		end)]]
	end
	return data.mesh
end

local nc = CFrame.new()
local ptws = nc.pointToWorldSpace
local vtws = nc.vectorToWorldSpace
local ptos = nc.pointToObjectSpace
local vtos = nc.vectorToObjectSpace
local function partpushplane(part, radius, orig, dir)
	local mesh = getmesh(part)
	local partcf = part.CFrame
	local relpos, relnorm = getpushplane(
		mesh,
		radius,
		ptos(partcf, orig),
		vtos(partcf, dir)
	)
	if relpos then
		return ptws(partcf, relpos),
			vtws(partcf, relnorm)
	end
end

local function getpushplanes(radius, orig, dir, ignore, whitefunc)
	local parts = getparts(radius, orig, dir, ignore)
	local n = 0
	local poses = {}
	local norms = {}
	for i = 1, #parts do
		local part = parts[i]
		if not whitefunc or whitefunc(part) then
			local pos, norm = partpushplane(part, radius, orig, dir)
			if pos then
				n = n + 1
				poses[n] = pos
				norms[n] = norm
			end
		end
	end
	return {
		poses = poses;
		norms = norms;
	}
end




local cf = CFrame.new
local function resolvePlane(points, basis)
	local xs = {}
	local ys = {}--we're solving relative to this one
	local zs = {}

	local h, u, v--we want these

	local ptos = basis.pointToObjectSpace

	local n = #points
	for i = 1, n do
		local p = ptos(basis, points[i])
		xs[i] = p.x
		ys[i] = p.y
		zs[i] = p.z
	end

	local pos
	local nrm

	if n == 0 then
		return
	elseif n == 1 then
		pos = v3(0, ys[1], 0)
		nrm = v3(0, 1, 0)
	elseif n == 2 then
		local ax = xs[1]
		local ay = ys[1]
		local az = zs[1]
		local bx = xs[2]
		local by = ys[2]
		local bz = zs[2]
		local dx = bx - ax
		local dy = by - ay
		local dz = bz - az
		local det = dx*dx + dz*dz--lol misnomer? idk, do you?
		local u = dx*dy/det
		local v = dy*dz/det
		local h = ay - ax*u - az*v
		pos = v3(0, h, 0)
		nrm = v3(-u, 1, -v).unit
	else
		--[[
		xx xz xc   u   xy
		xz zz zc x v = yz
		xc zc cc   h   yc
		]]
		local xx, xz, xc = 0, 0, 0
		local zz, zc = 0, 0
		local cc = 0

		local xy, yz, yc = 0, 0, 0

		for i = 1, n do
			local x = xs[i]
			local y = ys[i]
			local z = zs[i]
			xx = xx + x*x
			xz = xz + x*z
			xc = xc + x
			zz = zz + z*z
			zc = zc + z
			cc = cc + 1
			xy = xy + x*y
			yz = yz + y*z
			yc = yc + y
		end

		local det = cc*xx*zz - cc*xz*xz + 2*xc*xz*zc - xx*zc*zc - xc*xc*zz

		local u = (cc*xy*zz - cc*xz*yz + xz*yc*zc + xc*yz*zc - xy*zc*zc - xc*yc*zz)/det
		local v = (cc*xx*yz - cc*xy*xz + xc*xz*yc - xc*xc*yz + xc*xy*zc - xx*yc*zc)/det
		local h = (xc*xz*yz - xz*xz*yc + xy*xz*zc - xx*yz*zc - xc*xy*zz + xx*yc*zz)/det
		
		if det*det < 1e-12 then
			--temporary
			pos = v3(0, yc/cc, 0)
			nrm = v3(0, 1, 0)
		else
			pos = v3(0, h, 0)
			nrm = v3(-u, 1, -v).unit
		end

	end

	return basis*pos, basis:vectorToWorldSpace(nrm)
end

local function makeBasis(o, d)
	local m = d.magnitude
	local w = d.y + m
	local x = d.z
	local y = 0
	local z = -d.x
	if w < 1e-6*m then
		return cf(0, 0, 0, 1, 0, 0, 0) + o
	else
		return cf(0, 0, 0, x, y, z, w) + o
	end
end

local cross = nv.Cross
local function look(a, b, o)
	local q = a.magnitude*b.magnitude
	local d = dot(a, b)
	local c = cross(a, b)
	local R = cf(0, 0, 0, c.x, c.y, c.z, d + q)
	if o then
		return R - R*o + o
	else
		return R
	end
end

local function redirect(planes)
	--look(
end

local function getdist(o, d, p, n)
	local nr = dot(n, o - p)
	local dn = dot(d, n)
	if dn < 0 then
		return nr + dn
	else
		return nr
	end
	--[[if dot(d, n) < 0 then
		return dot(n, o + d - p)
	else
		return dot(d, o - p)
	end]]
end


















local collider = {}

local function choose(option, default)
	if option ~= nil then
		return option
	else
		return default
	end
end

local function split(n, v)
	local d = dot(n, v)/dot(n, n)
	local p = v - d*n
	return d, p
end

local function badn(n)
	return n ~= n
end

local function badv3(v)
	return v.x ~= v.x or v.y ~= v.y or v.z ~= v.z
end

local newray = Ray.new
local function raycast(o, d, ignore, blackfunc)
	local n0 = #ignore
	local n1 = n0
	local function recurse(part, pos, ...)
		if part and (not part.CanCollide or blackfunc and blackfunc(part)) then
			n1 = n1 + 1
			ignore[n1] = part
			return recurse(workspace:FindPartOnRayWithIgnoreList(newray(pos, d - (pos - o)), ignore))
		end
		return part, pos, ...
	end
	local r0, r1, r2, r3, r4, r5 = recurse(workspace:FindPartOnRayWithIgnoreList(newray(o, d), ignore))
	for i = n0 + 1, n1 do
		ignore[i] = nil
	end
	return r0, r1, r2, r3, r4, r5
end

--[[uses -y as the direction]]
local function castCylinder(basis, ignore, blackfunc, scale, r2, l)
	local n = 0
	local parts = {}
	local poses = {}
	local norms = {}

	local m = scale/r2^0.5
	local h = 2*(r2/3)^0.5
	h = h - h%-1

	for i = -h, h do
		for j = -h, h do
			if i*i - i*j + j*j <= r2 then
				local x = i - j/2
				local z = 3^0.5/2*j
				local o = ptws(basis, v3(m*x, 0, m*z))
				local d = vtws(basis, v3(0, -l, 0))
				local part, pos, norm = raycast(o, d, ignore, blackfunc)
				if part then
					n = n + 1
					parts[n] = part
					poses[n] = pos
					norms[n] = norm
				end
			end
		end
	end
	return parts, poses, norms, n
end

local function castFeet(basis, ignore, blackfunc, scale, r2, l)
	local parts, points, norms = castCylinder(basis, ignore, blackfunc, scale, r2, l)
	local n, p = resolvePlane(points, basis)
	if #parts == 0 then
		return false
	else
		return true, n, p, #points
	end
end

function collider.new(options)
	local self = {}
	
	self.up = choose(options.up, v3(0, 1, 0))
	
	self.radius = choose(options.radius, 1)
	self.length = choose(options.length, v3(0, -2.5, 0))--1
	
	self.goallength = choose(options.goallength, self.length)
	self.goalradius = choose(options.goalradius, self.radius)

	self.position = choose(options.position, v3(0, 50, 0))
	self.velocity = choose(options.velocity, v3(0, 0, 0))
	self.acceleration = choose(options.acceleration, v3(0, -32, 0))

	self.ignore = choose(options.ignore, {})
	self.minrate = choose(options.minrate, 60)
	self.maxrate = choose(options.maxrate, 1/0)
	--self.maxincline = choose(options.maxincline, 3)

	self.standheight = choose(options.standheight, 6)--5
	self.standtarget = choose(options.standtarget, 5)--4
	self.standaccel = choose(options.standaccel, 200)

	self.walkspeed = choose(options.walkspeed, 16)
	self.jumpheight = choose(options.jumpheight, 3)
	self.walkunit = choose(options.walkunit, v3(0, 0, 0))
	self.walkaccel = choose(options.walkaccel, 200)
	self.airaccel = choose(options.airaccel, self.walkaccel/4)
	self.climbaccel = choose(options.climbaccel, self.walkaccel/2)
	self.climbdist = choose(options.climbdist, 2*self.radius)
	self.climbspeed = choose(options.climbspeed, self.walkspeed*2/3)
	self.speedhop = choose(options.speedhop, false)

	self.climbing = choose(options.climbing, false)
	self.standing = choose(options.standing, false)
	self.falling = choose(options.falling, false)
	self.feetpos = self.standtarget*self.length.unit
	
	self.climbable = choose(options.climbable, function(part)
		return part:FindFirstAncestor("Ladder")--part.Name == "Ladder"
	end)
	
	function self.jump(h)
		--I fucked this function up pretty bad but whatever
		if self.climbing then
			self.climbing = false
		else
			local planes = getpushplanes(self.radius + self.climbdist, self.position, self.length, self.ignore, self.climbable)
			local poses = planes.poses
			if #planes.poses == 0 then
				if not self.falling and not self.climbing then
					self.falling = true
			
					local up = self.up
					local g = dot(up, self.acceleration)
					if g < 0 then
						local v = dot(up, self.velocity)
						local j = (-2*g*(h or self.jumpheight))^0.5
						local f = v < 0 and j or (v*v + j*j)^0.5
						self.velocity = self.velocity + (f - v)*up
					end
					return true
				end
			else
				self.climbing = true--temporary arbitrary
			end
		end
	end
	
	function self.trysizechange(maxpush, changes)
		local radius = choose(changes.radius, self.radius)
		local length = choose(changes.length, self.length)
		local ignore = choose(changes.ignore, self.ignore)
		local position = choose(changes.position, self.position)
		local planes = getpushplanes(radius + maxpush, position, length, ignore)
		local newpos, norma, normb, normc, unsolved = solve(planes.poses, planes.norms, radius, position, length)
		local delta = newpos - position
		if unsolved or maxpush < delta.magnitude then
			return false
		else
			return true
		end
	end
	
	--local lastwalkmag = 1
	local lastgoodpos
	local laststandpos = self.position
	
	--for making shit jitter less
	--probably tremove in the future
	local trackedposition0 = self.position
	local trackedposition1 = self.position
	local trackedposition2 = self.position
	
	local trackedtick0 = tick() - 2/60
	local trackedtick1 = tick() - 1/60
	local trackedtick2 = tick()

	local lastt = tick()
	function self.update()
		--debug.profilebegin("capsule")
		local nextt = tick()
		--local targetdt = 1/self.minrate--lastt and nextt - lastt or 1/60--whatever broooooo
		local n = self.minrate*(nextt - lastt)
		if n < 1 then
			n = 1
		else
			n = n + 1/2
			n = n - n%1
		end
		local dt = (nextt - lastt)/n
		for i = 1, n do
			local pos0 = self.position
			local up = self.up

			local newpos
			local newvel
				
			local basis = makeBasis(pos0, up)
			local groundpart, groundpos, groundnorm, count = castFeet(basis, self.ignore, self.climbable, 3^0.5/2*self.radius, 7, self.standheight)
			
			if groundpart then
				laststandpos = self.position
			end
			
			if not groundpart then--this is approximate
				groundpart, groundpos, groundnorm = raycast(pos0 - self.standtarget*up, -dt*self.velocity - dt*dt/2*self.acceleration, self.ignore)
			end
			
			if groundpart then
				if not self.standing then
					self.climbing = false
				end
				self.standing = true
			else
				self.standing = false
			end
			
			if self.climbing then
				local planes = getpushplanes(self.radius + self.climbdist, self.position, self.length, self.ignore, self.climbable)
				local poses = planes.poses
				local norms = planes.norms
				local bestdist = self.climbdist + self.radius
				local besti
				for i = 1, #norms do
					--get closest one I guess
					local dist = getdist(self.position, self.length, poses[i], norms[i])
					if dist < bestdist then
						bestdist = dist
						besti = i
					end
				end
				--print(bestdist - self.radius - self.climbdist)
				if not besti then
					self.climbing = false
				else
					local ppos = poses[besti]
					local norm = norms[besti]
					
					local climbunit = look(up, norm)*self.walkunit
					local tangtarg = self.climbspeed*climbunit
	
					--local upacc, sideacc = split(norm, self.acceleration)
					local normvel, tangvel = split(norm, self.velocity)
					local normpos, tangpos = split(norm, self.position)

					local h0 = dot(norm, pos0 - ppos)
					local v0 = normvel
					local h1, v1 = pushsolve(h0, v0, self.climbaccel, self.radius, dt)
					normpos = normpos + h1 - h0
					normvel = normvel + v1 - v0
					
					local tangacc
					
					do
						local accel = self.climbaccel
						local d = tangtarg - tangvel
						local dmag = d.magnitude
						if dt*accel < dmag then
							tangacc = accel/dmag*d
						else
							tangacc = d/dt
						end
					end

					tangpos = tangpos + dt*tangvel + dt*dt/2*tangacc
					tangvel = tangvel + dt*tangacc

					newpos = tangpos + normpos*norm
					newvel = tangvel + normvel*norm

					self.feetcenter = -(self.standtarget*up + self.radius*norm)
				end
				--if there's no closest one, then no climbing, do normal walk operation
				--if there is a closest one, then do look(up, norm)*walkunit to determine movement direction along ladder
				--a = climbunit*climbspeed
				--p = p + dt*v + dt/2*a
				--v = v + dt*a
				
				--continue to solver
			end
			
			if not self.climbing then
				--all of the walk code to be moved in here
	
				local upacc, sideacc = split(up, self.acceleration)
				local upvel, sidevel = split(up, self.velocity)
				local uppos, sidepos = split(up, self.position)
				local walkaccel = self.walkaccel
				local uptarg, sidetarg
		
				if self.standing then
					--self.standing = true
					local truewalkunit do
						local nu = dot(groundnorm, up)
						if self.walkunit.magnitude < 1e-6 or nu < 1e-6 then
							--truewalkunit = nv
							uptarg, sidetarg = split(up, nv)
						else
							local nw = dot(groundnorm, self.walkunit)
							local t = -nw/nu
							truewalkunit = self.walkunit.magnitude*(self.walkunit + t*up).unit
							uptarg, sidetarg = split(up, self.walkspeed*truewalkunit)
							walkaccel = self.walkaccel*sidetarg.magnitude/self.walkspeed
						end
					end
					--print(walkaccel)
		
					local h0 = dot(up, pos0 - groundpos)
					local v0 = upvel
					
					if self.falling then
						local p0 = h0
						local p1 = self.standtarget
						local a0 = upacc
						local a1 = self.standaccel
						if v0 < 0 then
							if p0 < p1 then
								self.falling = false
								upvel = 0
								v0 = 0
							else
								local i2 = a1*(a1 - a0)*(2*a0*(p1 - p0) + v0*v0)
								local t = -v0/a0 - i2^0.5/((a1 - a0)*a0)
								if t < 0 then
									self.falling = false
									upvel = -(2*a1*(p0 - p1))^0.5
									v0 = upvel
								elseif t < dt then
									self.falling = false
								end
							end
						else
							if p0 - v0*v0/(2*upacc) < p1 then
								self.falling = false
							end
						end
					end

					if not self.falling then
						local h1, v1 = pushsolve(h0, v0, self.standaccel, self.standtarget, dt)-- v0 - uptarg--springsolve(16, 1, h0, v0, self.standtarget, dt)--
						v1 = v1
						uppos = uppos + h1 - h0
						upvel = upvel + v1 - v0
					end
					
					self.feetcenter = groundpos - pos0--uppos - dot(up, groundpos)
				else
					uptarg, sidetarg = split(up, self.walkspeed*self.walkunit)
					--self.standing = false
					self.falling = true
					self.feetcenter = -self.standtarget*up
				end
		
				if self.falling then
					uppos = uppos + dt*upvel + dt*dt/2*upacc
					upvel = upvel + dt*upacc
				end
		
				sidepos = sidepos + dt*sidevel + dt*dt/2*sideacc
				sidevel = sidevel + dt*sideacc
		
				do
					if self.standing then
						local accel = walkaccel
						local d = sidetarg - sidevel
						local dmag = d.magnitude
						if dt*accel < dmag then
							sidevel = sidevel + dt*accel/dmag*d
						else
							sidevel = sidetarg
						end
					else
						local accel = self.airaccel
						
						if self.speedhop then
							local d = sidetarg
							local dmag = d.magnitude
							--if 1e-8 < dmag then
								sidevel = sidevel + dt*accel/dmag*d
							--[[else
								local d = -sidevel
								local dmag = d.magnitude
								if dt*accel < dmag then
									sidevel = sidevel + dt*accel/dmag*d
								else
									sidevel = sidetarg
								end
							end]]
						else
						--if 1e-8 < sidetarg.magnitude then
							local d = sidetarg - sidevel
							local dmag = d.magnitude
							if dt*accel < dmag then
								sidevel = sidevel + dt*accel/dmag*d
							else
								sidevel = sidetarg
							end
						--end
						end
					end
				end
		
				newpos = uppos*up + sidepos
				newvel = upvel*up + sidevel
			end
	
			local dpos = newpos - pos0

			local planes = getpushplanes(self.radius + dpos.magnitude, newpos, self.length, self.ignore)
			local newpos, norma, normb, normc = solve(planes.poses, planes.norms, self.radius, newpos, self.length)
			local newvel = vsolve({norma, normb, normc}, newvel)

			if badv3(newpos) then
				print("badpos")
				newpos = lastgoodpos
				newvel = nv
			else
				lastgoodpos = newpos
			end

			if self.radius ~= self.goalradius or self.length ~= self.goallength then
				--print(self.goalradius, newpos, self.goallength, self.ignore)
				local planes = getpushplanes(self.goalradius, newpos, self.goallength, self.ignore)
				local testpos, norma, normb, normc, unsolved = solve(planes.poses, planes.norms, self.goalradius, newpos, self.goallength)
				local testvel = vsolve({norma, normb, normc}, newvel)
				local delta = testpos - newpos
				if not unsolved and delta.magnitude < 1/10 then
					newpos = testpos
					newvel = testvel
					self.radius = self.goalradius
					self.length = self.goallength
				end
			end
			
			if newpos.y < workspace.FallenPartsDestroyHeight then
				print("fallen")
				newpos = laststandpos
				newvel = nv
			end
			
			do
				if self.position == trackedposition2 then
					trackedposition0 = trackedposition1
					trackedposition1 = trackedposition2
				else
					trackedposition0 = newpos
					trackedposition1 = newpos
				end
				trackedposition2 = newpos
					
				trackedtick0 = trackedtick1
				trackedtick1 = trackedtick2
				trackedtick2 = lastt + i*dt
			
				local p0 = trackedposition0
				local p1 = trackedposition1
				local p2 = trackedposition2
				local t0 = trackedtick0
				local t1 = trackedtick1
				local t2 = trackedtick2
				
				self.observedvelocity = (p2 - p1)/(t2 - t1)
				self.observedacceleration = 2*(p2*(t0 - t1) + p0*(t1 - t2) + p1*(t2 - t0))/((t0 - t1)*(t0 - t2)*(t1 - t2))
			end

			self.position = newpos
			self.velocity = newvel
		end
		lastt = nextt
		--debug.profileend()
	end

	return self
end

return collider