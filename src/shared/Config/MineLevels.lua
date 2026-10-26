-- Poziomy kopalni, kupowane za pieniądze z fabryki.
-- price   : koszt wejścia na ten poziom ($), poziom 1 jest darmowy
-- slots   : ile bloków surowców jest jednocześnie w kopalni (max 36)
-- respawn : po ilu sekundach wykopany blok się odradza
-- Nowe surowce odblokowują się przez Ores.minMineLevel.
return {
	{ price = 0, slots = 8, respawn = 6 },
	{ price = 300, slots = 12, respawn = 5.5 },
	{ price = 2000, slots = 16, respawn = 5 },
	{ price = 10000, slots = 20, respawn = 4.5 },
	{ price = 50000, slots = 26, respawn = 4 },
	{ price = 250000, slots = 32, respawn = 3.5 },
	{ price = 1000000, slots = 36, respawn = 3 },
}
