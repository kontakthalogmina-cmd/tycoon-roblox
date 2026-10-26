-- Szanse na rzadkości jajek przy danym szczęściu (wspólne dla serwera i klienta).
local EggRarities = require(script.Parent.Config.EggRarities)

local EggOdds = {}

local function weights(luck: number)
	local result, total = {}, 0
	for i, rarity in EggRarities do
		local w = rarity.weight * (i > 1 and luck or 1)
		result[i] = w
		total += w
	end
	return result, total
end

-- Zwraca listę prawdopodobieństw (0..1) w kolejności EggRarities.
function EggOdds.chances(luck: number)
	local w, total = weights(luck)
	for i, value in w do
		w[i] = value / total
	end
	return w
end

function EggOdds.roll(luck: number)
	local w, total = weights(luck)
	local roll = math.random() * total
	for i, value in w do
		roll -= value
		if roll <= 0 then
			return EggRarities[i], i
		end
	end
	return EggRarities[1], 1
end

return EggOdds
