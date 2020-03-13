local clock = os.clock

local c0 = clock()

local function time()
	return clock() - c0
end

return time