-- Napady na bazy innych graczy: start napadu, wieże obronne, rabunek skarbca,
-- obrona przez właściciela i historia napadów. Wszystko liczone na serwerze.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Raids = require(ReplicatedStorage.Shared.Config.Raids)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local FactoryService = require(script.Parent.FactoryService)
local MineService = require(script.Parent.MineService)
local Remotes = require(script.Parent.Remotes)

local RaidService = {}

local MAX_LOG = 10
local raids = {} -- [attacker] = { attacker, victim, plot, endsAt, token }
local raidOnVictim = {} -- [victim] = raid
local lastRaidAt = {} -- [attacker] = os.clock()
local lastPvpHit = {} -- [Player] = os.clock()

local function defenseOf(data)
	return Raids.defenseLevels[data.DefenseLevel] or Raids.defenseLevels[0]
end

local function rootOf(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart"), humanoid
end

local function addLog(player: Player, entry)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	entry.time = os.time()
	table.insert(data.RaidLog, 1, entry)
	while #data.RaidLog > MAX_LOG do
		table.remove(data.RaidLog)
	end
	PlayerData.MarkChanged(player)
end

local function sendState(raid, active: boolean)
	if raid.attacker.Parent then
		Remotes.RaidState:FireClient(raid.attacker, active and {
			role = "attacker",
			other = raid.victim.DisplayName,
			endsAt = raid.endsAt,
		} or nil)
	end
	if raid.victim.Parent then
		Remotes.RaidState:FireClient(raid.victim, active and {
			role = "victim",
			other = raid.attacker.DisplayName,
			endsAt = raid.endsAt,
		} or nil)
	end
end

-- Wieże obronne -------------------------------------------------------------

local function buildTower(spot: CFrame, parent: Instance)
	local tower = Instance.new("Model")
	tower.Name = "Tower"
	local function p(size, offset, color, material)
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = size
		part.CFrame = spot * offset
		part.Color = color
		part.Material = material
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = tower
		return part
	end
	local base = p(Vector3.new(12, 4, 4), CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(130, 125, 120), Enum.Material.Cobblestone)
	base.Shape = Enum.PartType.Cylinder
	p(Vector3.new(5.4, 1, 5.4), CFrame.new(0, 12.4, 0), Color3.fromRGB(100, 95, 90), Enum.Material.Slate)
	for _, offset in { Vector3.new(2.2, 0, 2.2), Vector3.new(-2.2, 0, 2.2), Vector3.new(2.2, 0, -2.2), Vector3.new(-2.2, 0, -2.2) } do
		p(Vector3.new(1, 1.2, 1), CFrame.new(offset + Vector3.new(0, 13.5, 0)), Color3.fromRGB(100, 95, 90), Enum.Material.Slate)
	end
	local crystal = p(Vector3.new(1.4, 2.4, 1.4), CFrame.new(0, 14.4, 0) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(255, 80, 60), Enum.Material.Neon)
	crystal.Name = "Crystal"
	local glow = Instance.new("PointLight")
	glow.Color = crystal.Color
	glow.Range = 12
	glow.Parent = crystal
	tower.PrimaryPart = crystal
	tower.Parent = parent
	return tower
end

-- Ustawia wieże przy skarbcu zgodnie z poziomem obrony właściciela.
function RaidService.RefreshDefense(player: Player)
	local plot = PlotService.Get(player)
	local data = PlayerData.Get(player)
	if not plot or not data then
		return
	end
	local folder = plot.vault.towerFolder
	folder:ClearAllChildren()
	for i = 1, defenseOf(data).towers do
		buildTower(plot.vault.towerSpots[i], folder)
	end
end

function RaidService.ClearDefense(player: Player)
	local plot = PlotService.Get(player)
	if plot then
		plot.vault.towerFolder:ClearAllChildren()
	end
end

local function shoot(from: Vector3, to: Vector3)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 90, 60)
	local length = (to - from).Magnitude
	beam.Size = Vector3.new(0.3, 0.3, length)
	beam.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.15)
end

-- Koniec napadu -------------------------------------------------------------

local function teleportHome(player: Player)
	local plot = PlotService.Get(player)
	local character = player.Character
	if plot and character and character.Parent then
		character:PivotTo(plot.spawnCFrame)
	end
end

local function finish(raid, result: string)
	if raids[raid.attacker] ~= raid then
		return
	end
	raids[raid.attacker] = nil
	raidOnVictim[raid.victim] = nil
	raid.plot.vault.vaultPrompt.Enabled = false
	sendState(raid, false)

	local attacker, victim = raid.attacker, raid.victim
	if result == "success" then
		local victimData = PlayerData.Get(victim)
		local attackerData = PlayerData.Get(attacker)
		if victimData and attackerData then
			local stolen = math.floor(victimData.Cash * Raids.stealPercent)
			local before = victimData.FactoryLevel
			victimData.Cash -= stolen
			victimData.FactoryLevel = math.max(1, victimData.FactoryLevel - Raids.levelsLost)
			victimData.ShieldUntil = os.time() + Raids.victimShield
			PlayerData.AddCash(attacker, stolen)
			FactoryService.UpdateLabel(victim)
			MineService.Refresh(victim)
			addLog(victim, {
				kind = "robbed",
				name = attacker.DisplayName,
				amount = stolen,
				levels = before - victimData.FactoryLevel,
			})
			addLog(attacker, { kind = "raidWon", name = victim.DisplayName, amount = stolen })
			Remotes.notify(victim, string.format("⚔️ %s obrabował Twoją bazę! -%s i -%d poz. fabryki", attacker.DisplayName, Format.money(stolen), before - victimData.FactoryLevel))
			Remotes.notify(attacker, string.format("💰 Udany napad na %s! +%s", victim.DisplayName, Format.money(stolen)))
		end
	else
		local reason = ({
			died = "napastnik zginął",
			timeout = "skończył się czas",
			left = "napastnik uciekł",
		})[result] or "napad przerwany"
		if victim.Parent then
			addLog(victim, { kind = "defended", name = attacker.DisplayName })
			Remotes.notify(victim, string.format("🛡️ Obroniłeś bazę przed %s (%s)!", attacker.DisplayName, reason))
		end
		if attacker.Parent then
			addLog(attacker, { kind = "raidLost", name = victim.DisplayName })
			Remotes.notify(attacker, string.format("Napad na %s nieudany: %s.", victim.DisplayName, reason))
		end
	end
	if attacker.Parent and result ~= "died" then
		teleportHome(attacker)
	end
end

-- Start napadu --------------------------------------------------------------

local function canBeRaided(victim: Player, now: number)
	local data = PlayerData.Get(victim)
	if not data or not PlotService.Get(victim) then
		return false, "ten gracz nie ma bazy"
	end
	if data.FactoryLevel < Raids.minFactoryLevel then
		return false, string.format("fabryka poniżej poz. %d (ochrona nowych graczy)", Raids.minFactoryLevel)
	end
	if (data.ShieldUntil or 0) > now then
		return false, "baza ma tarczę po niedawnym napadzie"
	end
	if raidOnVictim[victim] then
		return false, "ktoś już napada tę bazę"
	end
	return true
end

local function startRaid(attacker: Player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end
	local victim = Players:GetPlayerByUserId(targetUserId)
	local data = PlayerData.Get(attacker)
	if not victim or victim == attacker or not data then
		return
	end
	if raids[attacker] or raidOnVictim[attacker] then
		Remotes.notify(attacker, "Najpierw skończ obecny napad.")
		return
	end
	if data.FactoryLevel < Raids.minFactoryLevel then
		Remotes.notify(attacker, string.format("Napadać możesz od poziomu fabryki %d.", Raids.minFactoryLevel))
		return
	end
	local since = os.clock() - (lastRaidAt[attacker] or -math.huge)
	if since < Raids.attackerCooldown then
		Remotes.notify(attacker, string.format("Następny napad za %d s.", math.ceil(Raids.attackerCooldown - since)))
		return
	end
	local ok, reason = canBeRaided(victim, os.time())
	if not ok then
		Remotes.notify(attacker, "Nie możesz napaść: " .. reason .. ".")
		return
	end
	local root, humanoid = rootOf(attacker)
	if not root then
		return
	end

	local plot = PlotService.Get(victim)
	local victimData = PlayerData.Get(victim)
	local raid = {
		attacker = attacker,
		victim = victim,
		plot = plot,
		endsAt = os.time() + Raids.duration,
	}
	raids[attacker] = raid
	raidOnVictim[victim] = raid
	lastRaidAt[attacker] = os.clock()

	local prompt = plot.vault.vaultPrompt
	prompt.HoldDuration = defenseOf(victimData).holdTime
	prompt.Enabled = true
	attacker.Character:PivotTo(plot.vault.raidEntry)
	sendState(raid, true)
	Remotes.notify(victim, string.format("⚔️ %s napada na Twoją bazę! Broń skarbca!", attacker.DisplayName))
	Remotes.notify(attacker, "Dotrzyj do skarbca i obrabuj go, zanim zginiesz!")

	humanoid.Died:Connect(function()
		finish(raid, "died")
	end)

	-- Wieże strzelają, dopóki trwa napad.
	task.spawn(function()
		while raids[attacker] == raid do
			if os.time() >= raid.endsAt then
				finish(raid, "timeout")
				break
			end
			local targetRoot, targetHumanoid = rootOf(attacker)
			if targetRoot then
				local damage = defenseOf(PlayerData.Get(victim) or victimData).damage
				for _, tower in plot.vault.towerFolder:GetChildren() do
					local crystal = tower.PrimaryPart
					if crystal and (crystal.Position - targetRoot.Position).Magnitude <= Raids.towerRange then
						shoot(crystal.Position, targetRoot.Position)
						targetHumanoid:TakeDamage(damage)
					end
				end
			end
			task.wait(Raids.towerInterval)
		end
	end)
end

-- Rabunek skarbca -----------------------------------------------------------

local function onVaultTriggered(plot, player: Player)
	local raid = raids[player]
	if not raid or raid.plot ~= plot then
		return
	end
	-- Właściciel przy skarbcu blokuje rabunek.
	local ownerRoot = rootOf(raid.victim)
	if ownerRoot and (ownerRoot.Position - plot.vault.vaultCFrame.Position).Magnitude <= Raids.defenderBlockRadius then
		Remotes.notify(player, "Właściciel broni skarbca! Pokonaj go albo odciągnij.")
		return
	end
	finish(raid, "success")
end

-- Walka kilofem w czasie napadu ---------------------------------------------

local function inSameRaid(a: Player, b: Player)
	local raid = raids[a] or raidOnVictim[a]
	return raid ~= nil and (raid.attacker == b or raid.victim == b)
end

local function onPvpHit(player: Player, target)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player then
		return
	end
	if not inSameRaid(player, target) then
		return
	end
	local now = os.clock()
	if now - (lastPvpHit[player] or 0) < 0.4 then
		return
	end
	lastPvpHit[player] = now
	local root = rootOf(player)
	local targetRoot, targetHumanoid = rootOf(target)
	if root and targetRoot and (root.Position - targetRoot.Position).Magnitude <= 9 then
		targetHumanoid:TakeDamage(Raids.pvpDamage)
	end
end

-- Lista celów dla klienta ---------------------------------------------------

local function getTargets(player: Player)
	local now = os.time()
	local list = {}
	for _, other in Players:GetPlayers() do
		local data = PlayerData.Get(other)
		if other ~= player and data then
			local ok, reason = canBeRaided(other, now)
			table.insert(list, {
				userId = other.UserId,
				name = other.DisplayName,
				factoryLevel = data.FactoryLevel,
				defenseLevel = data.DefenseLevel,
				cash = data.Cash,
				available = ok,
				reason = reason,
			})
		end
	end
	local since = os.clock() - (lastRaidAt[player] or -math.huge)
	return {
		targets = list,
		cooldown = math.max(0, math.ceil(Raids.attackerCooldown - since)),
	}
end

-- Ochrona za $ --------------------------------------------------------------

function RaidService.BuyDefense(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local nextLevel = Raids.defenseLevels[data.DefenseLevel + 1]
	if not nextLevel then
		Remotes.notify(player, "Obrona ma już maksymalny poziom.")
		return
	end
	if data.Cash < nextLevel.price then
		Remotes.notify(player, "Za mało pieniędzy na ochronę.")
		return
	end
	data.Cash -= nextLevel.price
	data.DefenseLevel += 1
	PlayerData.MarkChanged(player)
	RaidService.RefreshDefense(player)
	Remotes.notify(player, string.format("🔒 Skarbiec wzmocniony: poziom %d (rabunek %d s)", data.DefenseLevel, nextLevel.holdTime))
end

function RaidService.DefendHome(player: Player)
	local raid = raidOnVictim[player]
	local plot = PlotService.Get(player)
	local character = player.Character
	if raid and plot and character then
		character:PivotTo(plot.vault.vaultCFrame * CFrame.new(0, 4, 10))
	end
end

-- Gracz wychodzi z gry: kończymy jego napady.
function RaidService.PlayerLeft(player: Player)
	local own = raids[player]
	if own then
		finish(own, "left")
	end
	local onMe = raidOnVictim[player]
	if onMe then
		raids[onMe.attacker] = nil
		raidOnVictim[player] = nil
		onMe.plot.vault.vaultPrompt.Enabled = false
		if onMe.attacker.Parent then
			Remotes.RaidState:FireClient(onMe.attacker, nil)
			Remotes.notify(onMe.attacker, "Właściciel bazy wyszedł z gry. Napad przerwany.")
			teleportHome(onMe.attacker)
		end
	end
	lastRaidAt[player] = nil
	lastPvpHit[player] = nil
	RaidService.ClearDefense(player)
end

function RaidService.Init()
	Remotes.StartRaid.OnServerEvent:Connect(startRaid)
	Remotes.BuyDefense.OnServerEvent:Connect(RaidService.BuyDefense)
	Remotes.DefendHome.OnServerEvent:Connect(RaidService.DefendHome)
	Remotes.PvpHit.OnServerEvent:Connect(onPvpHit)

	local getTargetsFunction = Instance.new("RemoteFunction")
	getTargetsFunction.Name = "GetRaidTargets"
	getTargetsFunction.OnServerInvoke = getTargets
	getTargetsFunction.Parent = ReplicatedStorage:WaitForChild("Remotes")

	for _, plot in PlotService.All() do
		plot.vault.vaultPrompt.Triggered:Connect(function(player)
			onVaultTriggered(plot, player)
		end)
	end
end

return RaidService
