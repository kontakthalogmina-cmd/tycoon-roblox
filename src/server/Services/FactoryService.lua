-- Fabryka: produkuje $ co sekundę, ulepszana surowcami albo za Robux.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FactoryLevels = require(ReplicatedStorage.Shared.Config.FactoryLevels)
local Ores = require(ReplicatedStorage.Shared.Config.Ores)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local FactoryService = {}

function FactoryService.Income(level: number): number
	return FactoryLevels[level].income
end

function FactoryService.UpdateLabel(player: Player)
	local plot = PlotService.Get(player)
	local data = PlayerData.Get(player)
	if plot and data then
		plot.factoryLabel.Text = string.format(
			"Fabryka poz. %d\n%s/s",
			data.FactoryLevel,
			Format.money(FactoryService.Income(data.FactoryLevel))
		)
	end
end

local function levelUp(player: Player, data)
	data.FactoryLevel += 1
	FactoryService.UpdateLabel(player)
	PlayerData.MarkChanged(player)
	Remotes.notify(player, string.format("Fabryka ulepszona do poziomu %d!", data.FactoryLevel))
end

function FactoryService.TryUpgradeWithOres(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local nextLevel = FactoryLevels[data.FactoryLevel + 1]
	if not nextLevel then
		Remotes.notify(player, "Fabryka ma już maksymalny poziom.")
		return
	end
	for oreId, amount in nextLevel.cost do
		if (data.Ores[oreId] or 0) < amount then
			Remotes.notify(player, "Brakuje surowca: " .. Ores.byId[oreId].name)
			return
		end
	end
	for oreId, amount in nextLevel.cost do
		data.Ores[oreId] -= amount
	end
	levelUp(player, data)
end

-- Ulepszenie kupione za Robux. Zwraca false, gdy fabryka ma już max poziom.
function FactoryService.GrantLevel(player: Player): boolean
	local data = PlayerData.Get(player)
	if not data or not FactoryLevels[data.FactoryLevel + 1] then
		return false
	end
	levelUp(player, data)
	return true
end

function FactoryService.StartLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in PlayerData.All() do
				PlayerData.AddCash(player, FactoryService.Income(data.FactoryLevel))
			end
		end
	end)
end

return FactoryService
