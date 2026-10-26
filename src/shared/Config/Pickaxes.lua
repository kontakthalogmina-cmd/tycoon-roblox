-- Kilofy kupowane za pieniądze z fabryki.
-- tier     : jakie surowce można kopać (Ores.tier <= tier)
-- damage   : ile HP bloku zabiera jedno uderzenie
-- cooldown : minimalny odstęp między uderzeniami (sekundy)
-- price    : cena w $
-- color, material : wygląd głowicy kilofa
local Pickaxes = {}

Pickaxes.list = {
	{ id = "wooden", name = "Drewniany kilof", tier = 1, damage = 1, cooldown = 0.45, price = 0,
		color = Color3.fromRGB(150, 105, 60), material = Enum.Material.WoodPlanks },
	{ id = "stone", name = "Kamienny kilof", tier = 2, damage = 2, cooldown = 0.42, price = 400,
		color = Color3.fromRGB(125, 125, 130), material = Enum.Material.Slate },
	{ id = "iron", name = "Żelazny kilof", tier = 3, damage = 3, cooldown = 0.4, price = 2500,
		color = Color3.fromRGB(205, 205, 210), material = Enum.Material.Metal },
	{ id = "gold", name = "Złoty kilof", tier = 4, damage = 5, cooldown = 0.37, price = 15000,
		color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "diamond", name = "Diamentowy kilof", tier = 5, damage = 8, cooldown = 0.34, price = 80000,
		color = Color3.fromRGB(90, 230, 255), material = Enum.Material.Glass },
	{ id = "ruby", name = "Rubinowy kilof", tier = 6, damage = 12, cooldown = 0.3, price = 350000,
		color = Color3.fromRGB(230, 30, 60), material = Enum.Material.Neon },
}

Pickaxes.byId = {}
for _, pickaxe in Pickaxes.list do
	Pickaxes.byId[pickaxe.id] = pickaxe
end

return Pickaxes
