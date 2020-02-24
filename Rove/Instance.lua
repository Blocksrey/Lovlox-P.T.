local meta = {}
meta.__index = meta

local Instance = {}

function Instance.new(type, parent)
	local self = require("Rove/Objects/"..type).new()
	return setmetatable(self, meta)
end

return Instance