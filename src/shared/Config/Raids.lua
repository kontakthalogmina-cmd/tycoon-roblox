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

	-- Poziomy wzmocnienia skarbca, kupowane za $ (osobno od min, pułapek, dział i wież, patrz Defenses.lua).
	-- holdTime : ile sekund napastnik musi trzymać klawisz przy skarbcu
	-- towers/damage: stare wieże przy skarbcu, wyłączone (0), obronę dają teraz budowle z Defenses.lua
	defenseLevels = {
		[0] = { price = 0, towers = 0, damage = 0, holdTime = 3 },
		{ price = 5000, towers = 0, damage = 0, holdTime = 5 },
		{ price = 25000, towers = 0, damage = 0, holdTime = 7 },
		{ price = 100000, towers = 0, damage = 0, holdTime = 9 },
		{ price = 400000, towers = 0, damage = 0, holdTime = 11 },
		{ price = 1500000, towers = 0, damage = 0, holdTime = 13 },
		{ price = 5000000, towers = 0, damage = 0, holdTime = 15 },
	},
}
