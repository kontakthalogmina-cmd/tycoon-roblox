-- Buduje geometrię jednej działki: teren, fabrykę, linię produkcyjną i kopalnię pod ziemią.
-- Wszystkie pozycje są liczone względem środka działki (origin).
local PlotBuilder = {}

local PLOT_HALF = 150 -- działka ma 300x300 studs
local MINE_FLOOR_Y = -24
local MINE_GRID = 6
local MINE_CELL = 7

PlotBuilder.MAX_SLOTS = MINE_GRID * MINE_GRID
PlotBuilder.MINE_FLOOR_Y = MINE_FLOOR_Y

local function part(parent: Instance, cframe: CFrame, size: Vector3, color: Color3, material: Enum.Material?, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Pionowy walec (Shape.Cylinder ma oś wzdłuż X, więc obracamy go).
local function verticalCylinder(parent, position: CFrame, height: number, diameter: number, color, material)
	local p = part(parent, position * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(height, diameter, diameter), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function light(parent: BasePart, range: number, brightness: number, color: Color3)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color
	l.Parent = parent
	return l
end

local function billboard(parent: BasePart, offsetY: number, size: UDim2, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 200
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = parent
	return label
end

-- Napis na ścianie części, od strony face.
local function surfaceText(parent: BasePart, face: Enum.NormalId, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	gui.Parent = parent
end

local function buildTerrain(origin: CFrame)
	local terrain = workspace.Terrain
	local center = origin.Position
	local size = PLOT_HALF * 2 + 20
	terrain:FillBlock(CFrame.new(center + Vector3.new(0, -24, 0)), Vector3.new(size, 40, size), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(center + Vector3.new(0, -2, 0)), Vector3.new(size, 4, size), Enum.Material.Grass)
	-- Wykop kopalni: x 4..60, z 16..64, dno na MINE_FLOOR_Y.
	terrain:FillBlock(
		CFrame.new(center + Vector3.new(32, (MINE_FLOOR_Y + 4) / 2, 40)),
		Vector3.new(56, 4 - MINE_FLOOR_Y, 48),
		Enum.Material.Air
	)
	-- Ścieżka z placu startowego do fabryki i kopalni.
	terrain:FillBlock(CFrame.new(center + Vector3.new(-10, -2, 3)), Vector3.new(8, 4, 26), Enum.Material.Pavement)
	terrain:FillBlock(CFrame.new(center + Vector3.new(-26, -2, -10)), Vector3.new(36, 4, 8), Enum.Material.Pavement)
	terrain:FillBlock(CFrame.new(center + Vector3.new(0, -2, 14)), Vector3.new(30, 4, 8), Enum.Material.Pavement)
end

local function buildBoundary(model: Model, origin: CFrame)
	local walls = Instance.new("Folder")
	walls.Name = "Boundary"
	walls.Parent = model
	local h = 60
	for _, data in {
		{ Vector3.new(0, h / 2, PLOT_HALF), Vector3.new(PLOT_HALF * 2, h, 2) },
		{ Vector3.new(0, h / 2, -PLOT_HALF), Vector3.new(PLOT_HALF * 2, h, 2) },
		{ Vector3.new(PLOT_HALF, h / 2, 0), Vector3.new(2, h, PLOT_HALF * 2) },
		{ Vector3.new(-PLOT_HALF, h / 2, 0), Vector3.new(2, h, PLOT_HALF * 2) },
	} do
		part(walls, origin * CFrame.new(data[1]), data[2], Color3.new(1, 1, 1), nil, { Transparency = 1 })
	end
end

local function buildTrees(model: Model, origin: CFrame, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "Trees"
	folder.Parent = model
	for _ = 1, 40 do
		-- Drzewa tylko przy krawędziach działki.
		local x, z
		repeat
			x = rng:NextNumber(-PLOT_HALF + 8, PLOT_HALF - 8)
			z = rng:NextNumber(-PLOT_HALF + 8, PLOT_HALF - 8)
		until math.max(math.abs(x), math.abs(z)) > 100
		local height = rng:NextNumber(10, 16)
		local base = origin * CFrame.new(x, 0, z)
		verticalCylinder(folder, base * CFrame.new(0, height / 2, 0), height, 1.6, Color3.fromRGB(105, 70, 40), Enum.Material.Wood)
		local crown = part(
			folder,
			base * CFrame.new(0, height + 2, 0),
			Vector3.one * rng:NextNumber(8, 11),
			Color3.fromRGB(50, rng:NextInteger(110, 150), 50),
			Enum.Material.Grass
		)
		crown.Shape = Enum.PartType.Ball
	end
end

local function buildFactory(model: Model, origin: CFrame)
	local folder = Instance.new("Model")
	folder.Name = "Factory"
	folder.Parent = model
	local F = origin * CFrame.new(-40, 0, -30)

	local brick = Color3.fromRGB(155, 72, 55)
	local trim = Color3.fromRGB(60, 62, 70)

	part(folder, F * CFrame.new(0, 0.5, 0), Vector3.new(46, 1, 36), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	part(folder, F * CFrame.new(0, 9, 0), Vector3.new(40, 16, 30), brick, Enum.Material.Brick)
	-- Gzyms i dach
	part(folder, F * CFrame.new(0, 17.3, 0), Vector3.new(42, 0.6, 32), trim, Enum.Material.Metal)
	-- Dach szedowy (ząbkowany) jak w starych fabrykach
	for i = -1, 1 do
		local tooth = F * CFrame.new(i * 13, 20.2, 0)
		part(folder, tooth * CFrame.new(-2.6, 0, 0) * CFrame.Angles(0, 0, math.rad(-35)), Vector3.new(9.4, 0.5, 30), trim, Enum.Material.Metal)
		part(folder, tooth * CFrame.new(3.8, 0, 0), Vector3.new(0.4, 5.4, 30), Color3.fromRGB(170, 210, 230), Enum.Material.Glass, {
			Transparency = 0.35,
		})
	end
	-- Okna na dwóch dłuższych ścianach
	for _, side in { 1, -1 } do
		for i = -3, 3 do
			local window = F * CFrame.new(i * 5.2, 10.5, side * 15.05)
			part(folder, window, Vector3.new(3.4, 4.6, 0.3), Color3.fromRGB(150, 200, 230), Enum.Material.Glass, { Transparency = 0.25 })
			part(folder, window * CFrame.new(0, -2.6, side * 0.2), Vector3.new(4, 0.4, 0.5), Color3.fromRGB(220, 220, 220), Enum.Material.Concrete)
		end
	end
	-- Drzwi wejściowe z lampą
	part(folder, F * CFrame.new(0, 4.5, 15.1), Vector3.new(5, 7, 0.3), Color3.fromRGB(70, 45, 30), Enum.Material.WoodPlanks)
	local lamp = part(folder, F * CFrame.new(0, 8.7, 15.5), Vector3.new(1.2, 0.6, 0.8), Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
	light(lamp, 16, 1.5, Color3.fromRGB(255, 210, 150))
	-- Szyld
	local sign = part(folder, F * CFrame.new(0, 14.5, 15.3) * CFrame.Angles(0, math.pi, 0), Vector3.new(18, 3, 0.4), Color3.fromRGB(30, 32, 40), Enum.Material.Metal)
	surfaceText(sign, Enum.NormalId.Front, "FABRYKA JAJEK", Color3.fromRGB(255, 215, 90))
	-- Brama, którą wyjeżdża taśma
	part(folder, F * CFrame.new(20.1, 5, 0), Vector3.new(0.4, 8, 8), Color3.fromRGB(40, 40, 45), Enum.Material.DiamondPlate)
	for _, z in { -4.4, 4.4 } do
		part(folder, F * CFrame.new(20.3, 5, z), Vector3.new(0.6, 8.6, 0.8), Color3.fromRGB(240, 190, 30), Enum.Material.SmoothPlastic)
	end
	-- Kominy z dymem
	for i, x in { -14, -6 } do
		local height = 16 + i * 2
		local chimney = verticalCylinder(folder, F * CFrame.new(x, 17 + height / 2, -8), height, 3.6, brick, Enum.Material.Brick)
		chimney.Name = "Chimney"
		verticalCylinder(folder, F * CFrame.new(x, 17 + height - 1.5, -8), 1, 3.9, Color3.fromRGB(235, 235, 235), Enum.Material.Concrete)
		local smoke = Instance.new("Smoke")
		smoke.RiseVelocity = 8
		smoke.Size = 4
		smoke.Opacity = 0.15
		smoke.Color = Color3.fromRGB(200, 200, 200)
		smoke.Parent = chimney
	end
	-- Silosy i rury
	for _, z in { -7, 7 } do
		verticalCylinder(folder, F * CFrame.new(-26, 7.5, z), 13, 6, Color3.fromRGB(190, 195, 200), Enum.Material.Metal)
		local cap = part(folder, F * CFrame.new(-26, 14, z), Vector3.new(6, 6, 6), Color3.fromRGB(170, 175, 180), Enum.Material.Metal)
		cap.Shape = Enum.PartType.Ball
		local pipe = part(folder, F * CFrame.new(-21.5, 11, z), Vector3.new(4, 1, 1), Color3.fromRGB(120, 125, 130), Enum.Material.Metal)
		pipe.Shape = Enum.PartType.Cylinder
	end
	-- Wentylatory na dachu
	for _, x in { -12, 0, 12 } do
		part(folder, F * CFrame.new(x, 18.6, 10), Vector3.new(3, 2, 3), Color3.fromRGB(140, 145, 150), Enum.Material.DiamondPlate)
	end

	local labelAnchor = part(folder, F * CFrame.new(0, 26, 0), Vector3.one, Color3.new(), nil, {
		Transparency = 1,
		CanCollide = false,
	})
	return billboard(labelAnchor, 3, UDim2.fromOffset(260, 80), "Fabryka")
end

-- Taśma od bramy fabryki (x=-20) do skupu (x=50), wzdłuż z=-30.
local function buildProductionLine(model: Model, origin: CFrame)
	local folder = Instance.new("Model")
	folder.Name = "ProductionLine"
	folder.Parent = model

	local startX, endX, z = -20, 46, -30
	local length = endX - startX
	local mid = origin * CFrame.new((startX + endX) / 2, 0, z)

	part(folder, mid * CFrame.new(0, 3, 0), Vector3.new(length, 0.4, 5), Color3.fromRGB(35, 35, 38), Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		part(folder, mid * CFrame.new(0, 3.5, side * 2.8), Vector3.new(length, 0.9, 0.4), Color3.fromRGB(240, 190, 30), Enum.Material.Metal)
	end
	for x = startX + 3, endX - 1, 7 do
		for _, side in { -1, 1 } do
			part(folder, origin * CFrame.new(x, 1.4, z + side * 2.2), Vector3.new(0.6, 2.8, 0.6), Color3.fromRGB(90, 95, 100), Enum.Material.Metal)
		end
		local roller = part(folder, origin * CFrame.new(x, 2.6, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(5, 0.6, 0.6), Color3.fromRGB(150, 150, 155), Enum.Material.Metal)
		roller.Shape = Enum.PartType.Cylinder
	end

	-- Skup jajek na końcu taśmy
	local collector = part(folder, origin * CFrame.new(51, 5, z), Vector3.new(10, 10, 10), Color3.fromRGB(70, 140, 80), Enum.Material.WoodPlanks)
	part(folder, origin * CFrame.new(51, 10.4, z), Vector3.new(11, 0.8, 11), Color3.fromRGB(120, 50, 40), Enum.Material.Slate)
	part(folder, origin * CFrame.new(45.9, 4.5, z), Vector3.new(0.3, 3.5, 4.4), Color3.fromRGB(15, 15, 15))
	surfaceText(collector, Enum.NormalId.Back, "SKUP\nJAJEK", Color3.fromRGB(255, 255, 255))
	surfaceText(collector, Enum.NormalId.Front, "SKUP\nJAJEK", Color3.fromRGB(255, 255, 255))

	local eggs = Instance.new("Folder")
	eggs.Name = "Eggs"
	eggs.Parent = folder

	return {
		lineStart = origin * CFrame.new(startX + 1, 4.5, z),
		lineEnd = origin * CFrame.new(endX - 0.5, 4.5, z),
		collectorTop = origin * CFrame.new(51, 12, z),
		eggFolder = eggs,
	}
end

local function buildMine(model: Model, origin: CFrame, rng: Random)
	local folder = Instance.new("Model")
	folder.Name = "MineDecor"
	folder.Parent = model
	local wood = Color3.fromRGB(110, 75, 45)
	local floor = MINE_FLOOR_Y
	local depth = -floor

	-- Rampa w dół wzdłuż zachodniej ściany (x 4..14), od z=16 (góra) do z=64 (dół).
	local rampLength = math.sqrt(48 ^ 2 + depth ^ 2)
	local rampAngle = math.atan2(depth, 48)
	local ramp = origin * CFrame.new(9, floor / 2, 40) * CFrame.Angles(rampAngle, 0, 0)
	part(folder, ramp, Vector3.new(10, 1, rampLength), wood, Enum.Material.WoodPlanks)
	for _, x in { -4.8, 4.8 } do
		part(folder, ramp * CFrame.new(x, 2, 0), Vector3.new(0.4, 0.4, rampLength), wood, Enum.Material.Wood)
	end
	for i = -2, 2 do
		local post = ramp * CFrame.new(4.8, 1, i * 10)
		part(folder, CFrame.new(post.Position), Vector3.new(0.4, 2.4, 0.4), wood, Enum.Material.Wood)
	end

	-- Brama kopalni nad wejściem na rampę
	for _, x in { 3.6, 14.4 } do
		part(folder, origin * CFrame.new(x, 4.5, 15), Vector3.new(1.2, 9, 1.2), wood, Enum.Material.Wood)
	end
	local beam = part(folder, origin * CFrame.new(9, 9.3, 15), Vector3.new(12.6, 1.4, 1.4), wood, Enum.Material.Wood)
	local mineSign = part(folder, origin * CFrame.new(9, 11, 15), Vector3.new(9, 2, 0.4), Color3.fromRGB(60, 40, 25), Enum.Material.WoodPlanks)
	surfaceText(mineSign, Enum.NormalId.Front, "KOPALNIA", Color3.fromRGB(255, 220, 120))
	surfaceText(mineSign, Enum.NormalId.Back, "KOPALNIA", Color3.fromRGB(255, 220, 120))
	local mineLabel = billboard(beam, 6, UDim2.fromOffset(240, 50), "Kopalnia")

	-- Drewniane stemple i lampy przy ścianach wykopu
	local function support(position: Vector3, inward: Vector3)
		local base = origin * CFrame.new(position)
		part(folder, base * CFrame.new(0, floor / 2, 0), Vector3.new(1.2, depth, 1.2), wood, Enum.Material.Wood)
		local lantern = part(folder, base * CFrame.new(inward * 1.2 + Vector3.new(0, floor + 9, 0)), Vector3.new(0.8, 1.2, 0.8), Color3.fromRGB(255, 170, 70), Enum.Material.Neon)
		light(lantern, 20, 1.6, Color3.fromRGB(255, 180, 100))
	end
	for x = 22, 58, 12 do
		support(Vector3.new(x, 0, 16.8), Vector3.new(0, 0, 1))
		support(Vector3.new(x, 0, 63.2), Vector3.new(0, 0, -1))
	end
	for z = 26, 56, 10 do
		support(Vector3.new(59.2, 0, z), Vector3.new(-1, 0, 0))
	end
	part(folder, origin * CFrame.new(40, -0.8, 16.8), Vector3.new(40, 1.2, 1.2), wood, Enum.Material.Wood)
	part(folder, origin * CFrame.new(37, -0.8, 63.2), Vector3.new(46, 1.2, 1.2), wood, Enum.Material.Wood)
	part(folder, origin * CFrame.new(59.2, -0.8, 40), Vector3.new(1.2, 1.2, 48), wood, Enum.Material.Wood)

	-- Barierka wokół wykopu (oprócz wejścia na rampę)
	local function rail(from: Vector3, to: Vector3)
		local mid = (from + to) / 2
		local len = (to - from).Magnitude
		local cf = origin * CFrame.lookAt(mid + Vector3.new(0, 2.6, 0), to + Vector3.new(0, 2.6, 0))
		part(folder, cf, Vector3.new(0.4, 0.4, len), wood, Enum.Material.Wood)
		local steps = math.floor(len / 8)
		for i = 0, steps do
			local p = from:Lerp(to, i / math.max(steps, 1))
			part(folder, origin * CFrame.new(p + Vector3.new(0, 1.4, 0)), Vector3.new(0.5, 2.8, 0.5), wood, Enum.Material.Wood)
		end
	end
	rail(Vector3.new(15, 0, 15.5), Vector3.new(60.5, 0, 15.5))
	rail(Vector3.new(60.5, 0, 15.5), Vector3.new(60.5, 0, 64.5))
	rail(Vector3.new(60.5, 0, 64.5), Vector3.new(3.5, 0, 64.5))
	rail(Vector3.new(3.5, 0, 64.5), Vector3.new(3.5, 0, 15.5))

	-- Wózek kopalniany i luźne kamienie dla klimatu
	local cart = origin * CFrame.new(9, floor + 1.6, 58)
	part(folder, cart, Vector3.new(4, 2.4, 5), Color3.fromRGB(90, 90, 95), Enum.Material.CorrodedMetal)
	part(folder, cart * CFrame.new(0, 1.1, 0), Vector3.new(3.4, 0.6, 4.4), Color3.fromRGB(60, 60, 60), Enum.Material.Slate)
	for _ = 1, 10 do
		local pebble = part(
			folder,
			origin * CFrame.new(rng:NextNumber(16, 58), floor + 0.4, rng:NextNumber(18, 62)) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			Vector3.new(rng:NextNumber(0.6, 1.6), rng:NextNumber(0.5, 1), rng:NextNumber(0.6, 1.6)),
			Color3.fromRGB(95, 92, 90),
			Enum.Material.Slate,
			{ CanCollide = false }
		)
		pebble.Name = "Pebble"
	end

	-- Miejsca na skały z rudą: siatka 6x6 na dnie, kolejność od środka na zewnątrz.
	local positions = {}
	local half = (MINE_GRID - 1) / 2
	for gx = 0, MINE_GRID - 1 do
		for gz = 0, MINE_GRID - 1 do
			local jitter = Vector3.new(rng:NextNumber(-1.2, 1.2), 0, rng:NextNumber(-1.2, 1.2))
			local pos = Vector3.new(37 + (gx - half) * MINE_CELL, floor, 40 + (gz - half) * MINE_CELL) + jitter
			table.insert(positions, { cframe = origin * CFrame.new(pos), dist = Vector2.new(gx - half, gz - half).Magnitude })
		end
	end
	table.sort(positions, function(a, b)
		return a.dist < b.dist
	end)
	for i, entry in positions do
		positions[i] = entry.cframe
	end

	return mineLabel, positions
end

function PlotBuilder.Build(index: number, origin: CFrame, parent: Instance)
	local rng = Random.new(index * 7919)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	buildTerrain(origin)
	buildBoundary(model, origin)
	buildTrees(model, origin, rng)
	local factoryLabel = buildFactory(model, origin)
	local line = buildProductionLine(model, origin)
	local mineLabel, minePositions = buildMine(model, origin, rng)

	local sign = part(model, origin * CFrame.new(-10, 3, 24), Vector3.new(10, 4, 0.6), Color3.fromRGB(60, 40, 25), Enum.Material.WoodPlanks)
	local signLabel = billboard(sign, 4, UDim2.fromOffset(260, 50), "Wolna działka")

	model.Parent = parent

	return {
		index = index,
		model = model,
		owner = nil,
		spawnCFrame = origin * CFrame.new(-10, 4, 30),
		minePositions = minePositions,
		factoryLabel = factoryLabel,
		mineLabel = mineLabel,
		signLabel = signLabel,
		line = line,
	}
end

return PlotBuilder
