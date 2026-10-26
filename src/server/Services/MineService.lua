-- Kopalnia gracza: spawnowanie bloków surowców i kopanie (ClickDetector).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage.Shared.Config
local Ores = require(Config.Ores)
local Pickaxes = require(Config.Pickaxes)
local MineLevels = require(Config.MineLevels)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local MineService = {}

local CLICK_DISTANCE = 24
local states = {} -- [Player] = { plot, slots = { [i] = Part }, pending = { [i] = true }, lastHit = number, folder }

local function pickOre(mineLevel: number)
	local total = 0
	for _, ore in Ores.list do
		if ore.minMineLevel <= mineLevel then
			total += ore.weight
		end
	end
	local roll = math.random() * total
	for _, ore in Ores.list do
		if ore.minMineLevel <= mineLevel then
			roll -= ore.weight
			if roll <= 0 then
				return ore
			end
		end
	end
	return Ores.list[1]
end

local function updateMineLabel(player: Player)
	local state = states[player]
	local data = PlayerData.Get(player)
	if state and data then
		state.plot.mineLabel.Text = string.format("Kopalnia poz. %d", data.MineLevel)
	end
end

local onHit -- forward

local function spawnOre(player: Player, state, index: number)
	local data = PlayerData.Get(player)
	if not data or states[player] ~= state then
		return
	end
	local ore = pickOre(data.MineLevel)

	local block = Instance.new("Part")
	block.Name = ore.id
	block.Anchored = true
	block.Size = Vector3.new(5, 5, 5)
	block.CFrame = state.plot.minePositions[index]
	block.Color = ore.color
	block.Material = ore.material
	block:SetAttribute("OreId", ore.id)
	block:SetAttribute("HP", ore.hp)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 35
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = string.format("%s (%d)", ore.name, ore.hp)
	label.Parent = gui
	gui.Parent = block

	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = CLICK_DISTANCE
	detector.MouseClick:Connect(function(clicker)
		onHit(clicker, player, state, index, block, ore)
	end)
	detector.Parent = block

	block.Parent = state.folder
	state.slots[index] = block
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

onHit = function(clicker: Player, owner: Player, state, index: number, block: BasePart, ore)
	if clicker ~= owner then
		Remotes.notify(clicker, "To nie Twoja kopalnia!")
		return
	end
	if states[owner] ~= state or state.slots[index] ~= block then
		return
	end
	local data = PlayerData.Get(owner)
	if not data then
		return
	end
	local pickaxe = Pickaxes.byId[data.EquippedPickaxe] or Pickaxes.list[1]

	local now = os.clock()
	if now - state.lastHit < pickaxe.cooldown then
		return
	end
	state.lastHit = now

	if pickaxe.tier < ore.tier then
		Remotes.notify(owner, string.format("%s wymaga lepszego kilofa (poziom %d)!", ore.name, ore.tier))
		return
	end

	local hp = block:GetAttribute("HP") - pickaxe.damage
	if hp > 0 then
		block:SetAttribute("HP", hp)
		block.BillboardGui.Label.Text = string.format("%s (%d)", ore.name, hp)
		return
	end

	-- Blok wykopany.
	block:Destroy()
	state.slots[index] = nil
	data.Ores[ore.id] = (data.Ores[ore.id] or 0) + ore.drop
	PlayerData.MarkChanged(owner)

	state.pending[index] = true
	task.delay(MineLevels[data.MineLevel].respawn, function()
		if states[owner] ~= state then
			return
		end
		state.pending[index] = nil
		spawnOre(owner, state, index)
	end)
end

function MineService.Start(player: Player)
	local plot = PlotService.Get(player)
	if not plot then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ores"
	folder.Parent = plot.model
	local state = { plot = plot, slots = {}, pending = {}, lastHit = 0, folder = folder }
	states[player] = state
	fillSlots(player, state)
	updateMineLabel(player)
end

-- Po ulepszeniu kopalni: dokłada nowe miejsca na bloki.
function MineService.Refresh(player: Player)
	local state = states[player]
	if state then
		fillSlots(player, state)
		updateMineLabel(player)
	end
end

function MineService.Stop(player: Player)
	local state = states[player]
	if state then
		states[player] = nil
		state.folder:Destroy()
	end
end

return MineService
