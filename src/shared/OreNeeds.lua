-- Które rudy są jeszcze potrzebne: te, których wymagają kolejne poziomy fabryki.
-- Kopalnia pojawia tylko potrzebne rudy (gdy fabryka ma max poziom, pojawiają się wszystkie).
local FactoryLevels = require(script.Parent.Config.FactoryLevels)

local OreNeeds = {}

function OreNeeds.needed(factoryLevel: number)
	local needed = {}
	for level = factoryLevel + 1, #FactoryLevels do
		for oreId in FactoryLevels[level].cost do
			needed[oreId] = true
		end
	end
	return needed
end

-- Lista rud, które mogą się pojawić w kopalni.
function OreNeeds.spawnable(ores, mineLevel: number, factoryLevel: number)
	local needed = OreNeeds.needed(factoryLevel)
	local unlocked, useful = {}, {}
	for _, ore in ores do
		if ore.minMineLevel <= mineLevel then
			table.insert(unlocked, ore)
			if needed[ore.id] then
				table.insert(useful, ore)
			end
		end
	end
	return #useful > 0 and useful or unlocked
end

return OreNeeds
