-- Fabryka: poziom decyduje o wartości jajek na linii; ulepszana surowcami albo za Robux.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FactoryLevels = require(ReplicatedStorage.Shared.Config.FactoryLevels)
local Ores = require(ReplicatedStorage.Shared.Config.Ores)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local MineService = require(script.Parent.MineService)

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
	MineService.Refresh(player)
	PlayerData.MarkChanged(player)
	Remotes.notify(player, string.format("Fabryka ulepszona do poziomu %d!", data.FactoryLevel))
	Remotes.PlaySound:FireClient(player, "levelUp")
	-- Fajerwerki nad fabryką.
	local plot = PlotService.Get(player)
	local anchor = plot and plot.factoryLabel.Parent and plot.factoryLabel.Parent.Parent
	if anchor and anchor:IsA("BasePart") then
		local burst = Instance.new("ParticleEmitter")
		burst.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 90, 160))
		burst.LightEmission = 0.8
		burst.Size = NumberSequence.new(1.2, 0)
		burst.Lifetime = NumberRange.new(1, 1.6)
		burst.Speed = NumberRange.new(18, 28)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Acceleration = Vector3.new(0, -20, 0)
		burst.Rate = 0
		burst.Parent = anchor
		burst:Emit(80)
		game:GetService("Debris"):AddItem(burst, 3)
	end
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

return FactoryService
