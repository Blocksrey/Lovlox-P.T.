local Color3 = {}

function Color3.new(r, g, b)
	local self = {}

	self.r = r
	self.g = g
	self.b = b

	return self
end

function Color3.hsv(h, s, v)
end

return Color3