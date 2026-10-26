-- Rzadkości jajek z linii produkcyjnej.
-- weight     : bazowa szansa (im więcej, tym częściej); szczęście mnoży szanse wszystkich poza pierwszą
-- multiplier : mnożnik wartości jajka
-- color      : kolor jajka tej rzadkości (Zwykłe biorą kolor ze skórki)
-- effect     : "rainbow" = jajko mieni się wszystkimi kolorami, "pulse" = pulsujący blask
return {
	{ id = "common", name = "Zwykłe", weight = 75, multiplier = 1, color = Color3.fromRGB(235, 235, 235) },
	{ id = "uncommon", name = "Niezwykłe", weight = 18, multiplier = 2, color = Color3.fromRGB(80, 210, 100) },
	{ id = "rare", name = "Rzadkie", weight = 5, multiplier = 5, color = Color3.fromRGB(60, 140, 255) },
	{ id = "epic", name = "Epickie", weight = 1.6, multiplier = 15, color = Color3.fromRGB(170, 70, 255) },
	{ id = "legendary", name = "Legendarne", weight = 0.35, multiplier = 50, color = Color3.fromRGB(255, 200, 40), effect = "rainbow" },
	{ id = "mythic", name = "Mityczne", weight = 0.05, multiplier = 200, color = Color3.fromRGB(255, 40, 70), effect = "pulse" },
}
