-- Poziomy fabryki. Fabryka produkuje jajka na linii produkcyjnej.
-- income : bazowa wartość produkcji w $ na sekundę (zwykłe jajko = income * interval linii)
-- cost   : surowce potrzebne, żeby wejść na ten poziom (id z Ores -> ilość)
-- Każdy poziom można też kupić za Robux (Products.FactoryUpgrade).
return {
	{ income = 2, cost = {} },
	{ income = 5, cost = { stone = 15 } },
	{ income = 10, cost = { stone = 30, coal = 15 } },
	{ income = 20, cost = { coal = 40, copper = 20 } },
	{ income = 40, cost = { copper = 40, iron = 20 } },
	{ income = 80, cost = { iron = 50, gold = 15 } },
	{ income = 160, cost = { iron = 80, gold = 40 } },
	{ income = 320, cost = { gold = 80, diamond = 10 } },
	{ income = 650, cost = { diamond = 30, ruby = 5 } },
	{ income = 1300, cost = { diamond = 60, ruby = 20 } },
}
