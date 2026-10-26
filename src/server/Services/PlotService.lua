-- Buduje działki graczy (fabryka + kopalnia) i przydziela je wchodzącym graczom.
local PlotService = {}

local PLOT_COUNT = 8
local PLOT_SIZE = 140
local PLOT_SPACING = 170
local MINE_GRID = 6 -- 6x6 = 36 miejsc na bloki
local MINE_CELL = 7

local plots = {} -- lista działek
local byPlayer = {} -- [Player] = plot

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	return p
end

local function billboard(parent: BasePart, offsetY: number, size: UDim2)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parent
	return label
end

local function buildPlot(index: number)
	local row = (index - 1) // 4
	local col = (index - 1) % 4
	local origin = CFrame.new((col - 1.5) * PLOT_SPACING, 0, (row - 0.5) * PLOT_SPACING)

	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	local base = part({
		Name = "Base",
		Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(86, 150, 70),
		Material = Enum.Material.Grass,
	})
	base.Parent = model

	local factory = part({
		Name = "Factory",
		Size = Vector3.new(34, 20, 30),
		CFrame = origin * CFrame.new(-35, 11, -30),
		Color = Color3.fromRGB(120, 120, 135),
		Material = Enum.Material.Concrete,
	})
	factory.Parent = model
	local chimney = part({
		Name = "Chimney",
		Size = Vector3.new(5, 14, 5),
		CFrame = origin * CFrame.new(-45, 28, -38),
		Color = Color3.fromRGB(150, 60, 50),
		Material = Enum.Material.Brick,
	})
	chimney.Parent = model
	local smoke = Instance.new("Smoke")
	smoke.RiseVelocity = 6
	smoke.Size = 3
	smoke.Parent = chimney
	local factoryLabel = billboard(factory, 16, UDim2.fromOffset(240, 70))
	factoryLabel.Text = "Fabryka"

	local mineCenter = origin * CFrame.new(25, 0, 15)
	local mineFloor = part({
		Name = "MineFloor",
		Size = Vector3.new(MINE_GRID * MINE_CELL + 6, 1, MINE_GRID * MINE_CELL + 6),
		CFrame = mineCenter * CFrame.new(0, 1.05, 0),
		Color = Color3.fromRGB(90, 70, 55),
		Material = Enum.Material.Ground,
	})
	mineFloor.Parent = model
	local mineLabel = billboard(mineFloor, 12, UDim2.fromOffset(240, 60))
	mineLabel.Text = "Kopalnia"

	local minePositions = {}
	-- Kolejność od środka na zewnątrz, żeby niskie poziomy miały zwarty układ.
	local half = (MINE_GRID - 1) / 2
	for x = 0, MINE_GRID - 1 do
		for z = 0, MINE_GRID - 1 do
			local offset = Vector3.new((x - half) * MINE_CELL, 4.05, (z - half) * MINE_CELL)
			table.insert(minePositions, { cframe = mineCenter * CFrame.new(offset), dist = Vector2.new(x - half, z - half).Magnitude })
		end
	end
	table.sort(minePositions, function(a, b)
		return a.dist < b.dist
	end)
	for i, entry in minePositions do
		minePositions[i] = entry.cframe
	end

	local sign = part({
		Name = "Sign",
		Size = Vector3.new(16, 6, 1),
		CFrame = origin * CFrame.new(0, 6, 60),
		Color = Color3.fromRGB(60, 40, 25),
		Material = Enum.Material.Wood,
	})
	sign.Parent = model
	local signLabel = billboard(sign, 5, UDim2.fromOffset(260, 50))
	signLabel.Text = "Wolna działka"

	model.PrimaryPart = base
	model.Parent = workspace:FindFirstChild("Plots")

	return {
		index = index,
		model = model,
		owner = nil,
		spawnCFrame = origin * CFrame.new(0, 5, 45),
		minePositions = minePositions,
		factoryLabel = factoryLabel,
		mineLabel = mineLabel,
		signLabel = signLabel,
	}
end

function PlotService.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace
	for i = 1, PLOT_COUNT do
		plots[i] = buildPlot(i)
	end
end

local function teleport(player: Player, plot)
	local character = player.Character
	if character then
		task.defer(function()
			character:PivotTo(plot.spawnCFrame)
		end)
	end
end

function PlotService.Assign(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plot.signLabel.Text = "Działka: " .. player.DisplayName
			byPlayer[player] = plot
			player.CharacterAdded:Connect(function()
				teleport(player, plot)
			end)
			teleport(player, plot)
			return plot
		end
	end
	return nil
end

function PlotService.Get(player: Player)
	return byPlayer[player]
end

function PlotService.Release(player: Player)
	local plot = byPlayer[player]
	if plot then
		plot.owner = nil
		plot.signLabel.Text = "Wolna działka"
		plot.factoryLabel.Text = "Fabryka"
		plot.mineLabel.Text = "Kopalnia"
		byPlayer[player] = nil
	end
end

PlotService.MAX_SLOTS = MINE_GRID * MINE_GRID
PlotService.PLOT_COUNT = PLOT_COUNT
-- Maks. liczba graczy na serwerze ustaw w Game Settings na <= PLOT_COUNT.

return PlotService
