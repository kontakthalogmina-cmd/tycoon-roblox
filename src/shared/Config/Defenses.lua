-- Obrona działki: budowle stawiane na stałych miejscach działki, kupowane za $.
-- Atakują każdego obcego gracza, który wejdzie na działkę (także napastników w czasie napadu).
-- price      : cena pierwszej sztuki; każda kolejna jest droższa o priceGrowth
-- max        : ile sztuk można postawić (tyle jest miejsc na działce)
-- range      : zasięg wykrywania (studs)
-- cooldown   : sekundy między strzałami / ponownym uzbrojeniem
-- damage     : obrażenia; knockback/upward/duration: przewrócenie trafionego
local Defenses = {}

Defenses.list = {
	{ id = "mine", name = "Mina", icon = "💣", price = 3000, priceGrowth = 1.5, max = 8,
		range = 4.5, cooldown = 8, damage = 35, knockback = 45, upward = 55, duration = 2,
		description = "Wybucha, gdy obcy na nią wejdzie. Wyrzuca go w powietrze." },
	{ id = "trap", name = "Niewidzialna pułapka", icon = "🕸️", price = 6000, priceGrowth = 1.5, max = 6,
		range = 4, cooldown = 10, damage = 10, knockback = 0, upward = 0, duration = 3.5,
		description = "Widzisz ją tylko Ty. Unieruchamia obcego na kilka sekund." },
	{ id = "cannon", name = "Działo", icon = "💥", price = 25000, priceGrowth = 1.6, max = 4,
		range = 50, cooldown = 3, damage = 25, knockback = 70, upward = 40, duration = 1.8,
		description = "Strzela kulami w obcych na działce i mocno ich odrzuca." },
	{ id = "wizard", name = "Wieża czarodzieja", icon = "🔮", price = 60000, priceGrowth = 1.7, max = 3,
		range = 45, cooldown = 1.5, damage = 12, knockback = 15, upward = 10, duration = 0.6,
		description = "Szybkie magiczne pociski. Najlepsza ochrona przed napastnikami." },
}

Defenses.byId = {}
for _, defense in Defenses.list do
	Defenses.byId[defense.id] = defense
end

-- Cena kolejnej sztuki, gdy gracz ma już `owned` sztuk.
function Defenses.price(defense, owned: number): number
	return math.floor(defense.price * defense.priceGrowth ^ owned)
end

-- Miejsca na budowle w układzie działki (x, z).
Defenses.slots = {
	mine = {
		Vector3.new(-55, 0, 82), Vector3.new(-55, 0, 94), Vector3.new(-55, 0, 106), Vector3.new(-55, 0, 118),
		Vector3.new(-10, 0, -50), Vector3.new(-10, 0, -62), Vector3.new(-4, 0, 8), Vector3.new(-16, 0, 8),
	},
	trap = {
		Vector3.new(-51, 0, 88), Vector3.new(-59, 0, 100), Vector3.new(-51, 0, 112),
		Vector3.new(-7, 0, -44), Vector3.new(-13, 0, -56), Vector3.new(0, 0, 24),
	},
	cannon = {
		Vector3.new(-76, 0, 52), Vector3.new(-34, 0, 76), Vector3.new(-76, 0, -20), Vector3.new(30, 0, -52),
	},
	wizard = {
		Vector3.new(-30, 0, 92), Vector3.new(-82, 0, 84), Vector3.new(22, 0, -8),
	},
}

return Defenses
