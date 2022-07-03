io.stdout:setvbuf("no")

--functions
local cos  = math.cos
local sin  = math.sin
local acos = math.acos

--constants
local pi = 3.14159265359
local E  = 2.71828182846

--make signals
local Signal       = require("lovlox/type/RBXScriptSignal")
love.mousefocus    = Signal.new()
love.focus         = Signal.new()
love.keypressed    = Signal.new()
love.wheelmoved    = Signal.new()
love.mousemoved    = Signal.new()
love.update        = Signal.new()
love.draw          = Signal.new()
love.resize        = Signal.new()
love.mousepressed  = Signal.new()
love.mousereleased = Signal.new()

--modules main
local lovlox       = require("lovlox/main")
local mat3         = require("algebra/mat3")
local vec3         = require("algebra/vec3")
local quat         = require("algebra/quat")
local rand         = require("random")
local light        = require("light")
local lovemesh     = require("lovemesh")
local collider     = require("collider")
local bouncer      = require("bouncer")
local acoustics    = require("acoustics")
local overlay      = require("overlay")
local random       = require("random")
local interval     = require("interval")
local testmodel    = require("models/pt")
local workspace    = require("lovlox/globals/vars/workspace")
local flashlight   = require("flashlight")
local soundhandler = require("soundhandler")

--load in the geometry shader and compositing shader
local geomshader   = love.graphics.newShader("shaders/geom_frag.glsl", "shaders/geom_vert.glsl")
local lightshader  = love.graphics.newShader("shaders/light_frag.glsl", "shaders/light_vert.glsl")
local compshader   = love.graphics.newShader("shaders/comp_frag.glsl")
local debandshader = love.graphics.newShader("shaders/deband_frag.glsl")


--make the buffers
local geombuffer
local compbuffer
local function makebuffers()
	local w, h = love.graphics.getDimensions()

	local depths = love.graphics.newCanvas(w, h, {format = "depth24"})
	local wverts = love.graphics.newCanvas(w, h, {format = "rgba32f"})
	local wnorms = love.graphics.newCanvas(w, h, {format = "rgba8"})
	local colors = love.graphics.newCanvas(w, h, {format = "rgba8"})

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


local newtet = lovemesh.newtetrahedron
local newbox = lovemesh.newbox
local newsphere = lovemesh.newsphere
local newlight = light.new

local scaryvalue = 0

local randomsampler = rand.newsampler(256, 256, rand.triangular4)

local wut = 1
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
	debandshader:send("scary", scaryvalue)
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
local cameraposition    = vec3.new(-19, 7, -20)
local cameraorientation = mat3.identity
local rot = mat3.identity
local angy = 0
local angx = 0
local sens = 1/256
local speed = 8

love.keypressed:Connect(function(k)
	if k == "escape" then
		love.event.quit()
	elseif k == "r" then
		wut = 1 - wut
	elseif k == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
		love.resize()
	elseif k == "printscreen" then
		love.graphics.captureScreenshot(os.time()..".png")
	end
end)

--[[
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
]]

local function clamp(p, a, b)
	return p < a and a or p > b and b or p
end

local mousemovedcon = love.mousemoved:Connect(function(px, py, dx, dy)
	angy = angy + sens*dx
	angx = angx + sens*dy
	angx = clamp(angx, -pi/2, pi/2)
end)


local function robloxinstancetomesh(robloxpart)
	local position
	local orientation
	local size
	local color
	local shape

	if robloxpart.ClassName then
		local m = robloxpart.CFrame
		local s = robloxpart.Size
		local c = robloxpart.Color

		local px, py, pz, xx, yx, zx, xy, yy, zy, xz, yz, zz = m:components()
		local sx, sy, sz = s.x, s.y, s.z
		local cr, cg, cb = c.r, c.g, c.b

		if robloxpart.ClassName == "WedgePart" then
			position    = vec3.new(px, py, pz)
			orientation = mat3.new(xx, yx, zx, xy, yy, zy, xz, yz, zz)
			size        = vec3.new(sx, sy, sz)
			color       = vec3.new(cr, cg, cb)
			shape       = "WedgePart"
		else
			position    = vec3.new(px, py, pz)
			orientation = mat3.new(xx, yx, zx, xy, yy, zy, xz, yz, zz)
			size        = vec3.new(sx, sy, sz)
			color       = vec3.new(cr, cg, cb)
			shape       = robloxpart.Shape
		end
	else
		position    = robloxpart[1]
		orientation = robloxpart[2]
		size        = robloxpart[3]
		color       = robloxpart[4]
		shape       = robloxpart[5]
	end

	if shape == "Ball" then
		local mesh = lovemesh.newsphere(color.x, color.y, color.z)
		mesh.setpos(position)
		mesh.setrot(orientation)
		mesh.setscale(size/2)
		return mesh
	elseif shape == "WedgePart" then
		local mesh = lovemesh.newwedge(color.x, color.y, color.z)
		mesh.setpos(position)
		mesh.setrot(orientation)
		mesh.setscale(size/2)
		return mesh
	else
		local mesh = lovemesh.newbox(color.x, color.y, color.z)
		mesh.setpos(position)
		mesh.setrot(orientation)
		mesh.setscale(size/2)
		return mesh
	end
end

--parts
for index = 1, #testmodel.Part do
	meshes[#meshes + 1] = robloxinstancetomesh(testmodel.Part[index])
end
--wedgeparts
for index = 1, #testmodel.WedgePart do
	--meshes[#meshes + 1] = robloxinstancetomesh(testmodel.WedgePart[index])
end
--meshparts
for index = 1, #testmodel.MeshPart do
	--meshes[#meshes + 1] = robloxinstancetomesh(testmodel.MeshPart[index])
end

--lights
for index = 1, #testmodel.light do
	--lights[index] = newlight()
	--lights[index].setpos(testmodel.light[index][1])
	--lights[index].setalpha(1/256/testmodel.light[index][2]:magnitude()/testmodel.light[index][4])
	--lights[index].setcolor(10*testmodel.light[index][3])
end




local function springsphere(p0, p1, v, e, s, x)
	x = s*x
	p0, p1 = p0:unit(), p1:unit()
	local co = cos(x)
	local si = sin(x)
	local k = E^(x - x/e)
	local p01 = p0:dot(p1)
	local t = acos(p01 < 1 and p01 or 1)
	local o = t*p1:cross(p0):unit()
	return
		mat3.fromaxisangle(k*(o*co + v*si))*p1,
		k*(v*co - o*si)
end


local flashlightdirection = vec3.new(0, 0, 1)
local flashlightdirectionvelocity = vec3.null

local flashlightlight = newlight()
flashlightlight.setalpha(1/256)
flashlightlight.setcolor(vec3.new(4, 5, 6))
lights[#lights + 1] = flashlightlight



local function handlenewrobloxbody(instance)
	local index = #meshes + 1
	meshes[index] = robloxinstancetomesh(instance)
	instance.Changed:Connect(function()
		meshes[index] = robloxinstancetomesh(instance)
	end)
end

--handle current parts
for index, value in next, workspace.bodies do
	--print(value)
end
--now handle new parts
workspace.bodyadded:Connect(handlenewrobloxbody)









--[[
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

--modules
local rigidbody = require("rigidbody")
local intervalrb  = require("intervalrb")

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
	x     = v3(0, 0, 0);
	omega = v3(2, 0.1, -0.1);
	m     = mass;
	I     = rectmoment(px, py, pz, sx, sy, sz, mass);
})

local function updatephysics(t)
	rigidbody.update(rigidbody0, t)	
end

--sub-frame physics stepping (for accuracy)
local physicsinterval = intervalrb.new({
	t = tick();
	i = 2^-10;
	f = updatephysics;
})

local cframe = require("cframe")

game:GetService("RunService").RenderStepped:Connect(function(dt)
	local t1 = tick()
	--sub-frame update
	intervalrb.update(physicsinterval, t1)
	--current frame update
	rigidbody.update(rigidbody0, t1)
	--render
	part.Size   = v3(sx, sy, sz)
	part.CFrame = rigidbody0.o*cf(px, py, pz) + rigidbody0.x
end)
--]]









local function tabrand(table)
	return table[math.random(1, #table)]
end

love.audio.setEffect("forestreverb", acoustics.forestreverb)

local branchsources = {
	love.audio.newSource("audio/branch1.wav", "static");
	love.audio.newSource("audio/branch2.wav", "static");
	love.audio.newSource("audio/branch3.wav", "static");
	love.audio.newSource("audio/branch4.wav", "static");
	love.audio.newSource("audio/branch5.wav", "static");
	love.audio.newSource("audio/branch6.wav", "static");
	love.audio.newSource("audio/treefall1.wav", "static");
	love.audio.newSource("audio/treefall2.wav", "static");
	love.audio.newSource("audio/treefall3.wav", "static");
--	love.audio.newSource("audio/thinkdifferent.wav", "stream");
}

for i, v in next, branchsources do
	v:setEffect("forestreverb")
end

local function playbranch()
	local theta = 0.2*2*pi*(1/2 - math.random())
	local c = cos(theta)
	local s = sin(theta)
	local sound = tabrand(branchsources)
	sound:setPosition(64*s, 0, 64*c)
	sound:play()
end

love.keypressed:Connect(function(key)
	if key == "e" then
		playbranch()
	end
end)


local frametime = 0

local eyeheight        = 11/2 + 6
local mousecoefficient = 1/128









--reverb stuff
love.audio.setEffect("genericreverb", acoustics.genericreverb)

love.audio.setDistanceModel("exponent")

local doorcamanimtime = 0

local footstepsources = {
	love.audio.newSource("audio/wood_smart_1.mp3", "static");
	love.audio.newSource("audio/wood_smart_2.mp3", "static");
	love.audio.newSource("audio/wood_smart_3.mp3", "static");
	love.audio.newSource("audio/wood_smart_4.mp3", "static");
	love.audio.newSource("audio/wood_smart_5.mp3", "static");
}

for i = 1, #footstepsources do
	footstepsources[i]:setVolume(5)
	footstepsources[i]:setEffect("genericreverb")
	footstepsources[i]:setPosition(0, -eyeheight, 0)
end




local stepinterval = interval.new({i = 1/5*pi, v = 1/10*pi})
stepinterval.f = function(t)
	local source = tabrand(footstepsources)
	source:stop()
	source:play()
end



local function constantlerp(a, b, p)
	local o = b - a
	local d = o:magnitude()
	if p < d then
		return a + p*o:unit()
	else
		return b
	end
end

local function camanimcf(t, r, h, c)
	return c*vec3.new(0, 0, -1/128*pi*cos(5*t)^3), vec3.new(0, h - r, 0) + c*vec3.new(0, 1/16*sin(10*t), 0)
end

local function doorcamanim(t)
	local l = 2
	t = t < l and t or l
	local p = 1 - (l - t)/l
	return 4*p*(1 - p)*vec3.new(-(1 - p)/6*sin(2*p*pi), -1/32*sin(p*pi), -1/32*sin(3*p*pi)^3)
end

local redsource = love.audio.newSource("audio/red.mp3", "stream")
redsource:setLooping(true)
redsource:play()


local collider0 = collider.new({
	position = Vector3.new(-19, 2, -19);
	radius = 1;
	length = Vector3.new();
})

collider0.walkspeed = 5
love.keypressed:Connect(function(key)
	if key == "space" then
		collider0.jump()
	elseif key == "f" then
		collider0.walkspeed = collider0.walkspeed == 5 and 15 or 5
	end
end)

local function lininterp(a, b, t)
	local o = b - a
	local u = o < 0 and -1 or o > 0 and 1 or 0
	local d = (o*o)^(1/2)
	if t < d then
		return a + t*u
	else
		return b
	end
end











local rustle = {}

local rustlesources = {
	love.audio.newSource("audio/longsoft01.mp3", "static");
	love.audio.newSource("audio/longsoft02.mp3", "static");
	love.audio.newSource("audio/longsoft03.mp3", "static");
	love.audio.newSource("audio/longsoft04.mp3", "static");
	love.audio.newSource("audio/longsoft05.mp3", "static");
	love.audio.newSource("audio/longsoft06.mp3", "static");
	love.audio.newSource("audio/longsoft07.mp3", "static");
	love.audio.newSource("audio/longsoft08.mp3", "static");
	love.audio.newSource("audio/longsoft09.mp3", "static");
	love.audio.newSource("audio/longsoft10.mp3", "static");
}

for i = 1, #rustlesources do
	rustlesources[i]:setEffect("genericreverb")
end

local rustlerate
local rustleval           = 0
local rustlevolumerestart = 1/4
local rustlelastangx      = angx
local rustlelastangy      = angy
local rustlefromstart     = 1/4
local rustlefromend       = 1/4

local function rustlekeepgoingdesuka()
	local timepos = rustlecurrentsource:tell()
	return rustlecurrentsource:isPlaying() and timepos < rustlecurrentsource:getDuration() - rustlefromend and timepos > rustlefromstart
end

function rustle.update(dt)
	local dx = angx - rustlelastangx
	local dy = angy - rustlelastangy
	local dd = (dx*dx + dy*dy)^(1/2)
	if dd > 0 then
		rustlerate = 1
	else
		rustlerate = 2
	end
	rustleval = lininterp(rustleval, dd, rustlerate*dt)

	if rustlecurrentsource and not rustlekeepgoingdesuka() then
		rustlecurrentsource = nil
	end
	if not rustlecurrentsource then 
		rustlecurrentsource = tabrand(rustlesources)
		rustlecurrentsource:play()
		rustlecurrentsource:seek(rustlefromstart)
	end
	rustlecurrentsource:setVolume(10*(1 - (1 - rustleval)^2))

	rustlelastangy = angy
	rustlelastangx = angx
end












local noise = love.math.noise



local flashlight0 = flashlight.new({})

love.mousepressed:Connect(function(x, y, button)
	if button == 1 then
		local success = flashlight.press(flashlight0)
		if success then
			flashlightdirectionvelocity = flashlightdirectionvelocity + flashlightdirection:cross(cameraorientation*vec3.new(0, 1/16*(1 + math.random()), 0))
		end
	elseif button == 2 then
		doorcamanimtime = 0
	end
end)

love.mousereleased:Connect(function(x, y, button)
	if button == 1 then
		local success = flashlight.release(flashlight0)
		if success then
			flashlightdirectionvelocity = flashlightdirectionvelocity + flashlightdirection:cross(cameraorientation*vec3.new(0, -1/16*(1 + math.random()), 0))
		end
	end
end)


local p  = Instance.new("Part")
p.CFrame = CFrame.new(0, 0, 0)
p.Size   = Vector3.new(1000, 1, 1000)

local function vector3tovec3(v3)
	local x, y, z = v3.x, v3.y, v3.z
	return vec3.new(x, y, z)
end


local effects = {}


local soundhandler0 = soundhandler.new()

local sound0 = soundhandler.add(soundhandler0, {
	position = vec3.new(-9, 12, 32);
	source   = love.audio.newSource("audio/raininterior.wav", "stream");
	effect   = acoustics.genericreverb;
})
sound0.source:play()

local part = Instance.new("Part")
part.CFrame = CFrame.new(sound0.position:dump())

local updatecon = love.update:Connect(function(dt)
	lovlox.update(tick(), dt)

	love.mouse.setRelativeMode(focused and mousefocused)
	local keyd = love.keyboard.isDown("d") and 1 or 0
	local keya = love.keyboard.isDown("a") and 1 or 0
	local keyw = love.keyboard.isDown("w") and 1 or 0
	local keys = love.keyboard.isDown("s") and 1 or 0
	local inputvector = vec3.new(keyd - keya, 0, keyw - keys):unit()

	collider0.walkunit = Vector3.new((cameraorientation*inputvector):dump())
	collider0.update()

	doorcamanimtime = doorcamanimtime + dt
	local baseorientation = mat3.fromaxisangle(vec3.new(0, angy, 0))*mat3.fromaxisangle(vec3.new(angx, 0, 0))
	frametime = frametime + 1/5*dt*collider0.velocity.Magnitude
	local walkanimangle, walkanimoff = camanimcf(frametime, collider0.radius, eyeheight, collider0.velocity.Magnitude/collider0.walkspeed)
	cameraorientation = baseorientation*mat3.fromaxisangle(walkanimangle + doorcamanim(doorcamanimtime))*mat3.fromaxisangle(vec3.new(1/32*noise(1 - 1/7*tick() - 1, 1)^5, 1/32*noise(2 - 1/7*tick() - 1, 2)^5, 1/32*noise(3 - 1/7*tick() - 1, 3)^5))
	cameraposition = walkanimoff + vector3tovec3(collider0.position)
	
	local tardir = cameraorientation*mat3.fromaxisangle(vec3.new(1/8*noise(1/4*tick() - 1, 1)^3 + 1/24*cos(5*frametime + pi/6)^24, 1/8*noise(1/4*tick() - 2, 2)^3, 1/8*noise(1/4*tick() - 3, 3)^3))*vec3.new(0, 0, 1)
	flashlightdirection, flashlightdirectionvelocity = springsphere(flashlightdirection, tardir, flashlightdirectionvelocity, 0.55, 12, dt)
	if flashlight0.enabled then
		flashlightlight.setpos(cameraposition + cameraorientation*vec3.new(1/2, -1, 3/2))
	else
		flashlightlight.setpos(vec3.new(0, -10000, 0))
	end

	scaryvalue = lininterp(scaryvalue, collider0.walkspeed == 5 and 0 or 1, dt/2)
	redsource:setVolume(scaryvalue)

	--audio
	--rustle audio
	rustle.update(dt)
	--footstep audio
	interval.update(stepinterval, frametime)
	--audio engine
	soundhandler.update(soundhandler0, cameraposition, cameraorientation)
end)











local lastt = love.timer.getTime()

love.draw:Connect(function()
	lovlox.render(meshes)

	local t = love.timer.getTime()--tick()
	local dt = t - lastt

	--flashlight
	lightshader:send("lightdir", {flashlightdirection:dump()})

	drawmeshes(1, near, far, cameraposition, cameraorientation, meshes, lights)

	lastt = t
end)
































local insert = table.insert

local network    = require("network")
local serializer = require("serializer")

local function start(starttype)
	print(starttype)	

	local host = network.init(starttype)

	local peers = {}
	local positions = {}

	network.onconnect(function(event)
		print("connect:", event.peer)
		peers[event.peer] = true
	end)

	network.ondisconnect(function(event)
		print("disconnect:", event.peer)
		peers[event.peer] = nil
	end)

	--[[
	network.onreceive(function(event)
		local data = serializer.deserialize(event.data)
		positions[event.peer] = data
	end)
	]]

	local numpeers = 0

	---[[
	if starttype == "client" then
		love.update:Connect(function()
			numpeers = 0
			for peer, _ in next, peers do
				numpeers = numpeers + 1
				--peer:send(serializer.serialize(cameraposition))
				peer:send(serializer.serialize({cameraposition:dump()}))
				peer:send(serializer.serialize({cameraorientation:dump()}))
			end
		end)
	elseif starttype == "server" then
		mousemovedcon:Disconnect()
		updatecon:Disconnect()

		love.update:Connect(function(dt)
			lovlox.update(tick(), dt)

			love.mouse.setRelativeMode(focused and mousefocused)
			local keyd = love.keyboard.isDown("d") and 1 or 0
			local keya = love.keyboard.isDown("a") and 1 or 0
			local keyw = love.keyboard.isDown("w") and 1 or 0
			local keys = love.keyboard.isDown("s") and 1 or 0
			local inputvector = vec3.new(keyd - keya, 0, keyw - keys):unit()

			collider0.walkunit = Vector3.new((cameraorientation*inputvector):dump())
			collider0.update()

			doorcamanimtime = doorcamanimtime + dt
			local baseorientation = mat3.fromaxisangle(vec3.new(0, angy, 0))*mat3.fromaxisangle(vec3.new(angx, 0, 0))
			frametime = frametime + 1/5*dt*collider0.velocity.Magnitude
			local walkanimangle, walkanimoff = camanimcf(frametime, collider0.radius, eyeheight, collider0.velocity.Magnitude/collider0.walkspeed)
			--cameraorientation = baseorientation*mat3.fromaxisangle(walkanimangle + doorcamanim(doorcamanimtime))*mat3.fromaxisangle(vec3.new(1/32*noise(1 - 1/7*tick() - 1, 1)^5, 1/32*noise(2 - 1/7*tick() - 1, 2)^5, 1/32*noise(3 - 1/7*tick() - 1, 3)^5))
			--cameraposition = walkanimoff + vector3tovec3(collider0.position)


			local tardir = cameraorientation*mat3.fromaxisangle(vec3.new(1/8*noise(1/4*tick() - 1, 1)^3 + 1/24*cos(5*frametime + pi/6)^24, 1/8*noise(1/4*tick() - 2, 2)^3, 1/8*noise(1/4*tick() - 3, 3)^3))*vec3.new(0, 0, 1)
			flashlightdirection, flashlightdirectionvelocity = springsphere(flashlightdirection, tardir, flashlightdirectionvelocity, 0.55, 12, dt)
			if flashlight0.enabled then
				flashlightlight.setpos(cameraposition + cameraorientation*vec3.new(1/2, -1, 3/2))
			else
				flashlightlight.setpos(vec3.new(0, -10000, 0))
			end

			scaryvalue = lininterp(scaryvalue, collider0.walkspeed == 5 and 0 or 1, dt/2)
			redsource:setVolume(scaryvalue)

			--audio
			--rustle audio
			rustle.update(dt)
			--footstep audio
			interval.update(stepinterval, frametime)
			--audio engine
			soundhandler.update(soundhandler0, cameraposition, cameraorientation)
		end)

		network.onreceive(function(event)
			local data = serializer.deserialize(event.data)
			if #data == 3 then
				cameraposition = vec3.new(unpack(data))
			else
				cameraorientation = mat3.new(unpack(data))
			end
		end)
	end
	--]]

	love.update:Connect(network.update)
	--[[
	love.update:Connect(function()
		network.update()
		
		numpeers = 0
		for peer, _ in next, peers do
			numpeers = numpeers + 1
			peer:send(serializer.serialize({love.mouse.getPosition()}))
		end
	end)
	]]

	--[[
	love.draw:Connect(function()
		for i, v in next, positions do
			--love.graphics.rectangle("fill", v[1] - 32, v[2] - 32, 64, 64)
		end
		love.graphics.print(starttype)
		love.graphics.print(numpeers, 0, 16)
	end)
	]]
	
end

local fuckcon
fuckcon = love.keypressed:Connect(function(key)
	if key == "1" then
		start("client")
		fuckcon:Disconnect()
	elseif key == "2" then
		start("server")
		fuckcon:Disconnect()
	end
end)
