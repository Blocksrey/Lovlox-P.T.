local signal = require("lovlox/type/RBXScriptSignal")
local object = require("lovlox/object")

local instance = {}

function instance.new(type, parent)
	local obj = require("lovlox/classes/"..type).new()

	if parent and parent.AddChild then
		parent:AddChild(obj)
	end

	return obj
end

return instance