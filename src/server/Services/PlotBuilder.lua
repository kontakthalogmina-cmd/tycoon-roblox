-- Buduje geometrię jednej działki: teren, fabrykę, linię produkcyjną, sklep i kopalnię w górze.
-- Wszystkie pozycje są liczone względem środka działki (origin).
local PlotBuilder = {}

local PLOT_HALF = 150 -- działka ma 300x300 studs

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
		until math.max(math.abs(x), math.abs(z)) > 100 and (Vector2.new(x, z) - Vector2.new(55, 95)).Magnitude > 55
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

-- Góra z tunelem prowadzącym w dół do jaskini z rudami.
local CAVE_CENTER = Vector3.new(50, 0, 92)
local CAVE_FLOOR_Y = -12
local CAVE_RADIUS = 30
local TUNNEL_START = Vector3.new(6, 0, 46) -- wejście (na zewnątrz góry)
local TUNNEL_END = Vector3.new(30.7, CAVE_FLOOR_Y, 71.8) -- wylot w jaskini
local MAX_SLOTS = 36

local function tunnelPoint(t: number): Vector3
	return TUNNEL_START:Lerp(TUNNEL_END, t)
end

local function buildTerrain(origin: CFrame)
	local terrain = workspace.Terrain
	local o = origin.Position
	local size = PLOT_HALF * 2 + 20
	terrain:FillBlock(CFrame.new(o + Vector3.new(0, -24, 0)), Vector3.new(size, 40, size), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(o + Vector3.new(0, -2, 0)), Vector3.new(size, 4, size), Enum.Material.Grass)

	-- Góra z kilku nachodzących na siebie brył skalnych.
	terrain:FillBall(o + Vector3.new(50, -8, 92), 42, Enum.Material.Rock)
	terrain:FillBall(o + Vector3.new(28, -6, 70), 26, Enum.Material.Rock)
	terrain:FillBall(o + Vector3.new(76, -4, 106), 30, Enum.Material.Rock)
	terrain:FillBall(o + Vector3.new(56, 12, 100), 28, Enum.Material.Slate)
	terrain:FillBall(o + Vector3.new(40, 22, 104), 14, Enum.Material.Basalt)
	-- Trochę trawy i ziemi na zboczach.
	terrain:FillBall(o + Vector3.new(84, 6, 80), 12, Enum.Material.Grass)
	terrain:FillBall(o + Vector3.new(20, 6, 84), 12, Enum.Material.Ground)

	-- Jaskinia: płaska podłoga, nierówny strop.
	local cave = o + CAVE_CENTER
	terrain:FillCylinder(CFrame.new(cave + Vector3.new(0, CAVE_FLOOR_Y + 11, 0)), 22, CAVE_RADIUS, Enum.Material.Air)
	terrain:FillBall(cave + Vector3.new(0, CAVE_FLOOR_Y + 18, 0), 16, Enum.Material.Air)
	terrain:FillBall(cave + Vector3.new(-12, CAVE_FLOOR_Y + 16, 10), 11, Enum.Material.Air)
	terrain:FillBall(cave + Vector3.new(12, CAVE_FLOOR_Y + 16, -10), 11, Enum.Material.Air)
	terrain:FillCylinder(CFrame.new(cave + Vector3.new(0, CAVE_FLOOR_Y - 2, 0)), 4, CAVE_RADIUS, Enum.Material.Ground)

	-- Tunel: ciąg kul powietrza wzdłuż pochylni + utwardzona podłoga.
	local steps = 22
	for i = 0, steps do
		local p = tunnelPoint(i / steps)
		terrain:FillBall(o + p + Vector3.new(0, 6, 0), 9, Enum.Material.Air)
	end
	local a, b = o + TUNNEL_START, o + TUNNEL_END
	local floorCFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -1, 0)
	terrain:FillBlock(floorCFrame, Vector3.new(14, 2, (b - a).Magnitude + 8), Enum.Material.Ground)

	-- Ścieżki z placu startowego do fabryki i do wejścia kopalni.
	terrain:FillBlock(CFrame.new(o + Vector3.new(-10, -2, 3)), Vector3.new(8, 4, 26), Enum.Material.Pavement)
	terrain:FillBlock(CFrame.new(o + Vector3.new(-26, -2, -10)), Vector3.new(36, 4, 8), Enum.Material.Pavement)
	terrain:FillBlock(CFrame.lookAt(o + Vector3.new(-2, -2, 38), o + Vector3.new(6, -2, 46)), Vector3.new(7, 4, 24), Enum.Material.Pavement)
end

local function buildMine(model: Model, origin: CFrame, rng: Random)
	local folder = Instance.new("Model")
	folder.Name = "MineDecor"
	folder.Parent = model
	local wood = Color3.fromRGB(105, 72, 42)
	local darkWood = Color3.fromRGB(75, 50, 30)
	local lanternColor = Color3.fromRGB(255, 170, 80)

	local horizontal = (TUNNEL_END - TUNNEL_START) * Vector3.new(1, 0, 1)
	local forward = horizontal.Unit
	local slopeLength = (TUNNEL_END - TUNNEL_START).Magnitude

	local function lantern(position: Vector3)
		local l = part(folder, origin * CFrame.new(position), Vector3.new(0.7, 1, 0.7), lanternColor, Enum.Material.Neon)
		light(l, 22, 1.8, lanternColor)
		local flame = Instance.new("Fire")
		flame.Size = 1
		flame.Heat = 2
		flame.Parent = l
		return l
	end

	-- Drewniane odrzwia (stemple) co kilka metrów w tunelu.
	local frames = 7
	for i = 0, frames do
		local t = (i + 0.3) / (frames + 0.6)
		local p = tunnelPoint(t)
		local frame = origin * CFrame.lookAt(p, p + forward)
		for _, side in { -1, 1 } do
			part(folder, frame * CFrame.new(side * 6, 5.5, 0), Vector3.new(1, 11, 1), wood, Enum.Material.Wood)
		end
		part(folder, frame * CFrame.new(0, 11.4, 0), Vector3.new(13, 1, 1.1), wood, Enum.Material.Wood)
		if i % 2 == 0 then
			lantern((frame * CFrame.new(0, 10.4, 0)).Position - origin.Position)
		end
	end

	-- Tory z podkładami wzdłuż tunelu.
	local railA, railB = TUNNEL_START + forward * 2, TUNNEL_END
	local railFrame = CFrame.lookAt(railA, railB)
	for _, side in { -1.1, 1.1 } do
		part(folder, origin * railFrame * CFrame.new(side, 0.25, -slopeLength / 2), Vector3.new(0.25, 0.25, slopeLength), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)
	end
	for d = 1, slopeLength - 1, 2.2 do
		part(folder, origin * railFrame * CFrame.new(0, 0.08, -d), Vector3.new(3.2, 0.2, 0.7), darkWood, Enum.Material.Wood)
	end

	-- Wejście: masywna rama z belek, tablica i kamienie.
	local gate = origin * CFrame.lookAt(TUNNEL_START + forward * 3, TUNNEL_START + forward * 4)
	for _, side in { -1, 1 } do
		part(folder, gate * CFrame.new(side * 7.5, 7, 0), Vector3.new(1.8, 14, 1.8), darkWood, Enum.Material.Wood)
	end
	local beam = part(folder, gate * CFrame.new(0, 14.6, 0), Vector3.new(17.4, 1.8, 2), darkWood, Enum.Material.Wood)
	local mineSign = part(folder, gate * CFrame.new(0, 16.8, -0.2), Vector3.new(11, 2.6, 0.4), Color3.fromRGB(60, 40, 25), Enum.Material.WoodPlanks)
	surfaceText(mineSign, Enum.NormalId.Back, "KOPALNIA", Color3.fromRGB(255, 220, 120))
	surfaceText(mineSign, Enum.NormalId.Front, "KOPALNIA", Color3.fromRGB(255, 220, 120))
	local mineLabel = billboard(beam, 6, UDim2.fromOffset(240, 50), "Kopalnia")
	lantern((gate * CFrame.new(-7.5, 9, -1.4)).Position - origin.Position)
	lantern((gate * CFrame.new(7.5, 9, -1.4)).Position - origin.Position)
	for _ = 1, 6 do
		local side = rng:NextNumber() < 0.5 and -1 or 1
		local boulder = part(
			folder,
			gate * CFrame.new(side * rng:NextNumber(10, 14), 0.6, rng:NextNumber(-5, -1)) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			Vector3.new(rng:NextNumber(1.5, 3.5), rng:NextNumber(1.2, 2.5), rng:NextNumber(1.5, 3.5)),
			Color3.fromRGB(110, 105, 100),
			Enum.Material.Slate
		)
		boulder.Name = "Boulder"
	end

	-- Jaskinia: lampy na ścianach, wózek przy wylocie tunelu, drobne kamienie.
	local tunnelAngle = math.atan2(TUNNEL_END.Z - CAVE_CENTER.Z, TUNNEL_END.X - CAVE_CENTER.X)
	for i = 0, 7 do
		local angle = tunnelAngle + math.rad(22.5) + i * math.rad(45)
		local p = CAVE_CENTER + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (CAVE_RADIUS - 1.2)
		part(folder, origin * CFrame.new(p + Vector3.new(0, CAVE_FLOOR_Y + 5, 0)), Vector3.new(1, 10, 1), wood, Enum.Material.Wood)
		lantern(p + Vector3.new(0, CAVE_FLOOR_Y + 10.6, 0) - Vector3.new(math.cos(angle), 0, math.sin(angle)) * 0.8)
	end
	local cartPos = TUNNEL_END + forward * 1.5 + Vector3.new(0, 1.4, 0)
	local cart = origin * CFrame.lookAt(cartPos, cartPos + forward)
	part(folder, cart, Vector3.new(3.4, 2.2, 4.6), Color3.fromRGB(85, 85, 90), Enum.Material.CorrodedMetal)
	part(folder, cart * CFrame.new(0, 1.15, 0), Vector3.new(3, 0.5, 4.2), Color3.fromRGB(60, 58, 55), Enum.Material.Slate)
	for _, x in { -1.8, 1.8 } do
		for _, z in { -1.5, 1.5 } do
			local wheel = part(folder, cart * CFrame.new(x, -1, z), Vector3.new(0.4, 1.2, 1.2), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	for _ = 1, 14 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, CAVE_RADIUS - 3)
		local p = CAVE_CENTER + Vector3.new(math.cos(angle) * r, CAVE_FLOOR_Y + 0.3, math.sin(angle) * r)
		local pebble = part(
			folder,
			origin * CFrame.new(p) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0),
			Vector3.new(rng:NextNumber(0.6, 1.6), rng:NextNumber(0.4, 0.9), rng:NextNumber(0.6, 1.6)),
			Color3.fromRGB(95, 90, 85),
			Enum.Material.Slate,
			{ CanCollide = false }
		)
		pebble.Name = "Pebble"
	end

	-- Miejsca na skały z rudą: środek, wewnętrzny pierścień i przy ścianach (poza wylotem tunelu).
	local positions = {}
	local function add(angle: number, radius: number)
		local p = CAVE_CENTER + Vector3.new(math.cos(angle) * radius, CAVE_FLOOR_Y, math.sin(angle) * radius)
		local facing = CAVE_CENTER * Vector3.new(1, 0, 1) + Vector3.new(0, CAVE_FLOOR_Y, 0)
		local cf = (radius > 0.5) and CFrame.lookAt(p, facing) or CFrame.new(p)
		table.insert(positions, { cframe = origin * cf, dist = radius })
	end
	for i = 0, 4 do
		add(i * math.pi * 2 / 5 + 0.3, 5.5)
	end
	for i = 0, 11 do
		add(i * math.pi * 2 / 12, 14)
	end
	local wallCount = MAX_SLOTS - 17
	for i = 0, wallCount - 1 do
		add(tunnelAngle + math.rad(24) + i * math.rad(16.6), CAVE_RADIUS - 3.5)
	end
	table.sort(positions, function(x, y)
		return x.dist < y.dist
	end)
	for k, entry in positions do
		positions[k] = entry.cframe
	end

	return mineLabel, positions
end

-- Budka sklepu z ulepszeniami obok placu startowego.
local function buildShop(model: Model, origin: CFrame)
	local folder = Instance.new("Model")
	folder.Name = "Shop"
	folder.Parent = model
	local base = origin * CFrame.lookAt(Vector3.new(-30, 0, 34), Vector3.new(-10, 0, 34))
	local wood = Color3.fromRGB(150, 100, 60)

	local counter = part(folder, base * CFrame.new(0, 1.8, 0), Vector3.new(10, 3.6, 3), wood, Enum.Material.WoodPlanks)
	part(folder, base * CFrame.new(0, 3.75, -0.2), Vector3.new(10.6, 0.3, 3.6), Color3.fromRGB(230, 220, 200), Enum.Material.Marble)
	part(folder, base * CFrame.new(0, 4, 3), Vector3.new(10, 8, 0.6), wood, Enum.Material.WoodPlanks)
	for _, x in { -4.8, 4.8 } do
		part(folder, base * CFrame.new(x, 4.5, -1.2), Vector3.new(0.6, 9, 0.6), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	end
	-- Pasiasta markiza
	for k = 0, 7 do
		local color = k % 2 == 0 and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(250, 250, 250)
		part(folder, base * CFrame.new(-4.4 + k * 1.26, 9.2, 0.3) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(1.26, 0.2, 6), color, Enum.Material.Fabric)
	end
	local sign = part(folder, base * CFrame.new(0, 10.8, 2.6), Vector3.new(8, 2, 0.4), Color3.fromRGB(40, 30, 25), Enum.Material.Wood)
	surfaceText(sign, Enum.NormalId.Front, "SKLEP", Color3.fromRGB(255, 215, 90))
	-- Skrzynki z towarem
	for k, x in { -3, 0, 3 } do
		local colors = { Color3.fromRGB(90, 230, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(230, 30, 60) }
		local gem = part(folder, base * CFrame.new(x, 4.6, -0.2), Vector3.new(0.9, 1.3, 0.9), colors[k], Enum.Material.Neon)
		gem.CFrame *= CFrame.Angles(0, math.rad(45), 0)
	end
	light(counter, 14, 1, Color3.fromRGB(255, 230, 180))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Otwórz sklep"
	prompt.ObjectText = "Sklep z ulepszeniami"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	return prompt
end

PlotBuilder.MAX_SLOTS = MAX_SLOTS

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
	local shopPrompt = buildShop(model, origin)

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
		shopPrompt = shopPrompt,
	}
end

return PlotBuilder
