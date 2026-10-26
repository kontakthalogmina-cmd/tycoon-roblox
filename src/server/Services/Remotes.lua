-- Tworzy RemoteEventy w ReplicatedStorage.Remotes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NAMES = {
	"DataUpdate", -- serwer -> klient: stan gracza
	"Notify", -- serwer -> klient: komunikat (tekst)
	"UpgradeFactory", -- klient -> serwer: ulepsz fabrykę surowcami
	"UpgradeMine", -- klient -> serwer: ulepsz kopalnię za $
	"BuyPickaxe", -- klient -> serwer: kup kilof (id)
	"EquipPickaxe", -- klient -> serwer: załóż kilof (id)
	"MineHit", -- klient -> serwer: uderzenie kilofem w skałę (model)
	"UpgradeLuck", -- klient -> serwer: kup kolejny poziom szczęścia
	"BuyEggSkin", -- klient -> serwer: kup skórkę jajek (id)
	"EquipEggSkin", -- klient -> serwer: załóż skórkę jajek (id)
	"OpenShop", -- serwer -> klient: otwórz sklep (budka na działce)
	"RaidState", -- serwer -> klient: trwający napad (rola, przeciwnik, koniec) albo nil
	"StartRaid", -- klient -> serwer: napadnij gracza (userId)
	"BuyDefense", -- klient -> serwer: kup kolejny poziom ochrony bazy
	"DefendHome", -- klient -> serwer: wróć bronić bazy w czasie napadu
	"PvpHit", -- klient -> serwer: uderzenie kilofem w gracza (Player)
	"ThrowEgg", -- klient -> serwer: rzut jajkiem w punkt (Vector3)
	"FireWeapon", -- klient -> serwer: strzał z karabinu w punkt (Vector3)
	"BuyWeapon", -- klient -> serwer: kup/wybierz karabin (id)
	"Knockback", -- serwer -> klient: przewrócenie (prędkość, czas)
}

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local Remotes = {}
for _, name in NAMES do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	Remotes[name] = remote
end

folder.Parent = ReplicatedStorage

function Remotes.notify(player: Player, text: string)
	Remotes.Notify:FireClient(player, text)
end

return Remotes
