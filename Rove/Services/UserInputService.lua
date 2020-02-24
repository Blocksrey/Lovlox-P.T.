local game   = require("Rove/Game")
local Signal = require("Rove/Signal")

local meta = {}
meta.__index = meta

function meta.IsKeyDown(inputserv, keyCode)
	return love.keyboard.isDown(keyCode)
end

local service = {}

game.UserInputService = service

service.InputBegan   = Signal.new()
service.InputChanged = Signal.new()
service.InputEnded   = Signal.new()

setmetatable(service, meta)
