-- Linia produkcyjna: z fabryki co chwilę wyjeżdża jajko, jedzie taśmą do skupu i zamienia się w $.
-- Rzadkość jajka losowana jest ze szczęściem gracza, wygląd zależy od skórki.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local EggSkins = require(Shared.Config.EggSkins)
local LuckLevels = require(Shared.Config.LuckLevels)
local LineConfig = require(Shared.Config.ProductionLine)
local EggOdds = require(Shared.EggOdds)
local Format = require(Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local FactoryService = require(script.Parent.FactoryService)
local Remotes = require(script.Parent.Remotes)

local ProductionLineService = {}

local NOTIFY_FROM_RARITY = 4 -- od Epickiego wzwyż gracz dostaje komunikat
local running = {} -- [Player] = token

local function makeEgg(skin, rarity, rarityIndex: number, start: CFrame)
	local egg = Instance.new("Part")
	egg.Name = "Egg"
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanQuery = false
	egg.Size = Vector3.new(2, 2.6, 2)
	egg.CFrame = start
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg

	if rarityIndex == 1 then
		-- Zwykłe jajko wygląda jak wybrana skórka.
		egg.Material = skin.material
		egg.Color = skin.color
		if skin.rainbow then
			CollectionService:AddTag(egg, "Rainbow")
		end
	else
		-- Rzadsze jajka mają kolor swojej rzadkości i świecą.
		egg.Material = rarityIndex >= 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic
		egg.Color = rarity.color
		if rarity.effect == "rainbow" then
			CollectionService:AddTag(egg, "Rainbow")
		elseif rarity.effect == "pulse" then
			CollectionService:AddTag(egg, "Pulse")
		end
	end

	if rarityIndex >= 2 then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(110, 26)
		gui.StudsOffset = Vector3.new(0, 2.4, 0)
		gui.MaxDistance = 80
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = rarity.color
		label.TextStrokeTransparency = 0.1
		label.Text = rarity.name
		label.Parent = gui
		gui.Parent = egg
		if rarity.effect == "rainbow" then
			CollectionService:AddTag(label, "Rainbow")
		end
	end
	if rarityIndex >= 3 then
		local glow = Instance.new("PointLight")
		glow.Color = rarity.color
		glow.Range = 6 + rarityIndex * 2
		glow.Brightness = 1 + rarityIndex * 0.4
		glow.Parent = egg
		if rarity.effect == "rainbow" then
			CollectionService:AddTag(glow, "Rainbow")
		end
	end
	if rarityIndex >= 4 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rarity.color
		sparkles.Parent = egg
	end
	if rarityIndex >= 6 then
		local fire = Instance.new("Fire")
		fire.Color = rarity.color
		fire.SecondaryColor = Color3.new(1, 1, 1)
		fire.Size = 3
		fire.Heat = 4
		fire.Parent = egg
	end
	return egg
end

local function popup(position: CFrame, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = position
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(140, 36)
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = anchor
	anchor.Parent = workspace
	local info = TweenInfo.new(1.2)
	TweenService:Create(gui, info, { StudsOffset = Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.3)
end

local function spawnEgg(player: Player, token)
	local data = PlayerData.Get(player)
	local plot = PlotService.Get(player)
	if not data or not plot then
		return
	end
	local line = plot.line
	local luck = LuckLevels[data.LuckLevel].luck
	local rarity, rarityIndex = EggOdds.roll(luck)
	local skin = EggSkins.byId[data.EquippedEggSkin] or EggSkins.list[1]
	local value = math.floor(
		FactoryService.Income(data.FactoryLevel) * LineConfig.interval * rarity.multiplier * skin.bonus
	)

	local egg = makeEgg(skin, rarity, rarityIndex, line.lineStart)
	egg.Parent = line.eggFolder

	local distance = (line.lineEnd.Position - line.lineStart.Position).Magnitude
	local tween = TweenService:Create(egg, TweenInfo.new(distance / LineConfig.speed, Enum.EasingStyle.Linear), {
		CFrame = line.lineEnd,
	})
	tween.Completed:Connect(function()
		egg:Destroy()
		if running[player] ~= token then
			return
		end
		local data = PlayerData.Get(player)
		if data then
			data.Eggs += rarity.tokens
		end
		PlayerData.AddCash(player, value)
		popup(line.collectorTop, "+" .. Format.money(value), rarity.color)
		if rarityIndex >= NOTIFY_FROM_RARITY then
			Remotes.notify(player, string.format("%s jajko! +%s", rarity.name, Format.money(value)))
		end
	end)
	tween:Play()
end

function ProductionLineService.Start(player: Player)
	local token = {}
	running[player] = token
	task.spawn(function()
		while running[player] == token do
			spawnEgg(player, token)
			task.wait(LineConfig.interval)
		end
	end)
end

function ProductionLineService.Stop(player: Player)
	running[player] = nil
	local plot = PlotService.Get(player)
	if plot then
		plot.line.eggFolder:ClearAllChildren()
	end
end

return ProductionLineService
