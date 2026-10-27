-- Prawdziwe okrzyki i obrazki brainrotów do karabinu maszynowego.
-- Gdy w Config/Weapons.lua pole sound/image jest puste, serwer przy starcie sam szuka ich
-- w Creator Store Robloxa: dźwięk przez AssetService:SearchAudio, obrazek jako miniaturka
-- przedmiotu z katalogu (AvatarEditorService:SearchCatalog). Wyniki trafiają do
-- ReplicatedStorage.BrainrotAssets, więc widzą je też klienci. Gdy wyszukiwanie się nie uda,
-- zostaje emotka i dźwięk zastępczy, a w Output pojawia się ostrzeżenie.
local AssetService = game:GetService("AssetService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Music = require(ReplicatedStorage.Shared.Config.Music)
local Weapons = require(ReplicatedStorage.Shared.Config.Weapons)

local BrainrotAssets = {}

local MAX_CLIP_SECONDS = 8 -- krótkie okrzyki, nie całe piosenki

local folder = Instance.new("Folder")
folder.Name = "BrainrotAssets"
folder.Parent = ReplicatedStorage

-- Muzyka w tle: atrybuty calm / raid z ID utworów (klient: Music.client.lua).
local musicFolder = Instance.new("Folder")
musicFolder.Name = "GameMusic"
musicFolder.Parent = ReplicatedStorage

local function store(name: string, kind: string, value: string)
	local entry = folder:FindFirstChild(name) or Instance.new("Folder")
	entry.Name = name
	entry:SetAttribute(kind, value)
	entry.Parent = folder
end

local SEARCH_TIMEOUT = 8 -- sekundy; w nieopublikowanym miejscu wyszukiwanie potrafi wisieć bez końca

-- Woła fn(...) w osobnym wątku i czeka najwyżej SEARCH_TIMEOUT sekund.
local function callWithTimeout(fn, ...)
	local args = table.pack(...)
	local done, ok, result = false, false, "przekroczono czas"
	task.spawn(function()
		ok, result = pcall(fn, table.unpack(args, 1, args.n))
		done = true
	end)
	local started = os.clock()
	while not done and os.clock() - started < SEARCH_TIMEOUT do
		task.wait(0.2)
	end
	if not done then
		return false, "przekroczono czas"
	end
	return ok, result
end

local function findSound(keyword: string): string?
	local params = Instance.new("AudioSearchParams")
	params.SearchKeyword = keyword
	params.MaxDuration = MAX_CLIP_SECONDS
	local ok, pages = callWithTimeout(AssetService.SearchAudio, AssetService, params)
	if not ok then
		warn("[BrainrotAssets] Nie udało się wyszukać dźwięku:", keyword, pages)
		return nil
	end
	local okPage, page = pcall(pages.GetCurrentPage, pages)
	if not okPage then
		return nil
	end
	for _, audio in page do
		if audio.Id then
			return "rbxassetid://" .. audio.Id
		end
	end
	return nil
end

local function findMusic(keyword: string): string?
	local params = Instance.new("AudioSearchParams")
	params.SearchKeyword = keyword
	params.MinDuration = Music.minDuration
	pcall(function()
		params.AudioSubType = Enum.AudioSubType.Music
	end)
	local ok, pages = callWithTimeout(AssetService.SearchAudio, AssetService, params)
	if not ok then
		warn("[BrainrotAssets] Nie udało się wyszukać muzyki:", keyword, pages)
		return nil
	end
	local okPage, page = pcall(pages.GetCurrentPage, pages)
	if not okPage then
		return nil
	end
	for _, audio in page do
		if audio.Id then
			return "rbxassetid://" .. audio.Id
		end
	end
	return nil
end

local function findImage(keyword: string): string?
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword
	local ok, pages = callWithTimeout(AvatarEditorService.SearchCatalog, AvatarEditorService, params)
	if not ok then
		warn("[BrainrotAssets] Nie udało się wyszukać obrazka:", keyword, pages)
		return nil
	end
	local okPage, page = pcall(pages.GetCurrentPage, pages)
	if not okPage then
		return nil
	end
	for _, item in page do
		if item.Id then
			local kind = item.ItemType == "Bundle" and "BundleThumbnail" or "Asset"
			return string.format("rbxthumb://type=%s&id=%d&w=150&h=150", kind, item.Id)
		end
	end
	return nil
end

-- Obrazek i dźwięk danego brainrota: najpierw ręcznie wpisane w Config, potem znalezione.
function BrainrotAssets.Get(brainrot)
	local entry = folder:FindFirstChild(brainrot.name)
	local image = brainrot.image ~= "" and brainrot.image or (entry and entry:GetAttribute("image")) or ""
	local sound = brainrot.sound ~= "" and brainrot.sound or (entry and entry:GetAttribute("sound")) or ""
	return image, sound
end

function BrainrotAssets.Init()
	-- Ręcznie wpisana muzyka działa od razu, także w nieopublikowanej grze.
	for name, track in Music.tracks do
		if track.id ~= "" then
			musicFolder:SetAttribute(name, track.id)
		end
	end
	if game.GameId == 0 then
		-- Wyszukiwarka Robloxa działa tylko w opublikowanej grze.
		warn("[BrainrotAssets] Gra nie jest opublikowana, więc nie szukam okrzyków i obrazków brainrotów. Karabin strzela emotkami z dźwiękiem zastępczym, a muzyka w tle gra tylko z ręcznie wpisanym ID (Config/Music.lua). Opublikuj grę (Plik → Opublikuj w Roblox) i uruchom ją ponownie.")
		return
	end
	task.spawn(function()
		print("[BrainrotAssets] Szukam muzyki oraz okrzyków i obrazków brainrotów...")
		for name, track in Music.tracks do
			if track.id == "" then
				for _, keyword in track.keywords do
					local id = findMusic(keyword)
					if id then
						musicFolder:SetAttribute(name, id)
						print(string.format("[BrainrotAssets] Muzyka %s: %s (%s)", name, id, keyword))
						break
					end
				end
				task.wait(0.5)
			end
		end
		for _, brainrot in Weapons.brainrots do
			if brainrot.sound == "" then
				local sound = findSound(brainrot.name)
				if sound then
					store(brainrot.name, "sound", sound)
				end
			end
			if brainrot.image == "" then
				local image = findImage(brainrot.name)
				if image then
					store(brainrot.name, "image", image)
				end
			end
			task.wait(0.5) -- nie zasypujemy Robloxa zapytaniami
		end
		local found = #folder:GetChildren()
		print(string.format("[BrainrotAssets] Znaleziono assety dla %d z %d brainrotów.", found, #Weapons.brainrots))
	end)
end

return BrainrotAssets
