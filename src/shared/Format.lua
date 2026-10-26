local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.number(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local i = 1
	local value = n
	while value >= 1000 and i < #SUFFIXES do
		value /= 1000
		i += 1
	end
	return string.format("%.1f%s", value, SUFFIXES[i])
end

function Format.money(n: number): string
	return "$" .. Format.number(n)
end

return Format
