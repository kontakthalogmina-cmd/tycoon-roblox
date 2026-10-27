-- Muzyka w tle: spokojna na co dzień, szybka podczas napadu i bitwy pisklaków.
-- Utwory wpisujesz sam w Config/Music.lua. Bez wpisanych ID jest cisza, a przycisk się nie pokazuje.
-- Przycisk 🎵 w prawym dolnym rogu wycisza muzykę (efekty dźwiękowe dalej grają).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Music = require(ReplicatedStorage.Shared.Config.Music)

local player = Players.LocalPlayer
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
end

local function loadIds()
	for name, sound in sounds do
		local id = Music.tracks[name].id
		if typeof(id) == "string" and id ~= sound.SoundId then
			sound.SoundId = id
			failed[name] = nil
			-- Utwór, który się nie wczyta (np. prywatny), zgłaszamy w Output.
			task.delay(10, function()
				if sound.SoundId == id and not sound.IsLoaded then
					failed[name] = true
					warn("[Music] Nie wczytał się utwór", name, id, "- sprawdź ID w Config/Music.lua.")
					update()
				end
			end)
		end
	end
	update()
end

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
button.Visible = Music.tracks.calm.id ~= "" or Music.tracks.raid.id ~= ""
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
