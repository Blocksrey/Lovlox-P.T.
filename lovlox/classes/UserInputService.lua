local game = require("lovlox/globals/vars/game")
local Signal = require("lovlox/types/RBXScriptSignal")

local meta = {}
meta.__index = meta

function meta.IsKeyDown(inputserv, keyCode)
	return love.keyboard.isDown(keyCode)
end

local service = {}

service.InputBegan   = Signal.new()
service.InputChanged = Signal.new()
service.InputEnded   = Signal.new()

game.UserInputService = service

setmetatable(service, meta)

return service