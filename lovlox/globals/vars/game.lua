local object = require("lovlox/object")

local gamemeta = object.getinheritedmeta()

function gamemeta.RemoveDefaultLoadingScreen()
	print("RemoveDefaultLoadingScreen()")
end

function gamemeta.GetService(self, name)
	local service = self[name]
	if service then
		print("obtain service: "..name)
		return service
	else
		print("no Service: "..name)
	end
end

local game = object.new(nil, gamemeta)

return game