-- Dekoracje bazy kupowane za $. Każda ma stałe miejsca na działce, więc baza zawsze wygląda porządnie.
-- price: cena każdej sztuki, max: ile miejsc jest na działce.
local Decorations = {}

Decorations.list = {
	{ id = "flowers", name = "Klomb z kwiatami", icon = "🌷", price = 800, max = 4,
		description = "Kolorowe kwiaty przy ścieżkach." },
	{ id = "bench", name = "Ławka", icon = "🪑", price = 1500, max = 4,
		description = "Ławki dookoła placu z fontanną." },
	{ id = "tree", name = "Drzewo", icon = "🌳", price = 2500, max = 6,
		description = "Duże drzewa przy żywopłocie." },
	{ id = "flag", name = "Flaga", icon = "🚩", price = 5000, max = 2,
		description = "Flagi przy bramie wejściowej." },
	{ id = "fountain", name = "Fontanna", icon = "⛲", price = 15000, max = 1,
		description = "Fontanna z tryskającą wodą na środku bazy." },
	{ id = "statue", name = "Złota kura", icon = "🐔", price = 100000, max = 1,
		description = "Pomnik złotej kury. Niech wszyscy widzą, kto tu rządzi!" },
}

Decorations.byId = {}
for _, decoration in Decorations.list do
	Decorations.byId[decoration.id] = decoration
end

local FOUNTAIN = Vector3.new(16, 0, 14)

-- Miejsca w układzie działki: { position, lookAt? }
Decorations.slots = {
	flowers = {
		{ Vector3.new(-30, 0, -1) }, { Vector3.new(-50, 0, -1) }, { Vector3.new(38, 0, 14) }, { Vector3.new(-24, 0, 50) },
	},
	bench = {},
	tree = {
		{ Vector3.new(-96, 0, -50) }, { Vector3.new(-96, 0, 10) }, { Vector3.new(-96, 0, 125) },
		{ Vector3.new(96, 0, -60) }, { Vector3.new(96, 0, 40) }, { Vector3.new(60, 0, -66) },
	},
	flag = { { Vector3.new(-24, 0, -68) }, { Vector3.new(4, 0, -68) } },
	fountain = { { FOUNTAIN } },
	statue = { { Vector3.new(-45, 0, 16) } },
}
for i = 0, 3 do
	local angle = math.rad(i * 90 + 45)
	local position = FOUNTAIN + Vector3.new(math.cos(angle) * 12, 0, math.sin(angle) * 12)
	table.insert(Decorations.slots.bench, { position, FOUNTAIN })
end

return Decorations
