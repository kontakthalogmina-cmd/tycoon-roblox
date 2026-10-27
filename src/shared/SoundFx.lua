-- Odtwarzanie dźwięków z Config/Sounds. Na serwerze dźwięk w świecie słyszą wszyscy w pobliżu,
-- na kliencie SoundFx.ui gra tylko u tego gracza (np. kliknięcia w sklepie).
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Sounds = require(script.Parent.Config.Sounds)

local SoundFx = {}

local function makeSound(def, pitchJitter: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = def.id
	sound.Volume = def.volume or 0.5
	local jitter = pitchJitter or 0
	sound.PlaybackSpeed = (def.pitch or 1) * (1 + (math.random() * 2 - 1) * jitter)
	return sound
end

local function play(def, position: Vector3, jitter: number?)
	if not def then
		return
	end
	-- Terrain stoi w (0, 0, 0), więc pozycja załącznika = pozycja w świecie.
	local holder = Instance.new("Attachment")
	holder.Position = position
	local sound = makeSound(def, jitter)
	sound.RollOffMaxDistance = 140
	sound.Parent = holder
	holder.Parent = workspace.Terrain
	sound:Play()
	Debris:AddItem(holder, 6)
end

-- Dźwięk w miejscu w świecie (np. wybuch, strzał).
function SoundFx.at(name: string, position: Vector3, jitter: number?)
	play(Sounds.list[name], position, jitter)
end

-- Okrzyk brainrota: prawdziwy z Config/Weapons (pole sound), a gdy go brak, losowy zastępczy.
function SoundFx.brainrot(position: Vector3, brainrot)
	if brainrot and brainrot.sound and brainrot.sound ~= "" then
		play({ id = brainrot.sound, volume = brainrot.volume or 0.8 }, position, 0)
		return
	end
	play(Sounds.brainrot[math.random(#Sounds.brainrot)], position, 0.1)
end

-- Dźwięk interfejsu słyszany tylko lokalnie (wołać z klienta).
function SoundFx.ui(name: string)
	local def = Sounds.list[name]
	if not def then
		return
	end
	local sound = makeSound(def, 0.04)
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 5)
end

return SoundFx
