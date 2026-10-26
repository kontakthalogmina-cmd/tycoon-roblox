-- Napady na bazy innych graczy i obrona własnej bazy.
return {
	minFactoryLevel = 3, -- napadać i być napadanym można od tego poziomu fabryki (ochrona nowych graczy)
	stealPercent = 0.2, -- udany napad zabiera tyle gotówki ofiary
	levelsLost = 2, -- o tyle poziomów spada fabryka ofiary po udanym napadzie
	duration = 90, -- sekundy na dotarcie do skarbca i obrabowanie go
	attackerCooldown = 180, -- sekundy między napadami jednego gracza
	victimShield = 600, -- po udanym napadzie baza ofiary jest chroniona przez tyle sekund
	defenderBlockRadius = 15, -- właściciel stojący tak blisko skarbca blokuje rabunek
	pvpDamage = 20, -- obrażenia od uderzenia kilofem w czasie napadu
	towerRange = 32,
	towerInterval = 2, -- co ile sekund strzela każda wieża

	-- Poziomy ochrony bazy, kupowane za $.
	-- towers   : liczba wież obronnych przy skarbcu (max 6)
	-- damage   : obrażenia jednego strzału wieży
	-- holdTime : ile sekund napastnik musi trzymać klawisz przy skarbcu
	defenseLevels = {
		[0] = { price = 0, towers = 0, damage = 0, holdTime = 3 },
		{ price = 5000, towers = 1, damage = 4, holdTime = 5 },
		{ price = 25000, towers = 2, damage = 5, holdTime = 7 },
		{ price = 100000, towers = 3, damage = 6, holdTime = 9 },
		{ price = 400000, towers = 4, damage = 7, holdTime = 11 },
		{ price = 1500000, towers = 5, damage = 8, holdTime = 13 },
		{ price = 5000000, towers = 6, damage = 9, holdTime = 15 },
	},
}
