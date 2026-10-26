-- Rzadkości jajek z linii produkcyjnej.
-- weight     : bazowa szansa (im więcej, tym częściej); szczęście mnoży szanse wszystkich poza pierwszą
-- multiplier : mnożnik wartości jajka
-- tokens     : ile jajek (waluty na bronie) daje sprzedanie takiego jajka
-- color      : kolor jajka tej rzadkości (Zwykłe biorą kolor ze skórki)
-- effect     : "rainbow" = jajko mieni się wszystkimi kolorami, "pulse" = pulsujący blask
return {
	{ id = "common", tokens = 1, name = "Zwykłe", weight = 75, multiplier = 1, color = Color3.fromRGB(235, 235, 235) },
	{ id = "uncommon", tokens = 2, name = "Niezwykłe", weight = 18, multiplier = 2, color = Color3.fromRGB(80, 210, 100) },
	{ id = "rare", tokens = 4, name = "Rzadkie", weight = 5, multiplier = 5, color = Color3.fromRGB(60, 140, 255) },
	{ id = "epic", tokens = 10, name = "Epickie", weight = 1.6, multiplier = 15, color = Color3.fromRGB(170, 70, 255) },
	{ id = "legendary", tokens = 30, name = "Legendarne", weight = 0.35, multiplier = 50, color = Color3.fromRGB(255, 200, 40), effect = "rainbow" },
	{ id = "mythic", tokens = 100, name = "Mityczne", weight = 0.05, multiplier = 200, color = Color3.fromRGB(255, 40, 70), effect = "pulse" },
}
