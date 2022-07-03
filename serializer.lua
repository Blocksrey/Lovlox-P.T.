local bitwriter = require("bitwriter")

local serializer = {}

local byte = string.byte
local char = string.char
local concat = table.concat
local frexp = math.frexp
local type = type
local tostring = tostring
local nan = tostring(0/0)

function serializer.serialize(data)
	local write, finalize = bitwriter.newbitwriter()
	local nrefs = 0
	local refs = {}
	local function encode(data)
		local ref = refs[data]
		if ref then
			write(3, 0)
			local fr, exp = frexp(ref)
			write(5, exp)
			write(exp, ref)
			return
		end
		local datatype = type(data)
		if datatype == "boolean" then
			write(3, 1)
			if data then
				write(1, 1)
			else
				write(1, 0)
			end
		elseif datatype == "number" then
			if data%1 == 0 and -2^31 < data and data < 2^31 then
				write(3, 2)
				local fr, exp = frexp(data)
				write(5, exp)
				if data < 0 then
					write(1, 1)
					write(exp, -data)
				else
					write(1, 0)
					write(exp, data)
				end
			else
				write(3, 3)
				if data == data then
					local pos
					if data < 0 then
						write(1, 1)
						pos = -data
					else
						write(1, 0)
						pos = data
					end
					if pos == 1/0 then
						write(11, 2047)
						write(52, 0)
					elseif pos < 2^-1022 then
						write(11, 0)
						write(52, pos*2^1022*2^52)
					else
						local fr, exp = frexp(pos)
						write(11, exp + 1022)
						write(52, 2^52*(2*fr - 1))
					end
				else
					write(1, 0)
					write(11, 2047)
					if tostring(data) == nan then
						write(52, 1)--ind
					else
						write(52, 2)--qnan
					end
				end
			end
		elseif datatype == "string" then
			nrefs = nrefs + 1
			refs[data] = nrefs
			write(3, 4)
			local len = #data
			if 2^31 <= len then
				print("string must be less than 2 gigabytes. Sorry! :(")
			end
			local fr, exp = frexp(len)
			write(5, exp)
			write(exp, len)
			for i = 1, len do
				local c = byte(data, i)
				write(8, c)
			end
		elseif datatype == "table" then
			nrefs = nrefs + 1
			refs[data] = nrefs
			write(3, 5)
			local numi = 0
			while data[numi + 1] do
				numi = numi + 1
			end
			local numk = -numi
			for k in next, data do
				numk = numk + 1
			end
			local fri, expi = frexp(numi)
			local frk, expk = frexp(numk)
			write(5, expi)
			write(expi, numi)
			write(5, expk)
			write(expk, numk)
			for i = 1, numi do
				encode(data[i])
			end
			for i, v in next, data do
				if type(i) ~= "number" or i%1 ~= 0 or i < 1 or numi < i then
					encode(i)
					encode(v)
				end
			end
		else
			--encode(tostring(data))--why the motherfucking hell does this work so well?
			--print("unknown datatype. sorry :( "..type(data).." "..tostring(data))
		end
	end
	encode(data)
	local final = finalize()
	return final
end

function serializer.deserialize(bin)
	local read = bitwriter.newbitreader(bin)
	local nrefs = 0
	local refs = {}
	local function decode()
		local datatype = read(3)
		if datatype == 0 then
			local exp = read(5)
			local ref = read(exp)
			return refs[ref]
		elseif datatype == 1 then
			local raw = read(1)
			return raw == 1
		elseif datatype == 2 then
			local exp = read(5)
			local sign = read(1)
			local mag = read(exp)
			if sign == 0 then
				return mag
			else
				return -mag
			end
		elseif datatype == 3 then
			local sign = read(1)
			local pow = read(11)
			local coef = read(52)
			local smul
			if sign == 0 then
				smul = 1
			else
				smul = -1
			end
			if pow == 2047 then
				if coef == 0 then
					return smul/0
				elseif coef == 1 then
					return 0/0
				else
					return -(0/0)
				end
			elseif pow == 0 then
				return smul*coef*2^-1074
			else
				return smul*(coef/2^52 + 1)*2^(pow - 1023)
			end
		elseif datatype == 4 then
			local exp = read(5)
			local len = read(exp)
			local chars = {}
			for i = 1, len do
				chars[i] = char(read(8))
			end
			local str = concat(chars)
			nrefs = nrefs + 1
			refs[nrefs] = str
			return str
		elseif datatype == 5 then
			local expi = read(5)
			local numi = read(expi)
			local expk = read(5)
			local numk = read(expk)
			local tab = {}
			nrefs = nrefs + 1
			refs[nrefs] = tab
			for i = 1, numi do
				tab[i] = decode()
			end
			for i = 1, numk do
				tab[decode()] = decode()
			end
			return tab
		else
			print("unknown datatype. sorry :(")
		end
	end
	local final = decode()
	return final
end

return serializer