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
