-- Skórki jajek kupowane za $. Zmieniają wygląd jajek na linii
-- i dają premię do ich wartości (bonus = mnożnik).
-- rainbow = true: każde jajko dostaje losowy kolor.
local EggSkins = {}

EggSkins.list = {
	{ id = "classic", name = "Klasyczne", price = 0, bonus = 1,
		color = Color3.fromRGB(245, 240, 225), material = Enum.Material.SmoothPlastic },
	{ id = "farm", name = "Wiejskie", price = 1500, bonus = 1.05,
		color = Color3.fromRGB(196, 140, 90), material = Enum.Material.SmoothPlastic },
	{ id = "chocolate", name = "Czekoladowe", price = 8000, bonus = 1.1,
		color = Color3.fromRGB(95, 55, 30), material = Enum.Material.Plastic },
	{ id = "marble", name = "Marmurowe", price = 30000, bonus = 1.15,
		color = Color3.fromRGB(235, 235, 240), material = Enum.Material.Marble },
	{ id = "ice", name = "Lodowe", price = 120000, bonus = 1.25,
		color = Color3.fromRGB(160, 220, 255), material = Enum.Material.Ice },
	{ id = "lava", name = "Lawowe", price = 400000, bonus = 1.4,
		color = Color3.fromRGB(255, 110, 30), material = Enum.Material.CrackedLava },
	{ id = "cosmic", name = "Kosmiczne", price = 1500000, bonus = 1.6,
		color = Color3.fromRGB(120, 60, 255), material = Enum.Material.Neon },
	{ id = "rainbow", name = "Tęczowe", price = 6000000, bonus = 2,
		color = Color3.fromRGB(255, 255, 255), material = Enum.Material.Neon, rainbow = true },
}

EggSkins.byId = {}
for _, skin in EggSkins.list do
	EggSkins.byId[skin.id] = skin
end

return EggSkins
