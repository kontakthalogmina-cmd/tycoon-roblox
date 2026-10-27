-- Budowle obronne na działce: miny, niewidzialne pułapki, działa i wieże czarodzieja.
-- Atakują każdego obcego gracza na działce właściciela. Wszystko liczy serwer.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Defenses = require(ReplicatedStorage.Shared.Config.Defenses)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local CombatService = require(script.Parent.CombatService)
local Remotes = require(script.Parent.Remotes)

local DefenseService = {}

local TICK = 0.2
local built = {} -- [Player] = { { defense, model, aim, cooldownUntil, position } }

local function part(parent: Instance, cframe: CFrame, size: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function upright(cf: CFrame)
	return cf * CFrame.Angles(0, 0, math.pi / 2) -- walec stoi pionowo
end

-- Modele budowli ---------------------------------------------------------

local builders = {}

function builders.mine(model: Model, base: CFrame)
	part(model, upright(base * CFrame.new(0, 0.15, 0)), Vector3.new(0.3, 2.6, 2.6), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, Enum.PartType.Cylinder)
	local light = part(model, base * CFrame.new(0, 0.4, 0), Vector3.new(0.5, 0.3, 0.5), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	light.Name = "Aim"
	return light
end

function builders.trap(model: Model, base: CFrame)
	local plate = part(model, base * CFrame.new(0, 0.1, 0), Vector3.new(5, 0.2, 5), Color3.fromRGB(120, 120, 130), Enum.Material.DiamondPlate)
	plate.Name = "Aim"
	for x = -1.5, 1.5, 1.5 do
		for z = -1.5, 1.5, 1.5 do
			part(model, base * CFrame.new(x, 0.6, z) * CFrame.Angles(0, math.rad(45), 0), Vector3.new(0.3, 1, 0.3), Color3.fromRGB(180, 180, 190), Enum.Material.Metal)
		end
	end
	-- Niewidzialna dla innych: serwer ustawia pełną przezroczystość, właściciel widzi ją u siebie.
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Transparency = 1
			p.CanCollide = false
			CollectionService:AddTag(p, "OwnerVisible")
		end
	end
	return plate
end

function builders.cannon(model: Model, base: CFrame)
	part(model, base * CFrame.new(0, 1, 0), Vector3.new(5, 2, 5), Color3.fromRGB(110, 80, 50), Enum.Material.WoodPlanks)
	for _, x in { -2.2, 2.2 } do
		part(model, base * CFrame.new(x, 1.4, 0) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(0.6, 2.4, 2.4), Color3.fromRGB(60, 45, 30), Enum.Material.Wood, Enum.PartType.Cylinder)
	end
	local barrel = part(model, base * CFrame.new(0, 3, 0) * CFrame.Angles(0, -math.pi / 2, 0), Vector3.new(4.4, 1.6, 1.6), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, Enum.PartType.Cylinder)
	barrel.Name = "Aim"
	return barrel
end

function builders.wizard(model: Model, base: CFrame)
	part(model, upright(base * CFrame.new(0, 7, 0)), Vector3.new(14, 4.5, 4.5), Color3.fromRGB(110, 90, 150), Enum.Material.Cobblestone, Enum.PartType.Cylinder)
	part(model, upright(base * CFrame.new(0, 14.4, 0)), Vector3.new(1, 6, 6), Color3.fromRGB(80, 60, 120), Enum.Material.Slate, Enum.PartType.Cylinder)
	local roof = part(model, base * CFrame.new(0, 16.5, 0), Vector3.new(5.4, 4, 5.4), Color3.fromRGB(60, 40, 140), Enum.Material.Slate, Enum.PartType.Ball)
	roof.Name = "Roof"
	local orb = part(model, base * CFrame.new(0, 20, 0), Vector3.new(2, 2, 2), Color3.fromRGB(190, 110, 255), Enum.Material.Neon, Enum.PartType.Ball)
	orb.Name = "Aim"
	local glow = Instance.new("PointLight")
	glow.Color = orb.Color
	glow.Range = 16
	glow.Brightness = 2
	glow.Parent = orb
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = orb.Color
	sparkles.Parent = orb
	return orb
end

-- Budowa i odświeżanie --------------------------------------------------

local function defenseFolder(plot)
	local folder = plot.model:FindFirstChild("Defenses")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Defenses"
		folder.Parent = plot.model
	end
	return folder
end

function DefenseService.Refresh(player: Player)
	local plot = PlotService.Get(player)
	local data = PlayerData.Get(player)
	if not plot or not data then
		return
	end
	local folder = defenseFolder(plot)
	folder:ClearAllChildren()
	local list = {}
	for _, defense in Defenses.list do
		local count = math.min(data.Defenses[defense.id] or 0, defense.max)
		for i = 1, count do
			local base = plot.origin * CFrame.new(Defenses.slots[defense.id][i])
			local model = Instance.new("Model")
			model.Name = defense.id
			model:SetAttribute("OwnerId", player.UserId)
			local aim = builders[defense.id](model, base)
			model.Parent = folder
			table.insert(list, { defense = defense, model = model, aim = aim, cooldownUntil = 0, position = base.Position })
		end
	end
	built[player] = list
end

function DefenseService.Clear(player: Player)
	built[player] = nil
	local plot = PlotService.Get(player)
	if plot then
		defenseFolder(plot):ClearAllChildren()
	end
end

-- Efekty -------------------------------------------------------------------

local function projectile(from: Vector3, to: Vector3, color: Color3, size: number, time: number, onArrive)
	local ball = Instance.new("Part")
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * size
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.CFrame = CFrame.new(from)
	ball.Parent = workspace
	local tween = TweenService:Create(ball, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = CFrame.new(to) })
	tween.Completed:Connect(function()
		ball:Destroy()
		onArrive()
	end)
	tween:Play()
end

local function boom(position: Vector3)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastPressure = 0
	explosion.BlastRadius = 6
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
end

-- Atak -------------------------------------------------------------------

local function hit(owner: Player, target: Player, defense, from: Vector3)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	CombatService.Knock(target, owner, {
		direction = root.Position - from,
		knockback = defense.knockback,
		upward = defense.upward,
		duration = defense.duration,
		damage = defense.damage,
		text = defense.icon .. " " .. string.upper(defense.name) .. "!",
		color = Color3.fromRGB(255, 180, 80),
		dropMessage = "Trafiła Cię obrona działki.",
	})
end

-- Obcy gracze w obrębie działki właściciela.
local function intruders(owner: Player, plot)
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= owner then
			local character = other.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and humanoid and humanoid.Health > 0 and not CombatService.InSafeZone(root.Position) then
				local localPos = plot.origin:PointToObjectSpace(root.Position)
				if math.abs(localPos.X) < 110 and localPos.Z > -80 and localPos.Z < 150 then
					table.insert(list, { player = other, root = root })
				end
			end
		end
	end
	return list
end

local function nearest(list, position: Vector3, range: number)
	local best, bestDist = nil, range
	for _, entry in list do
		local dist = (entry.root.Position - position).Magnitude
		if dist <= bestDist then
			best, bestDist = entry, dist
		end
	end
	return best
end

local function updateDefense(owner: Player, item, targets, now: number)
	if now < item.cooldownUntil or not item.aim.Parent then
		return
	end
	local defense = item.defense
	local target = nearest(targets, item.position + Vector3.new(0, 2, 0), defense.range)
	if not target then
		return
	end
	item.cooldownUntil = now + defense.cooldown

	if defense.id == "mine" then
		boom(item.position)
		hit(owner, target.player, defense, item.position)
		item.aim.Color = Color3.fromRGB(60, 20, 20)
		task.delay(defense.cooldown, function()
			if item.aim.Parent then
				item.aim.Color = Color3.fromRGB(255, 40, 40)
			end
		end)
	elseif defense.id == "trap" then
		-- Na chwilę pokazuje się wszystkim.
		for _, p in item.model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Transparency = 0
			end
		end
		hit(owner, target.player, defense, item.position)
		task.delay(2, function()
			for _, p in item.model:GetDescendants() do
				if p:IsA("BasePart") then
					p.Transparency = 1
				end
			end
		end)
	elseif defense.id == "cannon" then
		local barrel = item.aim
		local pivot = barrel.Position
		local look = (target.root.Position - pivot) * Vector3.new(1, 0, 1)
		if look.Magnitude > 0.1 then
			barrel.CFrame = CFrame.lookAt(pivot, pivot + look) * CFrame.Angles(0, math.pi / 2, 0)
		end
		local from = pivot + look.Unit * 2.4
		projectile(from, target.root.Position, Color3.fromRGB(30, 30, 30), 1.4, 0.35, function()
			boom(target.root.Position)
			hit(owner, target.player, defense, pivot)
		end)
	elseif defense.id == "wizard" then
		projectile(item.aim.Position, target.root.Position, Color3.fromRGB(200, 120, 255), 0.9, 0.25, function()
			hit(owner, target.player, defense, item.aim.Position)
		end)
	end
end

local function loop()
	while true do
		task.wait(TICK)
		local now = os.clock()
		for owner, list in built do
			local plot = PlotService.Get(owner)
			if plot and #list > 0 then
				-- Błąd jednej budowli nie może zatrzymać całej pętli obrony.
				local ok, err = pcall(function()
					local targets = intruders(owner, plot)
					if #targets > 0 then
						for _, item in list do
							updateDefense(owner, item, targets, now)
						end
					end
				end)
				if not ok then
					warn("[DefenseService]", err)
				end
			end
		end
	end
end

-- Zakup ------------------------------------------------------------------

local function buy(player: Player, defenseId)
	local data = PlayerData.Get(player)
	local defense = type(defenseId) == "string" and Defenses.byId[defenseId]
	if not data or not defense then
		return
	end
	local owned = data.Defenses[defense.id] or 0
	if owned >= defense.max then
		Remotes.notify(player, "Nie ma już miejsca na: " .. defense.name .. ".")
		return
	end
	local price = Defenses.price(defense, owned)
	if data.Cash < price then
		Remotes.notify(player, "Za mało pieniędzy na: " .. defense.name .. ".")
		return
	end
	data.Cash -= price
	data.Defenses[defense.id] = owned + 1
	PlayerData.MarkChanged(player)
	DefenseService.Refresh(player)
	Remotes.notify(player, string.format("%s Postawiono: %s (%d/%d)", defense.icon, defense.name, owned + 1, defense.max))
end

function DefenseService.Init()
	Remotes.BuyDefenseItem.OnServerEvent:Connect(buy)
	task.spawn(loop)
end

return DefenseService
