-- Dźwięki gry. Domyślnie używamy dźwięków wbudowanych w Robloxa (rbxasset://),
-- które działają bez wgrywania czegokolwiek.
-- Chcesz prawdziwe brainrot głosy („Tung tung sahur”, „Tralalero tralala”)? Znajdź je w
-- Creator Store (Toolbox -> Audio) albo wgraj własne i wpisz ID jako "rbxassetid://123456".
local Sounds = {}

Sounds.list = {
	click = { id = "rbxasset://sounds/clickfast.wav", volume = 0.5 },
	buy = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6 },
	coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, pitch = 1.4 },
	notify = { id = "rbxasset://sounds/button.wav", volume = 0.4 },
	levelUp = { id = "rbxasset://sounds/victory.wav", volume = 0.6 },
	throw = { id = "rbxasset://sounds/swoosh.wav", volume = 0.6 },
	splat = { id = "rbxasset://sounds/splat.wav", volume = 0.8 },
	shot = { id = "rbxasset://sounds/paintball.wav", volume = 0.5 },
	mineHit = { id = "rbxasset://sounds/hit.wav", volume = 0.6 },
	oreBreak = { id = "rbxasset://sounds/glassbreak.wav", volume = 0.5 },
	cannon = { id = "rbxasset://sounds/Rocket shot.wav", volume = 0.7 },
	magic = { id = "rbxasset://sounds/Rocket whoosh 01.wav", volume = 0.5, pitch = 1.6 },
	chirp = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.25, pitch = 2.2 },
	march = { id = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 0.5, pitch = 1.8 },
	win = { id = "rbxasset://sounds/victory.wav", volume = 0.7 },
	lose = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.6 },
	invite = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.7, pitch = 0.8 },
}

-- Głosy brainrotów przy strzale z pistoletu maszynowego (losowany jeden na strzał).
-- Podmień na prawdziwe nagrania z Toolboxa, np. { id = "rbxassetid://123456", volume = 0.6 }.
Sounds.brainrot = {
	{ id = "rbxasset://sounds/paintball.wav", volume = 0.6, pitch = 0.6 },
	{ id = "rbxasset://sounds/snap.wav", volume = 0.6, pitch = 1.5 },
	{ id = "rbxasset://sounds/swordlunge.wav", volume = 0.5, pitch = 1.8 },
	{ id = "rbxasset://sounds/uuhhh.mp3", volume = 0.5, pitch = 2.4 },
	{ id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 0.5 },
}

return Sounds
