local Object  = require("lovlox/Object")
local world   = require("lovlox/world")
local Vector3 = require("lovlox/Vector3")
local CFrame  = require("lovlox/CFrame")

local part = {}

function part.new()
	local props = {}

	props.ClassName  = "Part"
	props.Anchored   = false
	props.CanCollide = true
	props.CFrame     = CFrame.new()
	props.Size       = Vector3.new(2, 1, 4)
	props.Color      = Color3.new(0, 0, 0)
	
	local self = Object.new(props)
	
	world.newpart(self)
	
	return self
end

return part