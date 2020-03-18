local signal = require("lovlox/types/RBXScriptSignal")

local insert = table.insert
local remove = table.remove

local hierarchy = {}
local lookup = {}

local function getinheritedprops()
	local props = {}

	props.Archivable               = true
	props.Changed                  = signal.new()
	props.ClassName                = "UndefinedClass"
	props.Name                     = "UndefinedName"
	props.Parent                   = nil

	local listeners = {}

	function props.GetPropertyChangedSignal(prop)
		listeners[prop] = signal.new()
		return listeners[prop]
	end

	return props
end

local function getinheritedmeta()
	local meta = {}
	meta.__index = meta

	function meta.FindFirstChild(self, name)
		local children = self:GetChildren()
		for i = 1, #children do
			local child = children[i]
			if child.Name == name then
				return child
			end
		end
	end

	function meta.FindFirstAncestor()
		
	end

	function meta.__index(self, index)
		return meta[index] or lookup[self][index] or self:FindFirstChild(index)
	end

	function meta.__newindex(self, index, value)
		local last = lookup[self][index]
		if last ~= value then
			lookup[self][index] = value
			lookup[self].Changed(index)
		end
	end

	function meta.__tostring(self)
		return self.Name
	end

	function meta.Destroy(self)
		local children = self.Parent:GetChildren()
		for i = 1, #children do
			if children[i] == self then
				remove(children, i)
			end
		end
	end

	function meta.ClearAllChildren(self)
		local children = self:GetChildren()
		for i = 1, #children do
			children[i]:Destroy()
		end
	end

	function meta.GetChildren(self)
		return hierarchy[self]
	end

	function meta.Clone(self)
		return self
	end

	function meta.AddChild(self, child)
		insert(hierarchy[self], child)
	end

	return meta
end

local object = {}

--kinda hacky but i need to do it for __newindex stuff to work properly
function object.new(props, meta)
	props = props or getinheritedprops()
	meta  = meta  or getinheritedmeta()

	local hash = {}
	
	lookup[hash] = props
	hierarchy[hash] = {}
	
	setmetatable(hash, meta)

	return hash
end

object.getinheritedprops = getinheritedprops
object.getinheritedmeta  = getinheritedmeta

return object