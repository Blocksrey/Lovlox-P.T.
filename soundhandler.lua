local insert = table.insert
local remove = table.remove

local sound = require("sound")

local soundhandler = {}

function soundhandler.new(prop)
	prop = prop or {}

	local self = {}

	self.sounds = prop.sounds or {}

	return self
end

function soundhandler.add(self, soundprop)
	local cursound = sound.new(soundprop)
	insert(self.sounds, cursound)
	return cursound
end

function soundhandler.remove(self, sound)
	for i = 1, #self.sounds do
		if self.sounds[i] == sound then
			remove(self.sounds, i)
		end
	end
end

function soundhandler.update(self, campos, camori)
	local px, py, pz = campos:dump()
	local xx, yx, zx, xy, yy, zy, xz, yz, zz = camori:dump()
	love.audio.setPosition(px, py, -pz)
	love.audio.setOrientation(-xz, -yz, -zz, xy, yy, zy)

	for i = 1, #self.sounds do
		local cursound = self.sounds[i]
		sound.update(cursound)
	end
end

return soundhandler