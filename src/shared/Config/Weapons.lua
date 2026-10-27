-- Walka: rzucanie jajkami (zawsze, bez limitu), brainrot karabiny (kupowane za jajka)
-- i kradzież wielkiego złotego jajka po pokonaniu przeciwnika.
local Weapons = {}

-- Jajko do rzucania: przewraca i odpycha trafionego gracza.
Weapons.throw = {
	cooldown = 0.7,
	speed = 110, -- prędkość lotu (studs/s)
	gravity = 60,
	maxTime = 2.5, -- po tylu sekundach lotu jajko znika
	knockback = 55, -- siła odepchnięcia w poziomie
	upward = 35, -- podrzut w górę
	knockdown = 1.6, -- ile sekund leży przewrócony gracz
	damage = 5,
}

-- Brainrot karabiny. price w jajkach (🥚), fireRate = sekundy między strzałami.
Weapons.rifles = {
	{ id = "tralalero", name = "Tralalero Pukawka", price = 50, damage = 10, fireRate = 0.3, range = 150, spread = 1.5,
		color = Color3.fromRGB(60, 200, 255) },
	{ id = "tungtung", name = "Tung Tung Karabin", price = 250, damage = 14, fireRate = 0.22, range = 170, spread = 1.5,
		color = Color3.fromRGB(190, 140, 80) },
	{ id = "bombardiro", name = "Bombardiro M4", price = 1000, damage = 18, fireRate = 0.15, range = 200, spread = 2,
		color = Color3.fromRGB(80, 200, 90) },
	{ id = "brrbrr", name = "Brr Brr Minigun", price = 4000, damage = 7, fireRate = 0.06, range = 160, spread = 4,
		color = Color3.fromRGB(230, 90, 200) },
	{ id = "lirili", name = "Lirili Snajperka", price = 10000, damage = 65, fireRate = 1.2, range = 400, spread = 0.1,
		color = Color3.fromRGB(255, 210, 60) },
	-- Za Robux (Game Pass, ID w Config/Products.lua): strzela latającymi brainrotami z ich okrzykami.
	{ id = "brainrotsmg", name = "Brainrot Pistolet Maszynowy", robux = true, brainrot = true, price = 0, damage = 9,
		fireRate = 0.09, range = 180, spread = 3, color = Color3.fromRGB(255, 90, 160) },
}
Weapons.byId = {}
for _, rifle in Weapons.rifles do
	Weapons.byId[rifle.id] = rifle
end

-- Pociski brainrot pistoletu maszynowego.
Weapons.brainrots = {
	{ text = "🦈", name = "Tralalero", color = Color3.fromRGB(80, 170, 255) },
	{ text = "🪵", name = "Tung Tung", color = Color3.fromRGB(190, 140, 80) },
	{ text = "🐊", name = "Bombardiro", color = Color3.fromRGB(90, 200, 90) },
	{ text = "🌵", name = "Lirili", color = Color3.fromRGB(120, 210, 90) },
	{ text = "☕", name = "Cappuccino", color = Color3.fromRGB(170, 110, 70) },
	{ text = "🐸", name = "Patapim", color = Color3.fromRGB(110, 220, 120) },
}

-- Napisy pokazywane przy trafieniu.
Weapons.phrases = { "BRAINROT!", "SKIBIDI!", "TUNG TUNG!", "BOMBARDIRO!", "TRALALERO!", "BRR BRR!", "SAHUR!" }

-- Złote jajko: pokonanie gracza (albo zrzucenie go z wyspy) zabiera mu część gotówki
-- w postaci złotego jajka, które trzeba zanieść na własną działkę.
Weapons.goldenEgg = {
	stealPercent = 0.1, -- część gotówki ofiary
	attackerWindow = 10, -- ile sekund po trafieniu liczy się zabójstwo (np. upadek z wyspy)
	carrySpeed = 0.7, -- mnożnik prędkości gracza niosącego jajko
	groundTime = 60, -- po tylu sekundach na ziemi jajko wraca do właściciela
}

return Weapons
