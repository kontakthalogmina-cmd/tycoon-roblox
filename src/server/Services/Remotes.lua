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
	"BuyDefense", -- klient -> serwer: wzmocnij skarbiec (dłuższy rabunek)
	"BuyDefenseItem", -- klient -> serwer: postaw minę / pułapkę / działo / wieżę (id)
	"DefendHome", -- klient -> serwer: wróć bronić bazy w czasie napadu
	"PvpHit", -- klient -> serwer: uderzenie kilofem w gracza (Player)
	"ThrowEgg", -- klient -> serwer: rzut jajkiem w punkt (Vector3)
	"FireWeapon", -- klient -> serwer: strzał z karabinu w punkt (Vector3)
	"BuyWeapon", -- klient -> serwer: kup/wybierz karabin (id)
	"Knockback", -- serwer -> klient: przewrócenie (prędkość, czas)
	"HatchChick", -- klient -> serwer: wykluj pisklaka za jajka
	"TrainChick", -- klient -> serwer: trenuj / przestań (uid, bool)
	"UpgradeCamp", -- klient -> serwer: ulepsz obóz treningowy za $
	"SendToWar", -- klient -> serwer: wyślij armię (userId albo "bandit:N")
	"BuyDecoration", -- klient -> serwer: kup dekorację bazy (id)
	"AllianceState", -- serwer -> klient: lista sojuszników
	"AllianceInvite", -- serwer -> klient: ktoś zaprasza do sojuszu (okienko)
	"AllianceInviteSend", -- klient -> serwer: zaproś gracza (userId)
	"AllianceRespond", -- klient -> serwer: odpowiedź (userId, "accept" | "ignore" | "block")
	"AllianceLeave", -- klient -> serwer: opuść sojusz
	"AllianceUnblock", -- klient -> serwer: odblokuj wszystkich
	"PlaySound", -- serwer -> klient: dźwięk słyszany tylko przez tego gracza (nazwa)
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
