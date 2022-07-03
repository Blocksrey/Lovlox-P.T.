local signal = require("lovlox/type/RBXScriptSignal")
local game   = require("lovlox/globals/vars/game")

local runservice = {}

runservice.RenderStepped = signal.new()

game.RunService = runservice
