-- Pisklaki: wykluwasz je za jajka 🥚, trenujesz w obozie na działce i wysyłasz na wojnę.
-- weight : szansa przy wykluciu (szczęście z fabryki zwiększa szanse rzadszych)
-- power  : siła na poziomie 1; każdy kolejny poziom dodaje powerPerLevel
local Chicks = {}

Chicks.hatchPrice = 25 -- 🥚 za jedno wyklucie
Chicks.maxChicks = 12
Chicks.maxLevel = 25
Chicks.powerPerLevel = 0.15 -- +15% siły bazowej za poziom

Chicks.types = {
	{ id = "yellow", name = "Żółty pisklak", weight = 60, power = 10, color = Color3.fromRGB(255, 225, 70), scale = 1 },
	{ id = "brown", name = "Brązowy kogucik", weight = 25, power = 18, color = Color3.fromRGB(165, 105, 55), scale = 1.1 },
	{ id = "ninja", name = "Pisklak ninja", weight = 10, power = 32, color = Color3.fromRGB(45, 45, 55), scale = 1.15 },
	{ id = "knight", name = "Pisklak rycerz", weight = 4, power = 55, color = Color3.fromRGB(190, 195, 210), scale = 1.3 },
	{ id = "dragon", name = "Smoczy pisklak", weight = 1, power = 100, color = Color3.fromRGB(230, 60, 60), scale = 1.5 },
}

Chicks.byId = {}
for _, chickType in Chicks.types do
	Chicks.byId[chickType.id] = chickType
end

-- Ile XP potrzeba, żeby wejść z poziomu `level` na następny.
function Chicks.xpToNext(level: number): number
	return math.floor(20 * level ^ 1.4)
end

function Chicks.power(chick): number
	local chickType = Chicks.byId[chick.type]
	if not chickType then
		return 0
	end
	return math.floor(chickType.power * (1 + (chick.level - 1) * Chicks.powerPerLevel))
end

-- Losowanie rodzaju pisklaka; luck (1..1.6) mnoży wagi rzadszych rodzajów.
function Chicks.roll(luck: number, rng: Random)
	local total = 0
	local weights = {}
	for i, chickType in Chicks.types do
		local weight = i == 1 and chickType.weight or chickType.weight * luck
		weights[i] = weight
		total += weight
	end
	local pick = rng:NextNumber(0, total)
	for i, chickType in Chicks.types do
		pick -= weights[i]
		if pick <= 0 then
			return chickType
		end
	end
	return Chicks.types[1]
end

-- Obóz treningowy: slots = ile pisklaków trenuje naraz, xp = XP co trainTick sekund.
Chicks.trainTick = 5
Chicks.camp = {
	{ slots = 2, xp = 1, price = 0 },
	{ slots = 3, xp = 1.5, price = 15000 },
	{ slots = 4, xp = 2, price = 60000 },
	{ slots = 5, xp = 3, price = 200000 },
	{ slots = 6, xp = 4, price = 700000 },
	{ slots = 8, xp = 6, price = 2500000 },
}

Chicks.war = {
	cooldown = 120, -- sekundy między wyprawami
	travelTime = 12, -- marsz armii do celu (w tym czasie sojusznicy mogą dołączyć)
	stealPercent = 0.10, -- najwyżej tyle gotówki obrońcy zabiera wygrana; łup dzielony po równo między napastników
	victimShield = 600, -- po przegranej gracz jest chroniony przed kolejnym atakiem (s)
	allyHelp = 0.5, -- sojusznicy obrońcy pomagają połową siły swoich pisklaków
	injuredTime = 90, -- po przegranej pisklaki leczą się i nie walczą / nie trenują
	winXp = 15, -- XP dla każdego pisklaka z wygranej wyprawy
	homeFactor = 0.8, -- pisklaki w domu bronią z tą częścią siły
	minDefense = 15, -- najsłabsza możliwa obrona działki
	-- Siła każdej postawionej budowli obronnej przy obronie przed armią.
	defensePower = { mine = 8, trap = 6, cannon = 30, wizard = 45 },
	-- Dzikie obozy do ćwiczeń (zawsze dostępne, nawet gdy jesteś sam na serwerze).
	bandits = {
		{ name = "Obóz szczurów", icon = "🐀", power = 40, cash = 2000, eggs = 20 },
		{ name = "Kurnik lisów", icon = "🦊", power = 150, cash = 15000, eggs = 60 },
		{ name = "Twierdza wilków", icon = "🐺", power = 500, cash = 120000, eggs = 200 },
		{ name = "Zamek smoka", icon = "🐉", power = 1500, cash = 1000000, eggs = 600 },
	},
}

-- Szansa wygranej: przewaga siły się liczy, ale słabszy też ma szansę.
function Chicks.winChance(attack: number, defense: number): number
	local a, d = attack ^ 1.5, math.max(defense, 1) ^ 1.5
	return math.clamp(a / (a + d), 0.05, 0.95)
end

return Chicks
