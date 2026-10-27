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

-- Broń palna: tylko Brainrot Karabin Maszynowy za Robux (Game Pass, ID w Config/Products.lua).
-- Jajko do rzucania każdy ma za darmo. fireRate = sekundy między strzałami.
Weapons.rifles = {
	{ id = "brainrotsmg", name = "Brainrot Karabin Maszynowy", robux = true, brainrot = true, price = 0, damage = 9,
		fireRate = 0.09, range = 180, spread = 3, color = Color3.fromRGB(255, 90, 160) },
}
Weapons.byId = {}
for _, rifle in Weapons.rifles do
	Weapons.byId[rifle.id] = rifle
end

-- Okrzyk brainrota gra najwyżej co tyle sekund (przy serii z karabinu byłby chaos).
Weapons.voiceInterval = 0.7

-- Pociski karabinu: każdy strzał to losowy brainrot.
-- image : obrazek brainrota z Creator Store, np. "rbxassetid://123456" (puste = emotka + podpis)
-- sound : okrzyk brainrota z Creator Store, np. "rbxassetid://123456" (puste = dźwięk zastępczy)
-- Jak znaleźć: Roblox Studio -> View -> Toolbox -> Marketplace -> zakładka Images / Audio,
-- wpisz nazwę (np. "tralalero tralala"), kliknij prawym na wynik -> Copy Asset ID.
Weapons.brainrots = {
	{ text = "🦈", name = "Tralalero Tralala", color = Color3.fromRGB(80, 170, 255), image = "", sound = "" },
	{ text = "🪵", name = "Tung Tung Sahur", color = Color3.fromRGB(190, 140, 80), image = "", sound = "" },
	{ text = "🐊", name = "Bombardiro Crocodilo", color = Color3.fromRGB(90, 200, 90), image = "", sound = "" },
	{ text = "🌵", name = "Lirili Larila", color = Color3.fromRGB(120, 210, 90), image = "", sound = "" },
	{ text = "☕", name = "Cappuccino Assassino", color = Color3.fromRGB(170, 110, 70), image = "", sound = "" },
	{ text = "🐸", name = "Brr Brr Patapim", color = Color3.fromRGB(110, 220, 120), image = "", sound = "" },
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
