local flashsounds = {
	love.audio.newSource("audio/flashlight1.wav", "static"),
	love.audio.newSource("audio/flashlight2.wav", "static"),
	love.audio.newSource("audio/flashlight3.wav", "static"),
	love.audio.newSource("audio/flashlight4.wav", "static"),
}

for i = 1, #flashsounds do
	flashsounds[i]:setPosition(1/2, -1, 3/2)
	flashsounds[i]:setEffect("reverb")
	flashsounds[i]:setVolume(2/3)
end

local flashlight = {}

function flashlight.press(self)
	if self.pressed then
		return false
	else
		self.pressed = true
		if self.enabled then
			flashsounds[3]:play()
		else
			flashsounds[1]:play()
		end
		return true
	end
end

function flashlight.release(self)
	if self.pressed then
		self.pressed = false
		if self.enabled then
			flashsounds[4]:play()
			self.enabled = false
		else
			flashsounds[2]:play()
			self.enabled = true
		end
		return true
	else
		return false
	end
end

function flashlight.new(prop)
	local self = {}

	self.pressed = prop.pressed or false
	self.enabled = prop.enabled or false

	return self
end

return flashlight