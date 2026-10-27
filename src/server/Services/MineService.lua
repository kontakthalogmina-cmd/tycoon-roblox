-- Kopalnia gracza: skały z rudą na dnie wykopu i kopanie kilofem (RemoteEvent MineHit).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage.Shared.Config
local Ores = require(Config.Ores)
local Pickaxes = require(Config.Pickaxes)
local MineLevels = require(Config.MineLevels)
local OreNeeds = require(ReplicatedStorage.Shared.OreNeeds)
local SoundFx = require(ReplicatedStorage.Shared.SoundFx)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local MineService = {}

local HIT_DISTANCE = 18
local ROCK_COLOR = Color3.fromRGB(105, 100, 98)

-- [Player] = { plot, slots = { [i] = Model }, nodes = { [Model] = i }, pending = { [i] = true }, lastHit, folder }
local states = {}

local function pickOre(data)
	local candidates = OreNeeds.spawnable(Ores.list, data.MineLevel, data.FactoryLevel)
	local total = 0
	for _, ore in candidates do
		total += ore.weight
	end
	local roll = math.random() * total
	for _, ore in candidates do
		roll -= ore.weight
		if roll <= 0 then
			return ore
		end
	end
	return candidates[1]
end

local function updateMineLabel(player: Player)
	local state = states[player]
	local data = PlayerData.Get(player)
	if state and data then
		state.plot.mineLabel.Text = string.format("Kopalnia poz. %d", data.MineLevel)
	end
end

local function newPart(parent, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Skała z wbitymi kryształami/żyłami rudy.
local function buildNode(ore, base: CFrame)
	local model = Instance.new("Model")
	model.Name = ore.id

	local size = Vector3.new(math.random(36, 46) / 10, math.random(30, 40) / 10, math.random(36, 46) / 10)
	local rockCFrame = base * CFrame.new(0, size.Y / 2 - 0.4, 0) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(math.random(-8, 8)))
	local isPlainRock = ore.id == "stone"
	local rock = newPart(model, size, rockCFrame, isPlainRock and ore.color or ROCK_COLOR, Enum.Material.Slate)
	rock.Name = "Rock"
	-- Mniejsza skała obok, żeby bryła była mniej regularna.
	newPart(model, size * 0.6, rockCFrame * CFrame.new(size.X * 0.3, -size.Y * 0.15, -size.Z * 0.25) * CFrame.Angles(0.4, 0.7, 0.2), rock.Color, Enum.Material.Slate)

	if not isPlainRock then
		local glows = ore.material == Enum.Material.Glass
		for _ = 1, math.random(4, 6) do
			-- Punkt na powierzchni skały: losowy kierunek, wypchnięty do krawędzi.
			local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
			local offset = dir * (size / 2) * 0.95
			local crystalSize = Vector3.new(math.random(6, 14) / 10, math.random(10, 22) / 10, math.random(6, 14) / 10)
			local crystal = newPart(
				model,
				crystalSize,
				rockCFrame * CFrame.new(offset) * CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(math.rad(90), 0, math.random() * 3),
				ore.color,
				glows and Enum.Material.Neon or ore.material
			)
			crystal.Name = "Ore"
			if glows then
				crystal.Transparency = 0.15
			end
		end
		if glows or ore.id == "gold" then
			local glow = Instance.new("PointLight")
			glow.Color = ore.color
			glow.Range = 10
			glow.Brightness = 1.2
			glow.Parent = rock
		end
	end

	-- Odłamki przy uderzeniu (emitowane przez klienta).
	local debris = Instance.new("ParticleEmitter")
	debris.Name = "Debris"
	debris.Rate = 0
	debris.Color = ColorSequence.new(isPlainRock and ore.color or ore.color:Lerp(ROCK_COLOR, 0.3))
	debris.Size = NumberSequence.new(0.35, 0.1)
	debris.Lifetime = NumberRange.new(0.4, 0.8)
	debris.Speed = NumberRange.new(10, 18)
	debris.SpreadAngle = Vector2.new(70, 70)
	debris.Acceleration = Vector3.new(0, -50, 0)
	debris.EmissionDirection = Enum.NormalId.Top
	debris.Parent = rock

	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffset = Vector3.new(0, size.Y / 2 + 1.5, 0)
	gui.MaxDistance = 30
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = ore.color:Lerp(Color3.new(1, 1, 1), 0.5)
	label.TextStrokeTransparency = 0.2
	label.Text = string.format("%s (%d)", ore.name, ore.hp)
	label.Parent = gui
	gui.Parent = rock

	model.PrimaryPart = rock
	model:SetAttribute("OreId", ore.id)
	model:SetAttribute("HP", ore.hp)
	model:SetAttribute("Tier", ore.tier)
	return model
end

local function spawnOre(player: Player, state, index: number)
	local data = PlayerData.Get(player)
	if not data or states[player] ~= state then
		return
	end
	local ore = pickOre(data)
	local node = buildNode(ore, state.plot.minePositions[index])
	node.Parent = state.folder
	state.slots[index] = node
	state.nodes[node] = index
end

local function fillSlots(player: Player, state)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local slots = math.min(MineLevels[data.MineLevel].slots, PlotService.MAX_SLOTS)
	for i = 1, slots do
		if not state.slots[i] and not state.pending[i] then
			spawnOre(player, state, i)
		end
	end
end

local function onHit(player: Player, node)
	local state = states[player]
	if not state or typeof(node) ~= "Instance" then
		return
	end
	local index = state.nodes[node]
	if not index then
		return
	end
	local data = PlayerData.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	if (root.Position - node:GetPivot().Position).Magnitude > HIT_DISTANCE then
		Remotes.notify(player, "Podejdź bliżej do skały!")
		return
	end

	local pickaxe = Pickaxes.byId[data.EquippedPickaxe] or Pickaxes.list[1]
	local now = os.clock()
	-- Mały zapas na opóźnienia sieci.
	if now - state.lastHit < pickaxe.cooldown * 0.8 then
		return
	end
	state.lastHit = now

	local ore = Ores.byId[node:GetAttribute("OreId")]
	if pickaxe.tier < ore.tier then
		Remotes.notify(player, string.format("%s wymaga lepszego kilofa (poziom %d)!", ore.name, ore.tier))
		return
	end

	local hp = node:GetAttribute("HP") - pickaxe.damage
	local rockPart = node:FindFirstChild("Rock")
	local soundAt = rockPart and rockPart.Position or node:GetPivot().Position
	if hp > 0 then
		SoundFx.at("mineHit", soundAt, 0.12)
		node:SetAttribute("HP", hp)
		node.Rock.Info.Label.Text = string.format("%s (%d)", ore.name, hp)
		return
	end

	-- Skała rozbita.
	SoundFx.at("oreBreak", soundAt, 0.1)
	state.nodes[node] = nil
	state.slots[index] = nil
	node:Destroy()
	data.Ores[ore.id] = (data.Ores[ore.id] or 0) + ore.drop
	PlayerData.MarkChanged(player)

	state.pending[index] = true
	task.delay(MineLevels[data.MineLevel].respawn, function()
		if states[player] ~= state then
			return
		end
		state.pending[index] = nil
		spawnOre(player, state, index)
	end)
end

function MineService.Init()
	Remotes.MineHit.OnServerEvent:Connect(onHit)
end

function MineService.Start(player: Player)
	local plot = PlotService.Get(player)
	if not plot then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ores"
	folder.Parent = plot.model
	local state = { plot = plot, slots = {}, nodes = {}, pending = {}, lastHit = 0, folder = folder }
	states[player] = state
	fillSlots(player, state)
	updateMineLabel(player)
end

-- Po zmianie poziomu kopalni albo fabryki: usuwa skały z rudą, która nie jest już potrzebna,
-- i dokłada nowe miejsca na skały.
function MineService.Refresh(player: Player)
	local state = states[player]
	local data = PlayerData.Get(player)
	if not state or not data then
		return
	end
	local allowed = {}
	for _, ore in OreNeeds.spawnable(Ores.list, data.MineLevel, data.FactoryLevel) do
		allowed[ore.id] = true
	end
	for node, index in state.nodes do
		if not allowed[node:GetAttribute("OreId")] then
			state.nodes[node] = nil
			state.slots[index] = nil
			node:Destroy()
		end
	end
	fillSlots(player, state)
	updateMineLabel(player)
end

function MineService.Stop(player: Player)
	local state = states[player]
	if state then
		states[player] = nil
		state.folder:Destroy()
	end
end

return MineService
