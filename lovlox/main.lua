--global scope stuff
game     = require("lovlox/game")
Vector3  = require("lovlox/Vector3")
Color3   = require("lovlox/Color3")
CFrame   = require("lovlox/CFrame")
Instance = require("lovlox/Instance")
Enum     = require("lovlox/Enum")

--service instances
require("lovlox/Services/ReplicatedFirst")
require("lovlox/Services/RunService")
require("lovlox/Services/UserInputService")

require("lovlox/Service")

--enumerators
require("lovlox/Enums/KeyCode")
require("lovlox/Enums/Material")
require("lovlox/Enums/PartType")
require("lovlox/Enums/SurfaceType")

local vec3   = require("algebra/vec3")
local object = require("object")

local rove = {}

function rove.update(t1)
end

function rove.render(meshes)
	--print(game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A))
	--table.remove(meshes)
	--table.insert(meshes, object.newbox(vec3.new(1 - 2*math.random(), 1 - 2*math.random(), 1 - 2*math.random()), vec3.new(4, 4, 4)))
	--meshes[1].setpos(vec3.new(0, math.cos(love.timer.getTime()), 0))
end

return rove