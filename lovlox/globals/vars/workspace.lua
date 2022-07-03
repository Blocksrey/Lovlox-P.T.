local game     = require("lovlox/globals/vars/game")
local object   = require("lovlox/object")
local Instance = require("lovlox/type/Instance")
local CFrame   = require("lovlox/type/CFrame")
local Vector3  = require("lovlox/type/Vector3")
local Signal   = require("lovlox/type/RBXScriptSignal")

--workspacemeta
local workspaceprops = object.getinheritedprops()
local workspacemeta  = object.getinheritedmeta()

workspaceprops.bodies = {}
workspaceprops.bodyadded = Signal.new()

function workspacemeta.newbody(self, part)
	local index = #self.bodies + 1
	self.bodies[index] = part
	self.bodyadded(part)
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



workspaceprops.FallenPartsDestroyHeight = -500

function workspacemeta.FindPartsInRegion3WithIgnoreList(self, region, ignore)
	return self.bodies
end

function workspacemeta.FindPartOnRayWithIgnoreList(self, ray, ignore)
	--return self.bodies[1], Vector3.new(0, 0, 0), Vector3.new(0, 1, 0)
end

--workspace
local workspace = object.new(workspaceprops, workspacemeta)
game.workspace = workspace
game.Workspace = workspace

--[[
workspace.bodyadded:Connect(function(part)
	table.insert(rectoids, rectoidfrompart(part))
end)
]]

--camera
local cameraprops = object.getinheritedprops()
local camerameta  = object.getinheritedmeta()
cameraprops.Name = "CurrentCamera"
cameraprops.CFrame = CFrame.new()
local camera = object.new(cameraprops, camerameta)
workspace:AddChild(camera)



return workspace