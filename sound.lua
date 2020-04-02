local vec3 = require("algebra/vec3")

local sound = {}

function sound.new(prop)
	prop = prop or {}

	local self = {}

	self.source   = prop.source--need this xD
	self.position = prop.position or vec3.null
	self.effect   = prop.effect

	return self
end

function sound.delete(self)
	self.source:stop()
	if love.audio.getEffect(tostring(self)) then
		love.audio.setEffect(tostring(self), false)
	end
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