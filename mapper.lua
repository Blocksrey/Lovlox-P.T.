--used for storing data while being able to iterate with a numerical index.
--should be fast i guess idk

local meta   = {}
local mapper = {}

function meta.__index(self, index)
	
end

function mapper.new()
	local self = {}

	return setmetatable(self, meta)
end

return mapper