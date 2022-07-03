local event = require("event")
local enet  = require("enet")

local network = {}

network.connect    = event(network, "onconnect")
network.disconnect = event(network, "ondisconnect")
network.receive    = event(network, "onreceive")

local host

function network.init(inittype)
	if inittype == "client" then
		host = enet.host_create()
		host:connect("my.blocks.rocks:27182")
		return host
	elseif inittype == "server" then
		host = enet.host_create("*:27182")
		return host
	end
end

function network.update()
	local event = host:service(50/3)
	while event do
		local type = event.type
		local func = network[type]
		if func then
			func(event)
		end
		event = host:service()
	end
end

return network