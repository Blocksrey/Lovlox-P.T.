local bit = {}

local byte = string.byte
local char = string.char
local concat = table.concat

local function comp48(n)
	local c0 = n%256 n = (n - c0)/256
	local c1 = n%256 n = (n - c1)/256
	local c2 = n%256 n = (n - c2)/256
	local c3 = n%256 n = (n - c3)/256
	local c4 = n%256 n = (n - c4)/256
	local c5 = n%256 n = (n - c5)/256
	return char(c0, c1, c2, c3, c4, c5)
end

local function decomp48(d, i)
	local c0, c1, c2, c3, c4, c5 = byte(d, 6*i - 5, 6*i)
	return c0*2^0 + c1*2^8
		+ c2*2^16 + c3*2^24
		+ c4*2^32 + c5*2^40
end

function bit.newbitwriter()
	local ndat = 0
	local dat = {}
	local ncache = 0
	local cache = 0
	local function write(nvalue, value)
		while 48 <= ncache + nvalue do
			local nrem = 48 - ncache
			local mod = 2^nrem
			local rem = value%mod
			ndat = ndat + 1
			dat[ndat] = comp48(cache + rem*2^ncache)
			ncache = 0
			cache = 0
			nvalue = nvalue - nrem
			value = (value - rem)/mod
		end
		cache = cache + value*2^ncache
		ncache = ncache + nvalue
	end
	local function finalize()
		dat[ndat + 1] = comp48(cache)
		return concat(dat)
	end
	return write, finalize
end

function bit.newbitreader(dat)
	local ndat = 0
	local ncache = 0
	local cache = 0
	local function read(bits)
		local nvalue = 0
		local value = 0
		while ncache + nvalue < bits do
			value = value + cache*2^nvalue
			nvalue = nvalue + ncache
			ndat = ndat + 1
			cache = decomp48(dat, ndat)
			ncache = 48
		end
		local nrem = bits - nvalue
		local mod = 2^nrem
		local rem = cache%mod
		ncache = ncache - nrem
		cache = (cache - rem)/mod
		value = value + rem*2^nvalue
		return value
	end
	return read
end

return bit