--global scope stuff
game     = require("Rove/Game")
Vector3  = require("Rove/Vector3")
Color3   = require("Rove/Color3")
CFrame   = require("Rove/CFrame")
Instance = require("Rove/Instance")
Enum     = require("Rove/Enum")

--service instances
require("Rove/Services/ReplicatedFirst")
require("Rove/Services/RunService")
require("Rove/Services/UserInputService")

require("Rove/Service")

--enumerators
require("Rove/Enums/KeyCode")
require("Rove/Enums/Material")
require("Rove/Enums/PartType")
require("Rove/Enums/SurfaceType")

local vec3   = require("vec3")
local object = require("object")

local rove = {}

function rove.update(t1)
end

function rove.render(meshes)
	print(game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A))
	--table.remove(meshes)
	--table.insert(meshes, object.newbox(vec3.new(1 - 2*math.random(), 1 - 2*math.random(), 1 - 2*math.random()), vec3.new(4, 4, 4)))
	--meshes[1].setpos(vec3.new(0, math.cos(love.timer.getTime()), 0))
end

return rove