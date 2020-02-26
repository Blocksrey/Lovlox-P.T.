require("lovlox/main")

function _G.load(name)
	local find = require("game/"..name)
	if find then
		print("load: "..name)
		return find
	else
		print("no find: "..name)
		return nil
	end
end

require("game/main")
