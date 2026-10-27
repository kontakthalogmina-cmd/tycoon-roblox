-- Dźwięki gry. Domyślnie używamy dźwięków wbudowanych w Robloxa (rbxasset://),
-- które działają bez wgrywania czegokolwiek.
-- Prawdziwe okrzyki brainrotów wpisujesz w Config/Weapons.lua (Weapons.brainrots).
local Sounds = {}

Sounds.list = {
	click = { id = "rbxasset://sounds/clickfast.wav", volume = 0.5 },
	buy = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6 },
	coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, pitch = 1.4 },
	notify = { id = "rbxasset://sounds/button.wav", volume = 0.4 },
	levelUp = { id = "rbxasset://sounds/victory.wav", volume = 0.6 },
	throw = { id = "rbxasset://sounds/swoosh.wav", volume = 0.6 },
	splat = { id = "rbxasset://sounds/splat.wav", volume = 0.8 },
	shot = { id = "rbxasset://sounds/paintball.wav", volume = 0.3 },
	mineHit = { id = "rbxasset://sounds/hit.wav", volume = 0.15 },
	oreBreak = { id = "rbxasset://sounds/glassbreak.wav", volume = 0.2 },
	cannon = { id = "rbxasset://sounds/Rocket shot.wav", volume = 0.7 },
	magic = { id = "rbxasset://sounds/Rocket whoosh 01.wav", volume = 0.5, pitch = 1.6 },
	chirp = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.25, pitch = 2.2 },
	march = { id = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 0.5, pitch = 1.8 },
	win = { id = "rbxasset://sounds/victory.wav", volume = 0.7 },
	lose = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.6 },
	invite = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.7, pitch = 0.8 },
}

-- Zastępcze głosy brainrotów, gdy w Config/Weapons.lua (Weapons.brainrots[].sound) nie ma prawdziwego okrzyku.
Sounds.brainrot = {
	{ id = "rbxasset://sounds/paintball.wav", volume = 0.6, pitch = 0.6 },
	{ id = "rbxasset://sounds/snap.wav", volume = 0.6, pitch = 1.5 },
	{ id = "rbxasset://sounds/swordlunge.wav", volume = 0.5, pitch = 1.8 },
	{ id = "rbxasset://sounds/uuhhh.mp3", volume = 0.5, pitch = 2.4 },
	{ id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 0.5 },
}

return Sounds
