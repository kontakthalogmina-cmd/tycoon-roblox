-- Prawdziwe okrzyki i obrazki brainrotów do karabinu maszynowego.
-- Gdy w Config/Weapons.lua pole sound/image jest puste, serwer przy starcie sam szuka ich
-- w Creator Store Robloxa: dźwięk przez AssetService:SearchAudio, obrazek jako miniaturka
-- przedmiotu z katalogu (AvatarEditorService:SearchCatalog). Wyniki trafiają do
-- ReplicatedStorage.BrainrotAssets, więc widzą je też klienci. Gdy wyszukiwanie się nie uda,
-- zostaje emotka i dźwięk zastępczy, a w Output pojawia się ostrzeżenie.
local AssetService = game:GetService("AssetService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.Config.Weapons)

local BrainrotAssets = {}

local MAX_CLIP_SECONDS = 8 -- krótkie okrzyki, nie całe piosenki

local folder = Instance.new("Folder")
folder.Name = "BrainrotAssets"
folder.Parent = ReplicatedStorage

local function store(name: string, kind: string, value: string)
	local entry = folder:FindFirstChild(name) or Instance.new("Folder")
	entry.Name = name
	entry:SetAttribute(kind, value)
	entry.Parent = folder
end

local function findSound(keyword: string): string?
	local params = Instance.new("AudioSearchParams")
	params.SearchKeyword = keyword
	params.MaxDuration = MAX_CLIP_SECONDS
	local ok, pages = pcall(AssetService.SearchAudio, AssetService, params)
	if not ok then
		warn("[BrainrotAssets] Nie udało się wyszukać dźwięku:", keyword, pages)
		return nil
	end
	for _, audio in pages:GetCurrentPage() do
		if audio.Id then
			return "rbxassetid://" .. audio.Id
		end
	end
	return nil
end

local function findImage(keyword: string): string?
	local params = CatalogSearchParams.new()
	params.SearchKeyword = keyword
	local ok, pages = pcall(AvatarEditorService.SearchCatalog, AvatarEditorService, params)
	if not ok then
		warn("[BrainrotAssets] Nie udało się wyszukać obrazka:", keyword, pages)
		return nil
	end
	for _, item in pages:GetCurrentPage() do
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
	task.spawn(function()
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
