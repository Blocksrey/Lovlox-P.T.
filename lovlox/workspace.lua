local game = require("lovlox/game")

local meta = {}
meta.__index = meta

function meta.FindPartOnRayWithIgnoreList(ray, ignore)
	return
end

function meta.FindPartsInRegion3WithIgnoreList(region, ignore)
	return {}
end

local workspace = setmetatable({}, meta)

workspace.FallenPartsDestroyHeight = -500

game.workspace = workspace
game.Workspace = workspace

return workspace