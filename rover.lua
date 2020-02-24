require("Rove/Main")

function _G.load(name)
	local find = require("Game/client/"..name)
	if find then
		print("load: "..name)
		return find
	else
		print("no find: "..name)
		return nil
	end
end

require("Game/client/thebow")
