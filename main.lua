require("lovlox/main")

io.stdout:setvbuf("no")

local lovlox  = require("lovlox/Main")
local mat3    = require("algebra/mat3")
local vec3    = require("algebra/vec3")
local quat    = require("algebra/quat")
local rand    = require("random")
local light   = require("light")
local object  = require("object")
local Signal  = require("lovlox/Signal")

--load in the geometry shader and compositing shader
local geomshader   = love.graphics.newShader("shaders/geom_frag.glsl", "shaders/geom_vert.glsl")
local lightshader  = love.graphics.newShader("shaders/light_frag.glsl", "shaders/light_vert.glsl")
local compshader   = love.graphics.newShader("shaders/comp_frag.glsl")
local debandshader = love.graphics.newShader("shaders/deband_frag.glsl")
--local vhsshader    = love.graphics.newShader("shaders/vhs_frag.glsl", "shaders/vhs_vert.glsl")

--make signals
love.mousefocus = Signal.new()
love.focus      = Signal.new()
love.keypressed = Signal.new()
love.wheelmoved = Signal.new()
love.mousemoved = Signal.new()
love.update     = Signal.new()
love.draw       = Signal.new()
love.resize     = Signal.new()

local overlay = require("overlay")

local randomsampler = rand.newsampler(256, 256, rand.triangular4)

--make the buffers
local geombuffer
local compbuffer
local function makebuffers()
	local w, h = love.graphics.getDimensions()

	local depths = love.graphics.newCanvas(w, h, {format = "depth24";})
	local wverts = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local wnorms = love.graphics.newCanvas(w, h, {format = "rgba32f";})
	local colors = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	depths:setFilter("nearest", "nearest")
	wverts:setFilter("nearest", "nearest")
	wnorms:setFilter("nearest", "nearest")
	colors:setFilter("nearest", "nearest")

	geombuffer = {
		depthstencil = depths;
		wverts,
		wnorms,
		colors,
	}

	local composite = love.graphics.newCanvas(w, h, {format = "rgba32f";})

	composite:setFilter("nearest", "nearest")

	compbuffer = {
		depthstencil = depths;
		composite,
	}
end

makebuffers()
love.resize:Connect(makebuffers)

local mousefocused = false
local focused      = false


love.mousefocus:Connect(function(f)
	mousefocused = f
end)

love.focus:Connect(function(f)
	focused = f
end)

love.window.setMode(800, 600, {resizable = true; fullscreen = false;})

--this will allow us to compute the frustum transformation matrix once,
--then send it off to the gpu
--ratio of the screen plane (screen width / screen height)
--height of the screen plane (1 = 90 degree fov)
--near clipping plane distance (positive)
--far clipping plane distance (positive)
--pos (vec3 camera position)
--rot (mat3 camera rotation)
--returns a 4x4 transformation matrix to be passed to the vertex shader
local function getfrusT(ratio, height, near, far, pos, rot)
	local px, py, pz = pos.x, pos.y, pos.z
	local xx, yx, zx, xy, yy, zy, xz, yz, zz =	rot.xx, rot.yx, rot.zx,
												rot.xy, rot.yy, rot.zy,
												rot.xz, rot.yz, rot.zz
	local xmul = 1/ratio
	local ymul = 1/height
	local zmul = (far + near)/(far - near)
	local zoff = (2*far*near)/(far - near)
	local rx = px*xx + py*xy + pz*xz
	local ry = px*yx + py*yy + pz*yz
	local rz = px*zx + py*zy + pz*zz
	return {
		xmul*xx, xmul*xy, xmul*xz, -xmul*rx,
		ymul*yx, ymul*yy, ymul*yz, -ymul*ry,
		zmul*zx, zmul*zy, zmul*zz, -zmul*rz - zoff,
		zx,      zy,      zz,      -rz
	}
end


local newtet = object.newtetrahedron
local newbox = object.newbox
local newsphere = object.newsphere
local newlight = light.new

--for the sake of my battery life
--love.window.setVSync(false)

local animtex = love.graphics.newImage("woah.png")

local wut = 1
local shadow = 0
local function drawmeshes(height, near, far, pos, rot, meshes, lights)
	local w, h = love.graphics.getDimensions()
	local frusT = getfrusT(w/h, height, near, far, pos, rot)
	love.graphics.push("all")
	love.graphics.reset()

	--PREPARE FOR GEOMETRY
	love.graphics.setWireframe(wut == 0)
	--love.graphics.setBlendMode("replace")
	love.graphics.setMeshCullMode("back")
	love.graphics.setDepthMode("less", true)
	love.graphics.setCanvas(geombuffer)
	love.graphics.setShader(geomshader)
	love.graphics.clear()

	--RENDER GEOMETRY
	geomshader:send("frusT", frusT)
	for i = 1, #meshes do
		local mesh, vertT, normT = meshes[i].getdrawdata()
		geomshader:send("vertT", vertT)
		geomshader:send("normT", normT)
		love.graphics.draw(mesh)
	end

	--PREPARE FOR LIGHTING
	love.graphics.reset()
	love.graphics.setBlendMode("add")
	love.graphics.setMeshCullMode("front")
	love.graphics.setDepthMode("greater", false)
	love.graphics.setShader(lightshader)
	love.graphics.setCanvas(compbuffer)
	love.graphics.clear(0, 0, 0, 1, false, false)

	--RENDER LIGHTING
	lightshader:send("screendim", {w, h})
	lightshader:send("frusT", frusT)
	lightshader:send("wverts", geombuffer[1])
	lightshader:send("wnorms", geombuffer[2])
	lightshader:send("colors", geombuffer[3])
	lightshader:send("shadow", shadow)
	for i = 1, #lights do
		local mesh, vertT, color = lights[i].getdrawdata()
		lightshader:send("vertT", vertT)
		lightshader:send("lightcolor", color)
		love.graphics.draw(mesh)
	end

	---[[
	love.graphics.reset()--just to make sure
	love.graphics.setShader(debandshader)
	do
		local image, size, offset = randomsampler.getdrawdata()
		debandshader:send("randomimage", image)
		debandshader:send("randomsize", size)
		debandshader:send("randomoffset", offset)
	end
	debandshader:send("screendim", {w, h})
	debandshader:send("finalcanvas", compbuffer[1])
	love.graphics.setCanvas()
	--love.graphics.setShader()
	love.graphics.draw(compbuffer[1])--just straight up color
	--]]

	love.graphics.pop()
end











local meshes = {}
local lights = {}

local near = 1/10
local far = 5000
local pos = vec3.new(0, 0, 0)
local angy = 0
local angx = 0
local sens = 1/256
local speed = 8

love.keypressed:Connect(function(k)
	if k == "escape" then
		love.event.quit()
	elseif k == "r" then
		wut = 1 - wut
	elseif k == "t" then
		shadow = 1 - shadow
	elseif k == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
		love.resize()
	elseif k == "printscreen" then
		love.graphics.captureScreenshot(os.time()..".png")
	end
end)

local yoooo = -48
love.wheelmoved:Connect(function(x, y)
	if y > 0 then
		yoooo = yoooo - 1
	elseif y < 0 then
		yoooo = yoooo + 1
	end
	for i = 1, #lights do
		lights[i].setalpha(2^(yoooo/8))
	end
end)

local function clamp(p, a, b)
	return p < a and a or p > b and b or p
end

local pi = math.pi

love.mousemoved:Connect(function(px, py, dx, dy)
	angy = angy + sens*dx
	angx = angx + sens*dy
	angx = clamp(angx, -pi/2, pi/2)
end)

love.update:Connect(function(dt)
	love.mouse.setRelativeMode(focused and mousefocused)
	
	local mul = speed
	if love.keyboard.isDown("lshift") then
		mul = 8*mul
	end
	if love.keyboard.isDown("lctrl") then
		mul = mul/8
	end

	local rot = mat3.fromeuleryxz(angy, angx, 0)

	local keyd = love.keyboard.isDown("d") and 1 or 0
	local keya = love.keyboard.isDown("a") and 1 or 0
	local keye = love.keyboard.isDown("e") and 1 or 0
	local keyq = love.keyboard.isDown("q") and 1 or 0
	local keyw = love.keyboard.isDown("w") and 1 or 0
	local keys = love.keyboard.isDown("s") and 1 or 0

	local vel = rot*vec3.new(keyd - keya, keye - keyq, keyw - keys):unit()
	pos = pos + dt*mul*vel
end)

local testmodel = require("models/pt")

local function robloxparttomesh(robloxpart)
	local position    = robloxpart[1]
	local orientation = robloxpart[2]
	local size        = robloxpart[3]
	local color       = robloxpart[4]
	local shape       = robloxpart[5]
	if shape == "Ball" then
		local mesh = object.newsphere(color.x, color.y, color.z)
		mesh.setpos(position)
		mesh.setrot(orientation)
		mesh.setscale(size/2)
		return mesh
	else
		local mesh = object.newbox(color.x, color.y, color.z)
		mesh.setpos(position)
		mesh.setrot(orientation)
		mesh.setscale(size/2)
		return mesh
	end
end

local function robloxwedgetomesh(robloxwedgepart)
	local position    = robloxwedgepart[1]
	local orientation = robloxwedgepart[2]
	local size        = robloxwedgepart[3]
	local color       = robloxwedgepart[4]
	local mesh = object.newwedge(color.x, color.y, color.z)
	mesh.setpos(position)
	mesh.setrot(orientation)
	mesh.setscale(size/2)
	return mesh
end

--parts
for index = 1, #testmodel.Part do
	meshes[#meshes + 1] = robloxparttomesh(testmodel.Part[index])
end
--wedgeparts
for index = 1, #testmodel.WedgePart do
	meshes[#meshes + 1] = robloxwedgetomesh(testmodel.WedgePart[index])
end
--meshparts
for index = 1, #testmodel.MeshPart do
	meshes[#meshes + 1] = robloxparttomesh(testmodel.MeshPart[index])
end

--local randomoffset = {}
for i = 1, 32 do
	lights[i] = newlight()
	lights[i].setpos(vec3.new(
		(math.random() - 1/2)*64,
		(math.random())*25,
		(math.random() - 1/2)*64
	))
	--randomoffset[i] = 5*vec3.new(random.unit3())
	lights[i].setcolor(vec3.new(
		math.random()*10,
		math.random()*10,
		math.random()*10
	))
	lights[i].setalpha(1/64)
end












--[[

--main_rigidbody
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

--modules
local rigidbody = require("rigidbody")
local interval  = require("interval")

--localized
local v3       = Vector3.new
local cf       = CFrame.new
local instance = Instance.new

--stuff
local part      = instance("Part", workspace)
part.Anchored   = true
part.CanCollide = false

local px, py, pz = 0, 0, 0
local sx, sy, sz = 2, 1, 4
local mass       = 1

local function rectmoment(px, py, pz, sx, sy, sz, m)
	return cf(
		0, 0, 0,
		 m*(py*py + pz*pz + 1/12*(sy*sy + sz*sz)),
		-m* py*px,
		-m* pz*px,
		-m* px*py,
		 m*(pz*pz + px*px + 1/12*(sz*sz + sx*sx)),
		-m* pz*py,
		-m* px*pz,
		-m* py*pz,
		 m*(px*px + py*py + 1/12*(sx*sx + sy*sy))
  )
end

local rigidbody0 = rigidbody.new({
	t     = tick();
	x     = v3(0, 4, 0);
	omega = v3(2, 0.1, -0.1);
	m     = mass;
	I     = rectmoment(px, py, pz, sx, sy, sz, mass);
})

local function updatephysics(t)
	rigidbody.update(rigidbody0, t)	
end

--sub-frame physics stepping (for accuracy)
local physicsinterval = interval.new({
	t = tick();
	i = 2^-10;
	f = updatephysics;
})

local head = game:GetService("Players").LocalPlayer.Character:WaitForChild("Head")

game:GetService("RunService").RenderStepped:Connect(function()
	local t1 = tick()
	--sub-frame update
	interval.update(physicsinterval, t1)
	--current frame update
	rigidbody.update(rigidbody0, t1)
	--render
	part.Size   = v3(sx, sy, sz)
	part.CFrame = rigidbody0.o*cf(px, py, pz) + rigidbody0.x
end)

return nil


]]

local world = require("lovlox/world")

local function parserobloxinstance(part)
	local m = part.CFrame
	local s = part.Size
	local c = part.Color

	local px, py, pz, xx, yx, zx, xy, yy, zy, xz, yz, zz = m:components()
	local sx, sy, sz = s.x, s.y, s.z
	local cr, cg, cb = c.r, c.g, c.b

	--print()
	--print(px, py, pz)
	--print(sx, sy, sz)
	--print(xx, yx, zx, xy, yy, zy, xz, yz, zz)
	--print(cr, cg, cb)

	return blocktomesh({
		vec3.new(px, py, pz);
		mat3.new(xx, yx, zx, xy, yy, zy, xz, yz, zz);
		vec3.new(sx, sy, sz);
		vec3.new(cr, cg, cb);
	})
end

local function handlenewrobloxinstance(instance)
	local index = #meshes + 1
	meshes[index] = parserobloxinstance(instance)
	instance.Changed:Connect(function()
		meshes[index] = parserobloxinstance(instance)
	end)
end

--world.partadded:Connect(handlenewrobloxinstance)

for index, value in next, world.parts do
	--handlenewrobloxinstance(value)
end




local lastt = love.timer.getTime()

love.draw:Connect(function()
	lovlox.render(meshes)

	local t = love.timer.getTime()--tick()
	local dt = t - lastt
	local rot = mat3.fromeuleryxz(angy, angx, 0)

	for i = 1, 1 do
		local tpos = pos + rot*vec3.new(1/2, -1, 3/2)
		local lpos = lights[i].getpos()
		local dpos = lpos - tpos
		lights[i].setpos(tpos + 0.01^dt*dpos)
		lights[i].setcolor(vec3.new(5, 5, 5))
	end

	for index, value in next, world.parts do
		value.CFrame = CFrame.new(math.sin(os.clock()), math.cos(os.clock()*3), 0)*CFrame.Angles(os.clock(), 1/4*os.clock(), -3/8*os.clock())
	end

	drawmeshes(1, near, far, pos, rot, meshes, lights)

	lastt = t
end)