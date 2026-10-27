-- Wczytywanie, trzymanie w pamięci i zapisywanie danych gracza (DataStore).
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerData = {}

local STORE_NAME = "TycoonKopalnia_v1"
local MAX_RECEIPTS = 100

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore niedostępny, dane nie będą zapisywane:", result)
	end
end

local profiles = {} -- [Player] = { data = table, canSave = boolean }

local changedEvent = Instance.new("BindableEvent")
PlayerData.Changed = changedEvent.Event -- (player, data)

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

local TEMPLATE = {
	Cash = 0,
	TotalEarned = 0,
	Ores = {},
	FactoryLevel = 1,
	MineLevel = 1,
	OwnedPickaxes = { wooden = true },
	EquippedPickaxe = "wooden",
	LuckLevel = 1,
	OwnedEggSkins = { classic = true },
	EquippedEggSkin = "classic",
	DefenseLevel = 0,
	Defenses = {}, -- [defenseId] = ile sztuk stoi na działce
	Chicks = {}, -- lista { uid, type, level, xp, training, injuredUntil }
	ChickNextId = 0,
	CampLevel = 1,
	WarCooldownUntil = 0, -- os.time()
	WarShieldUntil = 0, -- os.time(), ochrona po przegranej wojnie
	Decorations = {}, -- [decorationId] = ile sztuk stoi w bazie
	BlockedPlayers = {}, -- [tostring(userId)] = true, zaproszenia do sojuszu od nich przepadają
	Eggs = 0, -- waluta na bronie (🥚), zdobywana z linii produkcyjnej
	OwnedWeapons = {},
	EquippedWeapon = "",
	RaidLog = {}, -- ostatnie napady: { kind, name, amount, levels, time }
	ShieldUntil = 0, -- os.time(), do kiedy baza jest chroniona po napadzie
	ProcessedReceipts = {}, -- [purchaseId] = true
	ReceiptOrder = {}, -- kolejność, żeby przycinać stare wpisy
}

local function reconcile(data)
	for key, value in TEMPLATE do
		if data[key] == nil then
			data[key] = deepCopy(value)
		end
	end
	return data
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function PlayerData.Load(player: Player)
	local data = nil
	if store then
		local loaded = false
		for attempt = 1, 3 do
			local ok, result = pcall(store.GetAsync, store, keyFor(player))
			if ok then
				data = result
				loaded = true
				break
			end
			warn("[PlayerData] Błąd odczytu (próba " .. attempt .. "):", result)
			task.wait(attempt)
		end
		if not loaded then
			if RunService:IsStudio() then
				-- W Studio bez dostępu do API gramy na świeżych danych, bez zapisu.
				warn("[PlayerData] Brak dostępu do DataStore w Studio. Włącz Game Settings > Security > Enable Studio Access to API Services, żeby zapisywać postęp.")
				data = reconcile(deepCopy(TEMPLATE))
				profiles[player] = { data = data, canSave = false }
				return data
			end
			-- Nie nadpisujemy zapisu pustymi danymi.
			player:Kick("Nie udało się wczytać Twoich danych. Spróbuj ponownie za chwilę.")
			return nil
		end
	end

	if not player.Parent then
		return nil -- gracz wyszedł w trakcie wczytywania
	end

	data = reconcile(data or deepCopy(TEMPLATE))
	profiles[player] = { data = data, canSave = store ~= nil }
	return data
end

function PlayerData.Get(player: Player)
	local profile = profiles[player]
	return profile and profile.data
end

function PlayerData.All()
	local result = {}
	for player, profile in profiles do
		result[player] = profile.data
	end
	return result
end

-- Zwraca true, jeśli zapis się udał (albo DataStore jest wyłączony).
function PlayerData.Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	if not profile.canSave then
		return true
	end
	for attempt = 1, 3 do
		local ok, err = pcall(store.SetAsync, store, keyFor(player), profile.data, { player.UserId })
		if ok then
			return true
		end
		warn("[PlayerData] Błąd zapisu (próba " .. attempt .. "):", err)
		task.wait(attempt)
	end
	return false
end

function PlayerData.Release(player: Player)
	profiles[player] = nil
end

-- Wywołuj po każdej zmianie danych, żeby odświeżyć GUI i leaderstats.
function PlayerData.MarkChanged(player: Player)
	local profile = profiles[player]
	if profile then
		changedEvent:Fire(player, profile.data)
	end
end

function PlayerData.AddCash(player: Player, amount: number)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned += amount
	end
	PlayerData.MarkChanged(player)
end

function PlayerData.HasReceipt(player: Player, purchaseId: string): boolean
	local data = PlayerData.Get(player)
	return data ~= nil and data.ProcessedReceipts[purchaseId] == true
end

function PlayerData.AddReceipt(player: Player, purchaseId: string)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	data.ProcessedReceipts[purchaseId] = true
	table.insert(data.ReceiptOrder, purchaseId)
	while #data.ReceiptOrder > MAX_RECEIPTS do
		local oldest = table.remove(data.ReceiptOrder, 1)
		data.ProcessedReceipts[oldest] = nil
	end
end

-- Dane wysyłane do klienta (bez wewnętrznych pól).
local function countKeys(t)
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

function PlayerData.Snapshot(data)
	return {
		Cash = data.Cash,
		TotalEarned = data.TotalEarned,
		Ores = data.Ores,
		FactoryLevel = data.FactoryLevel,
		MineLevel = data.MineLevel,
		OwnedPickaxes = data.OwnedPickaxes,
		EquippedPickaxe = data.EquippedPickaxe,
		LuckLevel = data.LuckLevel,
		OwnedEggSkins = data.OwnedEggSkins,
		EquippedEggSkin = data.EquippedEggSkin,
		DefenseLevel = data.DefenseLevel,
		Defenses = data.Defenses,
		Chicks = data.Chicks,
		CampLevel = data.CampLevel,
		WarCooldownUntil = data.WarCooldownUntil,
		WarShieldUntil = data.WarShieldUntil,
		Decorations = data.Decorations,
		BlockedCount = countKeys(data.BlockedPlayers),
		Eggs = data.Eggs,
		OwnedWeapons = data.OwnedWeapons,
		EquippedWeapon = data.EquippedWeapon,
		RaidLog = data.RaidLog,
		ShieldUntil = data.ShieldUntil,
	}
end

return PlayerData
