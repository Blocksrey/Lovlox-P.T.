local game     = require("lovlox/globals/vars/game")
local object   = require("lovlox/object")
local Instance = require("lovlox/types/Instance")
local CFrame   = require("lovlox/types/CFrame")

--workspacemeta
local workspaceprops = object.getinheritedprops()
local workspacemeta  = object.getinheritedmeta()

workspaceprops.FallenPartsDestroyHeight = -500

local p = Instance.new("Part", game)

function workspacemeta.FindPartOnRayWithIgnoreList(ray, ignore)
	return
end

function workspacemeta.FindPartsInRegion3WithIgnoreList(region, ignore)
	return {
		p
	}
end

--workspace
local workspace = object.new(workspaceprops, workspacemeta)
game.workspace = workspace
game.Workspace = workspace

--camera
local cameraprops = object.getinheritedprops()
local camerameta  = object.getinheritedmeta()
cameraprops.Name = "CurrentCamera"
cameraprops.CFrame = CFrame.new()
local camera = object.new(cameraprops, camerameta)
workspace:AddChild(camera)

return workspace