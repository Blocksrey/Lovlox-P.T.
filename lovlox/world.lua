local Signal = require("lovlox/Signal")




local ptree = {}

local function cubetouch()
end

local function add()
end

local function search()
end







local world = {}

world.parts = {}

world.partadded = Signal.new()

function world.newpart(part)
	local index = #world.parts + 1
	world.parts[index] = part
	world.partadded(part)
	return part
end

return world