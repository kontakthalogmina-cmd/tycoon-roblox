-- Kilofy kupowane za pieniądze z fabryki.
-- tier     : jakie surowce można kopać (Ores.tier <= tier)
-- damage   : ile HP bloku zabiera jedno uderzenie
-- cooldown : minimalny odstęp między uderzeniami (sekundy)
-- price    : cena w $
local Pickaxes = {}

Pickaxes.list = {
	{ id = "wooden", name = "Drewniany kilof", tier = 1, damage = 1, cooldown = 0.35, price = 0 },
	{ id = "stone", name = "Kamienny kilof", tier = 2, damage = 2, cooldown = 0.32, price = 400 },
	{ id = "iron", name = "Żelazny kilof", tier = 3, damage = 3, cooldown = 0.3, price = 2500 },
	{ id = "gold", name = "Złoty kilof", tier = 4, damage = 5, cooldown = 0.27, price = 15000 },
	{ id = "diamond", name = "Diamentowy kilof", tier = 5, damage = 8, cooldown = 0.24, price = 80000 },
	{ id = "ruby", name = "Rubinowy kilof", tier = 6, damage = 12, cooldown = 0.2, price = 350000 },
}

Pickaxes.byId = {}
for _, pickaxe in Pickaxes.list do
	Pickaxes.byId[pickaxe.id] = pickaxe
end

return Pickaxes
