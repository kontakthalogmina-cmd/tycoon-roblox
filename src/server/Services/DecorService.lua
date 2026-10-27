-- Dekoracje bazy kupowane za $: kwiaty, ławki, drzewa, flagi, fontanna i pomnik złotej kury.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Decorations = require(ReplicatedStorage.Shared.Config.Decorations)
local SoundFx = require(ReplicatedStorage.Shared.SoundFx)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local DecorService = {}

local function part(parent: Instance, cframe: CFrame, size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- Walec stojący pionowo (Shape.Cylinder ma oś wzdłuż X).
local function column(parent, cframe: CFrame, height: number, diameter: number, color: Color3, material)
	return part(parent, cframe * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(height, diameter, diameter), color, material, Enum.PartType.Cylinder)
end

local FLOWER_COLORS = {
	Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 220, 60), Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 140, 40), Color3.fromRGB(250, 250, 250),
}

local builders = {}

function builders.flowers(model: Model, base: CFrame, rng: Random)
	part(model, base * CFrame.new(0, 0.4, 0), Vector3.new(10, 0.8, 4), Color3.fromRGB(90, 60, 40), Enum.Material.Ground)
	part(model, base * CFrame.new(0, 0.5, 0), Vector3.new(10.6, 0.6, 4.6), Color3.fromRGB(200, 195, 185), Enum.Material.Cobblestone).CanCollide = false
	for _ = 1, 16 do
		local x, z = rng:NextNumber(-4.4, 4.4), rng:NextNumber(-1.6, 1.6)
		part(model, base * CFrame.new(x, 1.1, z), Vector3.new(0.15, 0.8, 0.15), Color3.fromRGB(60, 140, 50)).CanCollide = false
		local flower = part(model, base * CFrame.new(x, 1.6, z), Vector3.one * rng:NextNumber(0.6, 0.9), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], nil, Enum.PartType.Ball)
		flower.CanCollide = false
	end
end

function builders.bench(model: Model, base: CFrame)
	local wood = Color3.fromRGB(140, 95, 55)
	part(model, base * CFrame.new(0, 1.6, 0), Vector3.new(5, 0.4, 1.6), wood, Enum.Material.WoodPlanks)
	part(model, base * CFrame.new(0, 2.6, 0.75), Vector3.new(5, 1.6, 0.3), wood, Enum.Material.WoodPlanks)
	for _, x in { -2, 2 } do
		part(model, base * CFrame.new(x, 0.7, 0), Vector3.new(0.4, 1.4, 1.4), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
	end
	local seat = Instance.new("Seat")
	seat.Anchored = true
	seat.Transparency = 1
	seat.Size = Vector3.new(4, 0.4, 1.4)
	seat.CFrame = base * CFrame.new(0, 1.7, 0)
	seat.Parent = model
end

function builders.tree(model: Model, base: CFrame, rng: Random)
	local height = rng:NextNumber(14, 18)
	column(model, base * CFrame.new(0, height / 2, 0), height, 2.2, Color3.fromRGB(105, 70, 40), Enum.Material.Wood)
	for _, offset in { Vector3.new(0, height + 2, 0), Vector3.new(2.5, height - 0.5, 1), Vector3.new(-2.5, height, -1.2) } do
		part(model, base * CFrame.new(offset), Vector3.one * rng:NextNumber(7, 10), Color3.fromRGB(50, rng:NextInteger(120, 160), 55), Enum.Material.Grass, Enum.PartType.Ball)
	end
end

function builders.flag(model: Model, base: CFrame)
	column(model, base * CFrame.new(0, 7, 0), 14, 0.5, Color3.fromRGB(220, 220, 225), Enum.Material.Metal)
	local ball = part(model, base * CFrame.new(0, 14.3, 0), Vector3.one * 0.9, Color3.fromRGB(255, 200, 60), Enum.Material.Foil, Enum.PartType.Ball)
	ball.CanCollide = false
	part(model, base * CFrame.new(2.4, 12, 0), Vector3.new(4.4, 2.8, 0.15), Color3.fromRGB(255, 190, 40), Enum.Material.Fabric).CanCollide = false
	part(model, base * CFrame.new(2.4, 12, 0), Vector3.new(4.4, 0.6, 0.18), Color3.fromRGB(230, 60, 60), Enum.Material.Fabric).CanCollide = false
end

function builders.fountain(model: Model, base: CFrame)
	local stone = Color3.fromRGB(200, 195, 185)
	column(model, base * CFrame.new(0, 0.2, 0), 0.4, 18, Color3.fromRGB(170, 165, 155), Enum.Material.Cobblestone)
	column(model, base * CFrame.new(0, 1, 0), 2, 11, stone, Enum.Material.Marble)
	local water = column(model, base * CFrame.new(0, 1.6, 0), 1.6, 10, Color3.fromRGB(70, 150, 220), Enum.Material.Glass)
	water.Transparency = 0.35
	water.CanCollide = false
	column(model, base * CFrame.new(0, 3.5, 0), 4, 1.4, stone, Enum.Material.Marble)
	local top = column(model, base * CFrame.new(0, 5.6, 0), 0.6, 4, stone, Enum.Material.Marble)
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	spray.Transparency = NumberSequence.new(0.3, 1)
	spray.Size = NumberSequence.new(0.4, 0.1)
	spray.Lifetime = NumberRange.new(0.8, 1.2)
	spray.Rate = 60
	spray.Speed = NumberRange.new(8, 11)
	spray.SpreadAngle = Vector2.new(20, 20)
	spray.Acceleration = Vector3.new(0, -30, 0)
	spray.EmissionDirection = Enum.NormalId.Right -- walec leży na boku, Right = w górę
	spray.Parent = top
end

function builders.statue(model: Model, base: CFrame)
	local gold = Color3.fromRGB(255, 200, 50)
	part(model, base * CFrame.new(0, 1.5, 0), Vector3.new(8, 3, 8), Color3.fromRGB(235, 230, 220), Enum.Material.Marble)
	part(model, base * CFrame.new(0, 3.2, 0), Vector3.new(7, 0.4, 7), Color3.fromRGB(90, 85, 80), Enum.Material.Slate)
	part(model, base * CFrame.new(0, 6.5, 0), Vector3.new(6, 6, 6), gold, Enum.Material.Foil, Enum.PartType.Ball)
	part(model, base * CFrame.new(0, 10.5, -1.5), Vector3.new(3.6, 3.6, 3.6), gold, Enum.Material.Foil, Enum.PartType.Ball)
	part(model, base * CFrame.new(0, 10.3, -3.5), Vector3.new(1, 0.7, 1.4), Color3.fromRGB(255, 140, 30), Enum.Material.Foil)
	part(model, base * CFrame.new(0, 12.6, -1.5), Vector3.new(0.6, 1.4, 2), Color3.fromRGB(230, 50, 50), Enum.Material.SmoothPlastic)
	part(model, base * CFrame.new(0, 8, 3.2) * CFrame.Angles(math.rad(-30), 0, 0), Vector3.new(4, 3, 1), gold, Enum.Material.Foil)
	for _, x in { -0.8, 0.8 } do
		part(model, base * CFrame.new(x, 11, -3.1), Vector3.new(0.4, 0.4, 0.2), Color3.new(0.05, 0.05, 0.05))
	end
	local glow = Instance.new("PointLight")
	glow.Color = gold
	glow.Range = 20
	glow.Brightness = 1.5
	glow.Parent = model:FindFirstChildOfClass("Part")
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = gold
	sparkles.Parent = model:FindFirstChildOfClass("Part")
end

local function decorFolder(plot)
	local folder = plot.model:FindFirstChild("Decorations")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Decorations"
		folder.Parent = plot.model
	end
	return folder
end

function DecorService.Refresh(player: Player)
	local plot = PlotService.Get(player)
	local data = PlayerData.Get(player)
	if not plot or not data then
		return
	end
	local folder = decorFolder(plot)
	folder:ClearAllChildren()
	local rng = Random.new(plot.index * 31)
	for _, decoration in Decorations.list do
		local count = math.min(data.Decorations[decoration.id] or 0, decoration.max)
		for i = 1, count do
			local slot = Decorations.slots[decoration.id][i]
			local position = slot[1]
			local localCFrame = slot[2] and CFrame.lookAt(position, slot[2]) or CFrame.new(position)
			local model = Instance.new("Model")
			model.Name = decoration.id
			builders[decoration.id](model, plot.origin * localCFrame, rng)
			model.Parent = folder
		end
	end
end

function DecorService.Clear(player: Player)
	local plot = PlotService.Get(player)
	if plot then
		decorFolder(plot):ClearAllChildren()
	end
end

local function buy(player: Player, decorationId)
	local data = PlayerData.Get(player)
	local decoration = type(decorationId) == "string" and Decorations.byId[decorationId]
	if not data or not decoration then
		return
	end
	local owned = data.Decorations[decoration.id] or 0
	if owned >= decoration.max then
		Remotes.notify(player, "Nie ma już miejsca na: " .. decoration.name .. ".")
		return
	end
	if data.Cash < decoration.price then
		Remotes.notify(player, "Za mało pieniędzy na: " .. decoration.name .. ".")
		return
	end
	data.Cash -= decoration.price
	data.Decorations[decoration.id] = owned + 1
	PlayerData.MarkChanged(player)
	DecorService.Refresh(player)
	local plot = PlotService.Get(player)
	local slot = Decorations.slots[decoration.id][owned + 1]
	if plot and slot then
		SoundFx.at("buy", (plot.origin * CFrame.new(slot[1])).Position)
	end
	Remotes.notify(player, string.format("%s Postawiono: %s (%d/%d)", decoration.icon, decoration.name, owned + 1, decoration.max))
end

function DecorService.Init()
	Remotes.BuyDecoration.OnServerEvent:Connect(buy)
end

return DecorService
