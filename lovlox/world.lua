local Signal = require("lovlox/Signal")

local world = {}

world.parts = {}

world.partadded = Signal.new()

function world.newpart(part)
	local index = #world.parts + 1
	world.parts[index] = part
	world.partadded(world.parts[index])
	return world.parts[index]
end

return world