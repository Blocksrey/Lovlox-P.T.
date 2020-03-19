local vec3 = require("algebra/vec3")

--print(vec3.null*vec3.new(0, 0, 0))

local sound = {}

function sound.new(prop)
	prop = prop or {}

	local self = {}

	self.source   = prop.source--need this xD
	self.position = prop.position or vec3.null
	self.effect   = prop.effect

	return self
end

function sound.update(self, campos, camori)
	local px, py, pz = self.position:dump()
	self.source:setPosition(px, py, -pz)
	if self.effect then
		love.audio.setEffect(tostring(self), self.effect)
		self.source:setEffect(tostring(self))
	end
end

return sound