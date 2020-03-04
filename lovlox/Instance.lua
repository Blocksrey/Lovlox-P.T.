local Object = require("lovlox/Object")

local meta = {}
meta.__index = meta

local Instance = {}

function Instance.new(type, parent)
	return require("lovlox/Objects/"..type).new()
end

return Instance