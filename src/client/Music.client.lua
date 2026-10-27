-- Muzyka w tle: spokojna na co dzień, szybka podczas napadu i bitwy pisklaków.
-- ID utworów przychodzą z serwera (ReplicatedStorage.GameMusic, atrybuty calm / raid).
-- Gdy utworu nie ma (gra nieopublikowana, wyszukiwanie nic nie dało albo utwór się nie wczytał),
-- gra własna melodyjka składana z wbudowanych dźwięków Robloxa, więc muzyka jest zawsze.
-- Przycisk 🎵 w prawym dolnym rogu wycisza muzykę (efekty dźwiękowe dalej grają).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Music = require(ReplicatedStorage.Shared.Config.Music)

local player = Players.LocalPlayer
local musicFolder = ReplicatedStorage:WaitForChild("GameMusic")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local sounds = {} -- [nazwa utworu] = Sound
for name, track in Music.tracks do
	local sound = Instance.new("Sound")
	sound.Name = "Music_" .. name
	sound.Looped = true
	sound.Volume = 0
	sound:SetAttribute("TargetVolume", track.volume)
	sound.Parent = SoundService
	sounds[name] = sound
end

local muted = false
local inRaid = false
local current = nil
local failed = {} -- [nazwa utworu] = true, gdy utwór z ID się nie wczytał

---------------------------------------------------------------------------
-- Melodyjka zapasowa: nuty to jeden dźwięk z różną prędkością odtwarzania.
---------------------------------------------------------------------------

local NOTE_ID = "rbxasset://sounds/electronicpingshort.wav"
local KICK_ID = "rbxasset://sounds/hit.wav"
local SNARE_ID = "rbxasset://sounds/snap.wav"

local pool = {}
local poolIndex = 0
for i = 1, 16 do
	local sound = Instance.new("Sound")
	sound.Name = "MusicNote"
	sound.Parent = SoundService
	pool[i] = sound
end

local function note(id: string, semitone: number, volume: number)
	poolIndex = poolIndex % #pool + 1
	local sound = pool[poolIndex]
	sound:Stop()
	sound.SoundId = id
	sound.PlaybackSpeed = 0.5 * 2 ^ (semitone / 12)
	sound.Volume = volume
	sound.TimePosition = 0
	sound:Play()
end

-- Akordy jako półtony od C. Spokojna: C – G – Am – F, szybka: Am – F – C – G.
local SONGS = {
	calm = {
		step = 0.3, -- ósemki, ok. 100 BPM
		chords = { { 0, 4, 7 }, { 7, 11, 14 }, { 9, 12, 16 }, { 5, 9, 12 } },
		pattern = { 1, 2, 3, 4, 3, 2, 3, 2 }, -- 4 = oktawa wyżej podstawy
		melody = { 16, false, 14, false, 12, false, 14, false, 19, false, 16, false, 14, false, 12, false }, -- false = pauza
		volume = 0.22,
	},
	raid = {
		step = 0.13, -- szesnastki, szybko
		chords = { { 9, 12, 16 }, { 5, 9, 12 }, { 0, 4, 7 }, { 7, 11, 14 } },
		pattern = { 1, 2, 3, 2, 1, 2, 3, 4, 1, 2, 3, 2, 1, 2, 4, 3 },
		volume = 0.28,
		drums = true,
	},
}

local synthMode = nil -- "calm", "raid" albo nil (cisza)

task.spawn(function()
	local tick = 0
	while true do
		local song = synthMode and SONGS[synthMode]
		if not song then
			tick = 0
			task.wait(0.2)
			continue
		end
		local stepsPerChord = #song.pattern
		local chord = song.chords[(tick // stepsPerChord) % #song.chords + 1]
		local pos = tick % stepsPerChord + 1
		local pick = song.pattern[pos]
		local pitch = pick == 4 and chord[1] + 12 or chord[pick]
		note(NOTE_ID, pitch, song.volume * 0.7)
		if pos == 1 then
			note(NOTE_ID, chord[1] - 12, song.volume) -- bas
		end
		if song.melody then
			local m = song.melody[tick % #song.melody + 1]
			if m and (tick // #song.melody) % 2 == 1 then
				note(NOTE_ID, m + 12, song.volume * 0.6) -- melodia co drugi przebieg
			end
		end
		if song.drums then
			if pos % 4 == 1 then
				note(KICK_ID, -10, song.volume * 1.6)
			elseif pos % 8 == 5 then
				note(SNARE_ID, 0, song.volume * 1.2)
			end
		end
		tick += 1
		task.wait(song.step)
	end
end)

local function fade(sound: Sound, volume: number)
	TweenService:Create(sound, TweenInfo.new(Music.fadeTime), { Volume = volume }):Play()
end

local function hasTrack(name: string): boolean
	return sounds[name].SoundId ~= "" and not failed[name]
end

local function update()
	local wanted = (inRaid or player:GetAttribute("InBattle")) and "raid" or "calm"
	current = wanted
	local useTrack = hasTrack(wanted) and not muted
	for name, sound in sounds do
		if name == wanted and useTrack then
			if not sound.IsPlaying then
				sound:Play()
			end
			fade(sound, sound:GetAttribute("TargetVolume"))
		else
			fade(sound, 0)
		end
	end
	synthMode = (not muted and not useTrack) and wanted or nil
end

local function loadIds()
	for name, sound in sounds do
		local id = musicFolder:GetAttribute(name)
		if typeof(id) == "string" and id ~= sound.SoundId then
			sound.SoundId = id
			failed[name] = nil
			-- Utwór, który się nie wczyta (np. prywatny), zastępujemy melodyjką.
			task.delay(10, function()
				if sound.SoundId == id and not sound.IsLoaded then
					failed[name] = true
					warn("[Music] Nie wczytał się utwór", name, id, "- gra melodyjka zapasowa.")
					update()
				end
			end)
		end
	end
	update()
end

musicFolder.AttributeChanged:Connect(loadIds)
player:GetAttributeChangedSignal("InBattle"):Connect(update)
Remotes:WaitForChild("RaidState").OnClientEvent:Connect(function(info)
	inRaid = info ~= nil
	update()
end)

-- Wyciszony utwór po wygaśnięciu zatrzymujemy, żeby nie zużywał zasobów.
task.spawn(function()
	while true do
		task.wait(Music.fadeTime + 0.5)
		for name, sound in sounds do
			if name ~= current and sound.IsPlaying and sound.Volume < 0.01 then
				sound:Pause()
			end
		end
	end
end)

-- Przycisk włącz / wycisz.
local gui = Instance.new("ScreenGui")
gui.Name = "MusicToggle"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -12, 1, -12)
button.Size = UDim2.fromOffset(46, 46)
button.BackgroundColor3 = Color3.fromRGB(40, 44, 70)
button.BackgroundTransparency = 0.15
button.Text = "🎵"
button.TextSize = 24
button.Font = Enum.Font.FredokaOne
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", button)
stroke.Color = Color3.fromRGB(255, 200, 60)
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

button.Activated:Connect(function()
	muted = not muted
	button.Text = muted and "🔇" or "🎵"
	update()
end)

loadIds()
