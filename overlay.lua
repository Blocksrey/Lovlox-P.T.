--contains functionality for event handling
local Signal   = require("lovlox/type/RBXScriptSignal")

--main module
local overlay = {}

--event handlers
overlay.statechanged = Signal.new()
overlay.setenabled = overlay.statechanged

--the function that draws overlay stuff
local function drawoverlay()
	love.graphics.print(
		"fps: "..love.timer.getFPS()
		--"\ndebanding enabled: "..wut..
		--"\nssshadows enabled: "..shadow
		--"\nlight distance scaler: "..yoooo
		--select(2, lights[1].getdrawdata())[1]
	)
end

--handle user input
love.keypressed:Connect(function(key)
	if key == "h" then
		overlay.toggle()
	end
end)

--one of the many connections that is fired by love.draw
local drawcon

--returns if changing the state was successul
local function tryenable()
	if not drawcon then
		drawcon = love.draw:Connect(drawoverlay)
		return true
	else
		return false
	end
end

--same thing as above
local function trydisable()
	if drawcon then
		drawcon:Disconnect()
		drawcon = nil
		return true
	else
		return false
	end
end

--toggle returns the state that it has been changed to
function overlay.toggle()
	return tryenable() or trydisable() and false
end

--statechanging handler
overlay.statechanged:Connect(function(state)
	if state then
		tryenable()
	else
		trydisable()
	end
end)

--return module
return overlay