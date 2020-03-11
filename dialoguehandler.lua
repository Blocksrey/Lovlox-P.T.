--functions
local insert   = table.insert
local instance = Instance.new
local ud2      = UDim2.new
local c3       = Color3.new

--services
local players = game:GetService("Players")

local playergui = players.LocalPlayer:WaitForChild("PlayerGui")

local screengui = instance("ScreenGui", playergui)

local canvas                  = instance("Frame", screengui)
canvas.Size                   = ud2(1, 0, 1, 36)
canvas.Position               = ud2(0, 0, 0, -36)
canvas.BackgroundTransparency = 1

local function dialoguehandler()
	local labels = {}
	local times  = {}
	local total  = 0
	
	local self = {}
	
	function self.new(text)
		local textlabel      = instance("TextLabel", canvas)
		textlabel.Text       = text
		textlabel.TextColor3 = c3(1, 1, 1)
		textlabel.TextSize   = 32
		textlabel.Font       = Enum.Font.SourceSansSemibold
		insert(labels, textlabel)
		insert(times, 1/4*#text)
		total = total + 1
		return textlabel
	end
	
	function self.step(dt)
		for index = 1, total do
			--variables
			local time0  = times[index]
			
			--constants
			local label = labels[index]
			label.Position = ud2(1/2, 0, 3/4 + 32*(index - 1), 0)
			
			local time1 = time0 - dt
			
			if time1 < 0 then
				label:Destroy()
				labels[index] = nil
				times[index]  = nil
				total = total - 1
			end
			
			times[index] = time1
		end
	end
	
	return self
end

return dialoguehandler