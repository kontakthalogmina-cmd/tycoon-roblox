-- Surowce wydobywane w kopalni.
-- tier          : minimalny poziom kilofa (Pickaxes.tier) potrzebny do kopania
-- minMineLevel  : od którego poziomu kopalni surowiec zaczyna się pojawiać
-- hp            : ile "obrażeń" trzeba zadać, żeby wykopać blok
-- weight        : szansa pojawienia się (im więcej, tym częściej)
-- drop          : ile sztuk surowca daje jeden blok
local Ores = {}

Ores.list = {
	{ id = "stone", name = "Kamień", tier = 1, minMineLevel = 1, hp = 3, weight = 50, drop = 1,
		color = Color3.fromRGB(140, 140, 140), material = Enum.Material.Slate },
	{ id = "coal", name = "Węgiel", tier = 1, minMineLevel = 1, hp = 4, weight = 35, drop = 1,
		color = Color3.fromRGB(40, 40, 40), material = Enum.Material.Basalt },
	{ id = "copper", name = "Miedź", tier = 2, minMineLevel = 2, hp = 6, weight = 28, drop = 1,
		color = Color3.fromRGB(196, 112, 60), material = Enum.Material.Metal },
	{ id = "iron", name = "Żelazo", tier = 3, minMineLevel = 3, hp = 9, weight = 22, drop = 1,
		color = Color3.fromRGB(200, 190, 180), material = Enum.Material.DiamondPlate },
	{ id = "gold", name = "Złoto", tier = 4, minMineLevel = 4, hp = 14, weight = 14, drop = 1,
		color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Foil },
	{ id = "diamond", name = "Diament", tier = 5, minMineLevel = 5, hp = 22, weight = 8, drop = 1,
		color = Color3.fromRGB(90, 230, 255), material = Enum.Material.Glass },
	{ id = "ruby", name = "Rubin", tier = 6, minMineLevel = 6, hp = 32, weight = 5, drop = 1,
		color = Color3.fromRGB(230, 30, 60), material = Enum.Material.Glass },
}

Ores.byId = {}
for _, ore in Ores.list do
	Ores.byId[ore.id] = ore
end

return Ores
