-- Rzadkości jajek z linii produkcyjnej.
-- weight     : bazowa szansa (im więcej, tym częściej); szczęście mnoży szanse wszystkich poza pierwszą
-- multiplier : mnożnik wartości jajka
return {
	{ id = "common", name = "Zwykłe", weight = 70, multiplier = 1, color = Color3.fromRGB(230, 230, 230) },
	{ id = "uncommon", name = "Niezwykłe", weight = 20, multiplier = 2, color = Color3.fromRGB(90, 220, 110) },
	{ id = "rare", name = "Rzadkie", weight = 7, multiplier = 5, color = Color3.fromRGB(70, 150, 255) },
	{ id = "epic", name = "Epickie", weight = 2.5, multiplier = 15, color = Color3.fromRGB(180, 90, 255) },
	{ id = "legendary", name = "Legendarne", weight = 0.45, multiplier = 50, color = Color3.fromRGB(255, 190, 40) },
	{ id = "mythic", name = "Mityczne", weight = 0.05, multiplier = 200, color = Color3.fromRGB(255, 50, 80) },
}
