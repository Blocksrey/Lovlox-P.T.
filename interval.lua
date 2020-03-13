local interval = {}

function interval.new(table)
	local self = {}
	
	--variables
	self.t = table.t or 0
	self.v = table.v or 0
	
	--constants
	self.i = table.i or 0
	self.f = table.f or function() end
	
	return self
end

function interval.update(self, t1)
	--variables
	local t0 = self.t
	local v0 = self.v
	
	--constants
	local i = self.i
	local f = self.f
	
	local td = t1 - t0
	local v1 = v0 - td
	
	if v1 <= 0 then
		while true do
			f(t0 + v1)
			v1 = v1 + i
			if v1 > 0 then
				break
			end
		end
	end
	
	--output
	self.t = t1
	self.v = v1
end

return interval