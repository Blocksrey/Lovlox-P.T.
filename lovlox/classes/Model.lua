local object = require("lovlox/object")

local model = {}

function model.new()
	local props = object.getinheritedprops()

	props.Name      = "Model"
	props.ClassName = "Model"

	local self = object.new(props)

	return self
end

return model