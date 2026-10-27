-- Walka na wyspie: rzucanie jajkami (przewraca), brainrot karabiny (obrażenia),
-- zakup broni za jajka oraz kradzież wielkiego złotego jajka po pokonaniu gracza.
-- Serwer liczy trafienia sam; klient podaje tylko punkt, w który celuje.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Weapons = require(ReplicatedStorage.Shared.Config.Weapons)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local WeaponTools = require(script.Parent.WeaponTools)
local Remotes = require(script.Parent.Remotes)

local CombatService = {}

local lastThrow = {} -- [Player] = os.clock()
local lastShot = {} -- [Player] = os.clock()
local lastAttacker = {} -- [Player] = { player, time }
local carried = {} -- [Player] = { ownerId, ownerName, value, model, speed }
local groundEggs = {} -- [Model] = { ownerId, ownerName, value, droppedAt }

---------------------------------------------------------------------------
-- Pomocnicze
---------------------------------------------------------------------------

local function aliveRoot(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart"), humanoid
end

local function inSafeZone(position: Vector3)
	return (position * Vector3.new(1, 0, 1)).Magnitude < PlotService.SAFE_ZONE_RADIUS
end

local function playerFromPart(part: Instance)
	local model = part:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function equippedTool(player: Player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
end

local function popup(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.1
	label.Text = text
	label.Parent = gui
	gui.Parent = anchor
	anchor.Parent = workspace
	TweenService:Create(gui, TweenInfo.new(0.8), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.9)
end

local function tracer(from: Vector3, to: Vector3, color: Color3)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = color
	local length = (to - from).Magnitude
	beam.Size = Vector3.new(0.18, 0.18, length)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.08)
end

local function markHit(target: Player, attacker: Player)
	lastAttacker[target] = { player = attacker, time = os.clock() }
end

---------------------------------------------------------------------------
-- Złote jajko
---------------------------------------------------------------------------

local function goldenEggModel(value: number)
	local egg = Instance.new("Part")
	egg.Name = "GoldenEgg"
	egg.Size = Vector3.new(3, 3.8, 3)
	egg.Color = Color3.fromRGB(255, 200, 40)
	egg.Material = Enum.Material.Foil
	egg.CanCollide = false
	egg.Massless = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	local glow = Instance.new("PointLight")
	glow.Color = egg.Color
	glow.Range = 14
	glow.Brightness = 2
	glow.Parent = egg
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = egg.Color
	sparkles.Parent = egg
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 36)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 250
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 220, 90)
	label.TextStrokeTransparency = 0.1
	label.Text = "🥚 " .. Format.money(value)
	label.Parent = gui
	gui.Parent = egg
	return egg
end

local function returnToOwner(ownerId: number, value: number)
	local owner = Players:GetPlayerByUserId(ownerId)
	if owner and PlayerData.Get(owner) then
		PlayerData.AddCash(owner, value)
		Remotes.notify(owner, "🥚 Twoje złote jajko wróciło do Ciebie! +" .. Format.money(value))
	end
end

local function attachTo(carrier: Player, info)
	local root, humanoid = aliveRoot(carrier)
	if not root then
		returnToOwner(info.ownerId, info.value)
		return
	end
	local egg = goldenEggModel(info.value)
	egg.CFrame = root.CFrame * CFrame.new(0, 0.8, 1.9)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = egg
	weld.Parent = egg
	egg.Parent = carrier.Character
	info.model = egg
	info.speed = humanoid.WalkSpeed
	humanoid.WalkSpeed = info.speed * Weapons.goldenEgg.carrySpeed
	carried[carrier] = info
end

local function dropCarried(carrier: Player, reason: string?)
	local info = carried[carrier]
	if not info then
		return
	end
	carried[carrier] = nil
	local position = info.model and info.model.Parent and info.model.Position
	if info.model then
		info.model:Destroy()
	end
	local _, humanoid = aliveRoot(carrier)
	if humanoid and info.speed then
		humanoid.WalkSpeed = info.speed
	end
	-- Jajko spadło z wyspy albo nie wiadomo gdzie: wraca do właściciela.
	if not position or position.Y < -20 then
		returnToOwner(info.ownerId, info.value)
		return
	end
	local egg = goldenEggModel(info.value)
	egg.Anchored = true
	egg.CFrame = CFrame.new(position.X, 2, position.Z)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Podnieś złote jajko"
	prompt.ObjectText = "Złote jajko gracza " .. info.ownerName
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg
	egg.Parent = workspace
	local ground = { ownerId = info.ownerId, ownerName = info.ownerName, value = info.value, droppedAt = os.clock() }
	groundEggs[egg] = ground
	if reason and carrier.Parent then
		Remotes.notify(carrier, "Upuściłeś złote jajko! " .. reason)
	end
	prompt.Triggered:Connect(function(player)
		if groundEggs[egg] ~= ground or carried[player] or not aliveRoot(player) then
			return
		end
		groundEggs[egg] = nil
		egg:Destroy()
		if player.UserId == ground.ownerId then
			returnToOwner(ground.ownerId, ground.value)
		else
			attachTo(player, { ownerId = ground.ownerId, ownerName = ground.ownerName, value = ground.value })
			Remotes.notify(player, "Masz złote jajko! Zanieś je na swoją działkę.")
		end
	end)
end

-- Gracz zginął: jeśli niedawno ktoś go trafił, napastnik zabiera mu złote jajko.
local function onDied(victim: Player)
	dropCarried(victim)
	local hit = lastAttacker[victim]
	lastAttacker[victim] = nil
	if not hit or os.clock() - hit.time > Weapons.goldenEgg.attackerWindow then
		return
	end
	local attacker = hit.player
	local victimData = PlayerData.Get(victim)
	if not attacker.Parent or not victimData or carried[attacker] or not aliveRoot(attacker) then
		return
	end
	local value = math.floor(victimData.Cash * Weapons.goldenEgg.stealPercent)
	if value < 1 then
		Remotes.notify(attacker, "Pokonałeś " .. victim.DisplayName .. ", ale nie miał pieniędzy.")
		return
	end
	victimData.Cash -= value
	PlayerData.MarkChanged(victim)
	attachTo(attacker, { ownerId = victim.UserId, ownerName = victim.DisplayName, value = value })
	Remotes.notify(victim, string.format("💀 %s zabrał Twoje złote jajko (%s)! Trafiaj go, żeby je upuścił!", attacker.DisplayName, Format.money(value)))
	Remotes.notify(attacker, string.format("🥚 Masz złote jajko gracza %s (%s)! Zanieś je na swoją działkę!", victim.DisplayName, Format.money(value)))
end

-- Sprawdza dostarczenie jajek na własną działkę i jajka leżące za długo na ziemi.
local function checkEggs()
	for carrier, info in carried do
		local root = aliveRoot(carrier)
		local plot = PlotService.Get(carrier)
		if root and plot then
			local localPos = plot.origin:PointToObjectSpace(root.Position)
			if math.abs(localPos.X) < 110 and localPos.Z > -80 and localPos.Z < 150 then
				carried[carrier] = nil
				info.model:Destroy()
				local _, humanoid = aliveRoot(carrier)
				if humanoid and info.speed then
					humanoid.WalkSpeed = info.speed
				end
				PlayerData.AddCash(carrier, info.value)
				Remotes.notify(carrier, "💰 Złote jajko dostarczone! +" .. Format.money(info.value))
				local owner = Players:GetPlayerByUserId(info.ownerId)
				if owner then
					Remotes.notify(owner, string.format("%s dowiózł Twoje złote jajko do swojej bazy.", carrier.DisplayName))
				end
			end
		end
	end
	for egg, ground in groundEggs do
		if os.clock() - ground.droppedAt > Weapons.goldenEgg.groundTime then
			groundEggs[egg] = nil
			egg:Destroy()
			returnToOwner(ground.ownerId, ground.value)
		end
	end
end

local function eggLoop()
	while true do
		task.wait(0.25)
		local ok, err = pcall(checkEggs)
		if not ok then
			warn("[CombatService]", err)
		end
	end
end

---------------------------------------------------------------------------
-- Rzucanie jajkami
---------------------------------------------------------------------------

-- Przewraca i odpycha gracza (jajko, mina, działo...). Zwraca true, jeśli trafienie się liczyło.
-- opts: { direction, knockback, upward, duration, damage, text, color, dropMessage }
function CombatService.Knock(target: Player, attacker: Player?, opts)
	local root, humanoid = aliveRoot(target)
	if not root or inSafeZone(root.Position) then
		return false
	end
	local flat = (opts.direction or Vector3.zero) * Vector3.new(1, 0, 1)
	flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, 1)
	if attacker then
		markHit(target, attacker)
	end
	if opts.damage and opts.damage > 0 then
		humanoid:TakeDamage(opts.damage)
	end
	if opts.duration and opts.duration > 0 then
		Remotes.Knockback:FireClient(target, flat * (opts.knockback or 0) + Vector3.new(0, opts.upward or 0, 0), opts.duration)
	end
	if opts.text then
		popup(root.Position + Vector3.new(0, 3, 0), opts.text, opts.color or Color3.new(1, 1, 1))
	end
	dropCarried(target, opts.dropMessage or "Zostałeś trafiony.")
	return true
end

local function knock(target: Player, attacker: Player, direction: Vector3)
	local cfg = Weapons.throw
	CombatService.Knock(target, attacker, {
		direction = direction,
		knockback = cfg.knockback,
		upward = cfg.upward,
		duration = cfg.knockdown,
		damage = cfg.damage,
		text = "SPLAT!",
		color = Color3.fromRGB(255, 240, 200),
		dropMessage = "Ktoś trafił Cię jajkiem.",
	})
end

CombatService.InSafeZone = inSafeZone

local function throwEgg(player: Player, target)
	if typeof(target) ~= "Vector3" then
		return
	end
	local tool = equippedTool(player)
	if not tool or tool.Name ~= WeaponTools.EGG_TOOL then
		return
	end
	local now = os.clock()
	if now - (lastThrow[player] or 0) < Weapons.throw.cooldown * 0.8 then
		return
	end
	lastThrow[player] = now
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end

	local cfg = Weapons.throw
	local position = head.Position + (target - head.Position).Unit * 2
	local velocity = (target - position).Unit * cfg.speed + Vector3.new(0, 8, 0)
	local egg = Instance.new("Part")
	egg.Name = "ThrownEgg"
	egg.Anchored = true
	egg.CanCollide = false
	egg.CanQuery = false
	egg.Size = Vector3.new(1, 1.3, 1)
	egg.Color = Color3.fromRGB(250, 245, 230)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	egg.CFrame = CFrame.new(position)
	egg.Parent = workspace

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, egg }
	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local nextPosition = position + velocity * dt
		velocity += Vector3.new(0, -cfg.gravity, 0) * dt
		local result = workspace:Raycast(position, nextPosition - position, params)
		if result or elapsed > cfg.maxTime then
			connection:Disconnect()
			egg:Destroy()
			if result then
				local hitPlayer = playerFromPart(result.Instance)
				if hitPlayer and hitPlayer ~= player then
					knock(hitPlayer, player, velocity)
				end
			end
			return
		end
		position = nextPosition
		egg.CFrame = CFrame.new(position)
	end)
end

---------------------------------------------------------------------------
-- Karabiny
---------------------------------------------------------------------------

local function fireWeapon(player: Player, target)
	if typeof(target) ~= "Vector3" then
		return
	end
	local data = PlayerData.Get(player)
	local tool = equippedTool(player)
	local rifle = tool and Weapons.byId[tool:GetAttribute("WeaponId")]
	if not data or not rifle or not data.OwnedWeapons[rifle.id] then
		return
	end
	local now = os.clock()
	if now - (lastShot[player] or 0) < rifle.fireRate * 0.8 then
		return
	end
	lastShot[player] = now
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end

	local origin = head.Position
	local spread = math.rad(rifle.spread)
	local direction = (CFrame.lookAt(origin, target) * CFrame.Angles((math.random() - 0.5) * spread, (math.random() - 0.5) * spread, 0)).LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, direction * rifle.range, params)
	local hitPosition = result and result.Position or origin + direction * rifle.range

	local barrel = tool:FindFirstChild("Barrel", true)
	local muzzle = barrel and barrel:FindFirstChild("Muzzle")
	tracer(muzzle and muzzle.WorldPosition or origin, hitPosition, rifle.color)

	if result then
		local hitPlayer = playerFromPart(result.Instance)
		local root, humanoid = nil, nil
		if hitPlayer and hitPlayer ~= player then
			root, humanoid = aliveRoot(hitPlayer)
		end
		if root and not inSafeZone(root.Position) then
			markHit(hitPlayer, player)
			humanoid:TakeDamage(rifle.damage)
			popup(result.Position, Weapons.phrases[math.random(#Weapons.phrases)] .. " -" .. rifle.damage, rifle.color)
		end
	end
end

---------------------------------------------------------------------------
-- Sklep z bronią (za jajka)
---------------------------------------------------------------------------

local function buyWeapon(player: Player, weaponId)
	local data = PlayerData.Get(player)
	local rifle = type(weaponId) == "string" and Weapons.byId[weaponId]
	if not data or not rifle then
		return
	end
	if not data.OwnedWeapons[rifle.id] then
		if data.Eggs < rifle.price then
			Remotes.notify(player, "Za mało jajek 🥚 na " .. rifle.name .. ".")
			return
		end
		data.Eggs -= rifle.price
		data.OwnedWeapons[rifle.id] = true
		Remotes.notify(player, "Kupiono: " .. rifle.name .. "!")
	end
	data.EquippedWeapon = rifle.id
	PlayerData.MarkChanged(player)
	WeaponTools.Give(player)
end

---------------------------------------------------------------------------

function CombatService.Setup(player: Player)
	WeaponTools.Setup(player)
	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onDied(player)
		end)
	end
	player.CharacterAdded:Connect(watch)
	if player.Character then
		task.spawn(watch, player.Character)
	end
end

function CombatService.PlayerLeft(player: Player)
	dropCarried(player)
	lastAttacker[player] = nil
	lastThrow[player] = nil
	lastShot[player] = nil
end

function CombatService.Init()
	Remotes.ThrowEgg.OnServerEvent:Connect(throwEgg)
	Remotes.FireWeapon.OnServerEvent:Connect(fireWeapon)
	Remotes.BuyWeapon.OnServerEvent:Connect(buyWeapon)
	task.spawn(eggLoop)
end

return CombatService
