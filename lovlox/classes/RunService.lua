local signal = require("lovlox/types/RBXScriptSignal")
local game   = require("lovlox/globals/vars/game")

local runservice = {}

runservice.RenderStepped = signal.new()

game.RunService = runservice
