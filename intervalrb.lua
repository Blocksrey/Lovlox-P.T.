

local interval = {}

function interval.new(table)
	local self = {}
	
	self.t = table.t or 0
	self.c = table.c or self.t
	
	self.i = table.i or 1--safe
	self.f = table.f or function() end
	
	return self
end

function interval.update(self, t1)
	local t0 = self.t
	local c0 = self.c
	local i  = self.i
	
	local dt = t1 - t0
	
	local c1 = c0
	while c1 < t1 - i do
		self.f(c1)
		c1 = c1 + i
	end
	
	self.t = t1
	self.c = c1
end

return interval