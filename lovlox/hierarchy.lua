local Signal = require("lovlox/Signal")

local insert = table.insert
local remove = table.remove

local lookup   = {}
local Instancemeta = {}
Instancemeta.__index = Instancemeta

function Instancemeta.__index(self, index)
	return Instancemeta[index] or lookup[self][index]
end

function Instancemeta.__newindex(self, index, value)
	local last = lookup[self][index]
	if last ~= value then
		lookup[self][index] = value
		lookup[self].Changed(index)
	end
end

function Instancemeta.__tostring(self)
	return self.Name
end

function Instancemeta.Destroy(self)
	local parent = self.Parent
	local children = parent:GetChildren()
	for i = 1, #children do
		if children[i] == self then
			remove(children, i)
		end
	end
end

function Instancemeta.ClearAllChildren(self)
	local children = self:GetChildren()
	for i = 1, #children do
		children[i]:Destroy()
	end
end

function Instancemeta.GetChildren(self)
	return self.children
end

function Instancemeta.Clone(self)
	return self
end

function Instancemeta.AddChild(self, child)
	insert(self.children, child)
end

local Instance = {}

--kinda hacky but i need to do it for __newindex stuff to work properly
function Instance.new(type, Parent)
	local self = {}

	self.Name      = type
	self.ClassName = type
	self.Changed   = Signal.new()
	self.Parent    = Parent
	self.children  = {}

	--[[
	for index, value in next, props or {} do
		lookup[self][index] = value
		--print(index)
	end
	--]]

	local hash = {}
	lookup[hash] = self

	setmetatable(hash, Instancemeta)

	if Parent then
		Parent:AddChild(hash)
	end

	return hash
end

local game = Instance.new("game")
local workspace = Instance.new("workspace", game)
local part = Instance.new("Part", workspace)

print(workspace:GetChildren()[1])
part:Destroy()
print(workspace:GetChildren()[1])