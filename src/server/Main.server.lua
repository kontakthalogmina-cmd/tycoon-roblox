-- Punkt startowy serwera: podłącza serwisy i zdarzenia graczy.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Services = script.Parent.Services
local Remotes = require(Services.Remotes)
local PlayerData = require(Services.PlayerData)
local PlotService = require(Services.PlotService)
local MineService = require(Services.MineService)
local FactoryService = require(Services.FactoryService)
local ShopService = require(Services.ShopService)
local ProductionLineService = require(Services.ProductionLineService)
local PickaxeTool = require(Services.PickaxeTool)
local RaidService = require(Services.RaidService)
local CombatService = require(Services.CombatService)
local DefenseService = require(Services.DefenseService)
local MonetizationService = require(Services.MonetizationService)

local LuckLevels = require(game:GetService("ReplicatedStorage").Shared.Config.LuckLevels)
local Raids = require(game:GetService("ReplicatedStorage").Shared.Config.Raids)

local AUTOSAVE_INTERVAL = 60

-- Słoneczny dzień z lekką mgiełką na horyzoncie.
Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
Lighting.Ambient = Color3.fromRGB(70, 65, 60) -- żeby w jaskini nie było zupełnie ciemno
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Haze = 1.5
atmosphere.Color = Color3.fromRGB(200, 220, 240)
atmosphere.Parent = Lighting

PlotService.Init()
MineService.Init()
MonetizationService.Init()
RaidService.Init()
CombatService.Init()
DefenseService.Init()

local function setupLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Pieniądze"
	cash.Value = data.Cash
	cash.Parent = leaderstats
	local earned = Instance.new("NumberValue")
	earned.Name = "Zarobione"
	earned.Value = data.TotalEarned
	earned.Parent = leaderstats
	leaderstats.Parent = player
end

PlayerData.Changed:Connect(function(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats["Pieniądze"].Value = data.Cash
		leaderstats["Zarobione"].Value = data.TotalEarned
	end
	Remotes.DataUpdate:FireClient(player, PlayerData.Snapshot(data))
end)

local function onPlayerAdded(player: Player)
	local data = PlayerData.Load(player)
	if not data then
		return
	end
	-- Starsze zapisy mogły mieć więcej poziomów szczęścia niż obecnie.
	data.LuckLevel = math.clamp(data.LuckLevel, 1, #LuckLevels)
	data.DefenseLevel = math.clamp(data.DefenseLevel, 0, #Raids.defenseLevels)
	setupLeaderstats(player, data)
	if not PlotService.Assign(player) then
		player:Kick("Brak wolnych działek na tym serwerze. Spróbuj inny serwer.")
		return
	end
	MineService.Start(player)
	ProductionLineService.Start(player)
	PickaxeTool.Setup(player)
	CombatService.Setup(player)
	RaidService.RefreshDefense(player)
	DefenseService.Refresh(player)
	FactoryService.UpdateLabel(player)
	PlayerData.MarkChanged(player)
end

local function onPlayerRemoving(player: Player)
	if not PlayerData.Get(player) then
		return
	end
	RaidService.PlayerLeft(player)
	CombatService.PlayerLeft(player)
	MineService.Stop(player)
	ProductionLineService.Stop(player)
	DefenseService.Clear(player)
	PlotService.Release(player)
	PlayerData.Save(player)
	PlayerData.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Remotes.UpgradeFactory.OnServerEvent:Connect(FactoryService.TryUpgradeWithOres)
Remotes.UpgradeMine.OnServerEvent:Connect(ShopService.UpgradeMine)
Remotes.BuyPickaxe.OnServerEvent:Connect(ShopService.BuyPickaxe)
Remotes.EquipPickaxe.OnServerEvent:Connect(ShopService.EquipPickaxe)
Remotes.UpgradeLuck.OnServerEvent:Connect(ShopService.UpgradeLuck)
Remotes.BuyEggSkin.OnServerEvent:Connect(ShopService.BuyEggSkin)
Remotes.EquipEggSkin.OnServerEvent:Connect(ShopService.EquipEggSkin)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in PlayerData.All() do
			task.spawn(PlayerData.Save, player)
		end
	end
end)

game:BindToClose(function()
	local remaining = 0
	for player in PlayerData.All() do
		remaining += 1
		task.spawn(function()
			PlayerData.Save(player)
			remaining -= 1
		end)
	end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
