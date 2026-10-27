-- Pisklaki: wyklucie za jajka, obóz treningowy na działce i wysyłanie armii na wojnę.
-- Pisklaki chodzą po zagrodzie obozu; na wojnę maszerują przez wyspę do celu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Chicks = require(ReplicatedStorage.Shared.Config.Chicks)
local LuckLevels = require(ReplicatedStorage.Shared.Config.LuckLevels)
local Format = require(ReplicatedStorage.Shared.Format)

local PlayerData = require(script.Parent.PlayerData)
local PlotService = require(script.Parent.PlotService)
local RaidService = require(script.Parent.RaidService)
local AllianceService = require(script.Parent.AllianceService)
local SoundFx = require(ReplicatedStorage.Shared.SoundFx)
local Remotes = require(script.Parent.Remotes)

local ChickService = {}

local CAMP_POSITION = Vector3.new(78, 0, 4) -- środek obozu w układzie działki
local PEN_RADIUS = 13
local rng = Random.new()

local camps = {} -- [Player] = { folder, chicks = { [uid] = Model } }
local atWar = {} -- [Player] = true, gdy armia jest w drodze

local function part(parent: Instance, cframe: CFrame, size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
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

local function healthy(chick, now: number)
	return (chick.injuredUntil or 0) <= now
end

local function chickName(chick)
	local chickType = Chicks.byId[chick.type]
	return chickType and chickType.name or "Pisklak"
end

-- Model pisklaka: tułów, głowa, dziób, oczy i podpis z poziomem. Pozycja = pivot przy ziemi.
local function buildChickModel(chick, cframe: CFrame)
	local chickType = Chicks.byId[chick.type] or Chicks.types[1]
	local s = chickType.scale
	local model = Instance.new("Model")
	model.Name = "Chick_" .. chick.uid
	local body = part(model, cframe * CFrame.new(0, 1.1 * s, 0), Vector3.one * 2.2 * s, chickType.color, nil, Enum.PartType.Ball)
	body.Name = "Body"
	model.PrimaryPart = body
	local head = part(model, cframe * CFrame.new(0, 2.6 * s, -0.5 * s), Vector3.one * 1.5 * s, chickType.color, nil, Enum.PartType.Ball)
	part(model, cframe * CFrame.new(0, 2.5 * s, -1.35 * s), Vector3.new(0.5, 0.35, 0.6) * s, Color3.fromRGB(255, 150, 30))
	for _, side in { -1, 1 } do
		part(model, cframe * CFrame.new(side * 0.35 * s, 2.85 * s, -1.15 * s), Vector3.one * 0.3 * s, Color3.new(0.05, 0.05, 0.05), nil, Enum.PartType.Ball)
		part(model, cframe * CFrame.new(side * 1.05 * s, 1.2 * s, 0) * CFrame.Angles(0, 0, math.rad(side * 20)), Vector3.new(0.3, 1.2, 1.4) * s, chickType.color:Lerp(Color3.new(1, 1, 1), 0.15))
		part(model, cframe * CFrame.new(side * 0.45 * s, 0.1, 0), Vector3.new(0.3, 0.2, 0.6) * s, Color3.fromRGB(255, 150, 30))
	end
	if chick.type == "knight" then
		part(model, cframe * CFrame.new(0, 3.3 * s, -0.5 * s), Vector3.new(1.3, 0.5, 1.3) * s, Color3.fromRGB(150, 155, 170), Enum.Material.Metal)
	elseif chick.type == "ninja" then
		part(model, cframe * CFrame.new(0, 2.75 * s, -0.5 * s), Vector3.new(1.55, 0.3, 1.55) * s, Color3.fromRGB(220, 40, 40))
	elseif chick.type == "dragon" then
		for _, side in { -1, 1 } do
			part(model, cframe * CFrame.new(side * 0.4 * s, 3.4 * s, -0.3 * s) * CFrame.Angles(math.rad(-25), 0, 0), Vector3.new(0.25, 0.8, 0.25) * s, Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
		end
	end
	head.Name = "Head"
	model:SetAttribute("Level", chick.level)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(140, 26)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2 * s, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = true
	gui.Name = "Info"
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	gui.Parent = head
	return model
end

local function updateChickLabel(model: Model, chick, now: number)
	local label = model:FindFirstChild("Head") and model.Head:FindFirstChild("Info") and model.Head.Info:FindFirstChildOfClass("TextLabel")
	if not label then
		return
	end
	local status = ""
	if not healthy(chick, now) then
		status = " 🤕"
	elseif chick.training then
		status = " 💪"
	end
	label.Text = string.format("%s poz. %d%s", chickName(chick), chick.level, status)
end

-- Obóz treningowy: płot w kółko, brama, manekiny treningowe i tablica.
local function buildCamp(plot)
	local folder = Instance.new("Model")
	folder.Name = "TrainingCamp"
	local center = plot.origin * CFrame.new(CAMP_POSITION)
	local wood = Color3.fromRGB(140, 95, 55)
	part(folder, center * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, PEN_RADIUS * 2 + 4, PEN_RADIUS * 2 + 4), Color3.fromRGB(200, 170, 110), Enum.Material.Sand, Enum.PartType.Cylinder)
	local posts = 20
	for i = 1, posts do
		local a = i / posts * math.pi * 2
		-- Przerwa w płocie od strony środka wyspy (brama).
		if math.abs(math.cos(a)) > 0.12 or math.sin(a) > 0 then
			local p = Vector3.new(math.cos(a), 0, math.sin(a)) * (PEN_RADIUS + 1.5)
			part(folder, center * CFrame.new(p + Vector3.new(0, 1.5, 0)), Vector3.new(0.6, 3, 0.6), wood, Enum.Material.Wood).CanCollide = true
			local nextA = (i + 1) / posts * math.pi * 2
			local q = Vector3.new(math.cos(nextA), 0, math.sin(nextA)) * (PEN_RADIUS + 1.5)
			if math.abs(math.cos(nextA)) > 0.12 or math.sin(nextA) > 0 then
				local mid = (p + q) / 2
				part(folder, center * CFrame.lookAt(mid + Vector3.new(0, 2.2, 0), q + Vector3.new(0, 2.2, 0)), Vector3.new(0.3, 0.4, (q - p).Magnitude), wood, Enum.Material.WoodPlanks)
			end
		end
	end
	-- Manekiny do treningu
	for _, offset in { Vector3.new(-7, 0, 6), Vector3.new(7, 0, 6) } do
		part(folder, center * CFrame.new(offset + Vector3.new(0, 1.5, 0)), Vector3.new(0.5, 3, 0.5), wood, Enum.Material.Wood)
		part(folder, center * CFrame.new(offset + Vector3.new(0, 3.4, 0)), Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(220, 200, 150), Enum.Material.Fabric, Enum.PartType.Ball)
		part(folder, center * CFrame.new(offset + Vector3.new(0, 2.4, 0)), Vector3.new(2.4, 0.3, 0.3), wood, Enum.Material.Wood)
	end
	local sign = part(folder, center * CFrame.new(0, 4, -(PEN_RADIUS + 3)), Vector3.new(12, 3, 0.4), Color3.fromRGB(60, 40, 25), Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		part(folder, center * CFrame.new(side * 5.5, 2, -(PEN_RADIUS + 3)), Vector3.new(0.5, 4, 0.5), wood, Enum.Material.Wood)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.Text = "🐣 OBÓZ TRENINGOWY"
	label.Parent = gui
	gui.Parent = sign
	folder.Parent = plot.model
	return folder
end

local function randomPenPoint(plot)
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(0, PEN_RADIUS - 2)
	return plot.origin * CFrame.new(CAMP_POSITION + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
end

-- Dopasowuje modele w zagrodzie do listy pisklaków gracza.
function ChickService.Refresh(player: Player)
	local plot = PlotService.Get(player)
	local data = PlayerData.Get(player)
	if not plot or not data then
		return
	end
	local camp = camps[player]
	if not camp then
		camp = { folder = buildCamp(plot), chicks = {} }
		camps[player] = camp
	end
	local now = os.time()
	local alive = {}
	for _, chick in data.Chicks do
		alive[chick.uid] = true
		local model = camp.chicks[chick.uid]
		if model and model:GetAttribute("Level") ~= chick.level then
			-- Awans: przebudowujemy model, żeby podpis i wygląd były aktualne.
			local pivot = model:GetPivot()
			model:Destroy()
			model = buildChickModel(chick, pivot * CFrame.new(0, -1.1 * (Chicks.byId[chick.type] or Chicks.types[1]).scale, 0))
			model.Parent = camp.folder
			camp.chicks[chick.uid] = model
		end
		if not model and not atWar[player] then
			model = buildChickModel(chick, randomPenPoint(plot))
			model.Parent = camp.folder
			camp.chicks[chick.uid] = model
		end
		if model then
			updateChickLabel(model, chick, now)
		end
	end
	for uid, model in camp.chicks do
		if not alive[uid] then
			model:Destroy()
			camp.chicks[uid] = nil
		end
	end
end

function ChickService.Clear(player: Player)
	local camp = camps[player]
	if camp then
		camp.folder:Destroy()
	end
	camps[player] = nil
	atWar[player] = nil
end

-- Wyklucie ---------------------------------------------------------------

local function hatch(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if #data.Chicks >= Chicks.maxChicks then
		Remotes.notify(player, string.format("Masz już %d pisklaków. Więcej się nie zmieści.", Chicks.maxChicks))
		return
	end
	if data.Eggs < Chicks.hatchPrice then
		Remotes.notify(player, string.format("Wyklucie kosztuje 🥚 %d jajek.", Chicks.hatchPrice))
		return
	end
	data.Eggs -= Chicks.hatchPrice
	local luck = LuckLevels[data.LuckLevel] and LuckLevels[data.LuckLevel].luck or 1
	local chickType = Chicks.roll(luck, rng)
	data.ChickNextId += 1
	table.insert(data.Chicks, {
		uid = data.ChickNextId,
		type = chickType.id,
		level = 1,
		xp = 0,
		training = false,
		injuredUntil = 0,
	})
	PlayerData.MarkChanged(player)
	ChickService.Refresh(player)
	Remotes.notify(player, string.format("🐣 Wykluł się: %s (siła %d)!", chickType.name, chickType.power))
	Remotes.PlaySound:FireClient(player, chickType.weight <= 10 and "levelUp" or "chirp")
end

-- Trening ---------------------------------------------------------------

local function findChick(data, uid)
	for _, chick in data.Chicks do
		if chick.uid == uid then
			return chick
		end
	end
	return nil
end

local function trainingCount(data)
	local count = 0
	for _, chick in data.Chicks do
		if chick.training then
			count += 1
		end
	end
	return count
end

local function setTraining(player: Player, uid, on)
	local data = PlayerData.Get(player)
	if not data or type(uid) ~= "number" then
		return
	end
	local chick = findChick(data, uid)
	if not chick then
		return
	end
	on = on == true
	if on and not chick.training then
		local camp = Chicks.camp[data.CampLevel] or Chicks.camp[1]
		if trainingCount(data) >= camp.slots then
			Remotes.notify(player, string.format("Obóz mieści %d pisklaków naraz. Ulepsz obóz, żeby trenować więcej.", camp.slots))
			return
		end
		if chick.level >= Chicks.maxLevel then
			Remotes.notify(player, "Ten pisklak ma już maksymalny poziom.")
			return
		end
	end
	chick.training = on
	PlayerData.MarkChanged(player)
	ChickService.Refresh(player)
end

local function upgradeCamp(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local nextLevel = Chicks.camp[data.CampLevel + 1]
	if not nextLevel then
		Remotes.notify(player, "Obóz ma już maksymalny poziom.")
		return
	end
	if data.Cash < nextLevel.price then
		Remotes.notify(player, "Za mało pieniędzy na ulepszenie obozu.")
		return
	end
	data.Cash -= nextLevel.price
	data.CampLevel += 1
	PlayerData.MarkChanged(player)
	Remotes.notify(player, string.format("🏕️ Obóz poz. %d: %d miejsc, %.1f XP co %d s", data.CampLevel, nextLevel.slots, nextLevel.xp, Chicks.trainTick))
end

local function addXp(chick, amount: number)
	chick.xp += amount
	local leveled = false
	while chick.level < Chicks.maxLevel and chick.xp >= Chicks.xpToNext(chick.level) do
		chick.xp -= Chicks.xpToNext(chick.level)
		chick.level += 1
		leveled = true
	end
	if chick.level >= Chicks.maxLevel then
		chick.xp = 0
		chick.training = false
	end
	return leveled
end

local function trainTick()
	local now = os.time()
	for _, player in Players:GetPlayers() do
		local data = PlayerData.Get(player)
		if data and not atWar[player] and #data.Chicks > 0 then
			local camp = Chicks.camp[data.CampLevel] or Chicks.camp[1]
			local changed = false
			for _, chick in data.Chicks do
				if chick.training and healthy(chick, now) then
					if addXp(chick, camp.xp) then
						Remotes.notify(player, string.format("💪 %s awansował na poziom %d!", chickName(chick), chick.level))
						Remotes.PlaySound:FireClient(player, "levelUp")
					end
					changed = true
				end
			end
			if changed then
				PlayerData.MarkChanged(player)
			end
			-- Odświeżamy też podpisy (np. koniec leczenia).
			ChickService.Refresh(player)
		end
	end
end

-- Pisklaki w zagrodzie dreptają w losowe miejsca.
local function wander()
	for player, camp in camps do
		local plot = PlotService.Get(player)
		if plot and not atWar[player] then
			for _, model in camp.chicks do
				if rng:NextNumber() < 0.4 and model.PrimaryPart and (model:GetAttribute("MoveUntil") or 0) < os.clock() then
					local target = randomPenPoint(plot)
					local duration = rng:NextNumber(1.5, 3)
					model:SetAttribute("MoveUntil", os.clock() + duration)
					local from = model:GetPivot()
					local look = CFrame.lookAt(from.Position, Vector3.new(target.X, from.Y, target.Z))
					local goal = CFrame.new(target.X, from.Y, target.Z) * look.Rotation
					local value = Instance.new("CFrameValue")
					value.Value = from
					local start = os.clock()
					local hops = math.max(2, math.floor(duration * 3))
					value.Changed:Connect(function(cf)
						if model.Parent then
							-- Pisklak podskakuje w trakcie dreptania.
							local alpha = math.min((os.clock() - start) / duration, 1)
							model:PivotTo(cf + Vector3.new(0, math.abs(math.sin(alpha * math.pi * hops)) * 0.6, 0))
						end
					end)
					local tween = TweenService:Create(value, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = goal })
					tween.Completed:Connect(function()
						value:Destroy()
						if model.Parent then
							model:PivotTo(goal)
						end
					end)
					tween:Play()
					if rng:NextNumber() < 0.15 then
						SoundFx.at("chirp", from.Position, 0.2)
					end
				end
			end
		end
	end
end

-- Wojna -----------------------------------------------------------------

local function armyPower(data, now: number)
	local total, count = 0, 0
	for _, chick in data.Chicks do
		if healthy(chick, now) then
			total += Chicks.power(chick)
			count += 1
		end
	end
	return total, count
end

-- Siła obrony działki: pisklaki w domu + postawione budowle obronne.
local function homeDefense(data, now: number, armyAway: boolean?)
	local power = armyAway and 0 or armyPower(data, now) * Chicks.war.homeFactor
	for id, count in data.Defenses or {} do
		power += (Chicks.war.defensePower[id] or 0) * count
	end
	return math.max(math.floor(power), Chicks.war.minDefense)
end

-- Siła obrony z pomocą sojuszników obrońcy (ich pisklaki pomagają z połową siły).
local function totalDefense(victim: Player, now: number)
	local data = PlayerData.Get(victim)
	if not data then
		return 0
	end
	local power = homeDefense(data, now, atWar[victim])
	for _, ally in AllianceService.Members(victim) do
		local allyData = ally ~= victim and PlayerData.Get(ally)
		if allyData and not atWar[ally] then
			power += math.floor(armyPower(allyData, now) * Chicks.war.allyHelp)
		end
	end
	return power
end

local battles = {} -- [victim userId] = { victim, attackers = { [Player] = power }, resolveAt }

local function getTargets(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return nil
	end
	local now = os.time()
	local power, count = armyPower(data, now)
	local players = {}
	for _, other in Players:GetPlayers() do
		local otherData = PlayerData.Get(other)
		if other ~= player and otherData and not AllianceService.AreAllies(player, other) then
			local battle = battles[other.UserId]
			local joinable = false
			if battle then
				for attacker in battle.attackers do
					if AllianceService.AreAllies(player, attacker) then
						joinable = true
					end
				end
			end
			table.insert(players, {
				userId = other.UserId,
				name = other.DisplayName,
				defense = totalDefense(other, now),
				cash = otherData.Cash,
				shield = math.max(0, (otherData.WarShieldUntil or 0) - now),
				allyAttacking = joinable, -- sojusznik już tam idzie: można dołączyć
				busy = battle ~= nil and not joinable,
			})
		end
	end
	return {
		power = power,
		count = count,
		cooldown = math.max(0, (data.WarCooldownUntil or 0) - now),
		atWar = atWar[player] == true,
		players = players,
	}
end

-- Animacja marszu: pisklaki z zagrody idą gęsiego w stronę celu i znikają za horyzontem.
local function marchArmy(player: Player, targetPosition: Vector3)
	local camp = camps[player]
	if not camp then
		return
	end
	local i = 0
	for uid, model in camp.chicks do
		i += 1
		local from = model:GetPivot()
		local flat = Vector3.new(targetPosition.X, from.Y, targetPosition.Z)
		local direction = (flat - from.Position)
		if direction.Magnitude < 1 then
			direction = Vector3.new(0, 0, -1)
		end
		local goal = CFrame.lookAt(flat - direction.Unit * (i * 3), flat)
		model:PivotTo(CFrame.lookAt(from.Position, flat))
		local value = Instance.new("CFrameValue")
		value.Value = model:GetPivot()
		local start = os.clock()
		value.Changed:Connect(function(cf)
			if model.Parent then
				-- Podskoki w marszu
				local hop = math.abs(math.sin((os.clock() - start) * 10 + i)) * 0.8
				model:PivotTo(cf + Vector3.new(0, hop, 0))
			end
		end)
		local tween = TweenService:Create(value, TweenInfo.new(Chicks.war.travelTime, Enum.EasingStyle.Linear), { Value = goal })
		tween.Completed:Connect(function()
			value:Destroy()
			model:Destroy()
		end)
		tween:Play()
		camp.chicks[uid] = nil
	end
	local plot = PlotService.Get(player)
	if plot then
		SoundFx.at("march", (plot.origin * CFrame.new(CAMP_POSITION)).Position)
	end
end

local function winXp(data, now: number)
	for _, chick in data.Chicks do
		if healthy(chick, now) then
			addXp(chick, Chicks.war.winXp)
		end
	end
end

local function injure(data, now: number)
	for _, chick in data.Chicks do
		if healthy(chick, now) then
			chick.injuredUntil = now + Chicks.war.injuredTime
		end
	end
end

local function finishArmy(player: Player)
	atWar[player] = nil
	player:SetAttribute("InBattle", nil) -- muzyka bitewna u klienta
	if player.Parent then
		PlayerData.MarkChanged(player)
		ChickService.Refresh(player)
	end
end

-- Rozstrzygnięcie bitwy z graczem: wszyscy napastnicy (sojusz) razem kontra obrona celu.
local function resolveBattle(key)
	local battle = battles[key]
	battles[key] = nil
	if not battle then
		return
	end
	local now = os.time()
	local victim = battle.victim
	victim:SetAttribute("InBattle", nil)
	local victimData = victim.Parent and PlayerData.Get(victim)
	local attackers = {}
	local power = 0
	for attacker, attackPower in battle.attackers do
		if attacker.Parent and PlayerData.Get(attacker) then
			table.insert(attackers, attacker)
			power += attackPower
		end
	end
	if not victimData then
		for _, attacker in attackers do
			Remotes.notify(attacker, battle.victimName .. " uciekł z serwera. Armia wraca do domu.")
			finishArmy(attacker)
		end
		return
	end
	local defense = totalDefense(victim, now)
	local names = {}
	for _, attacker in attackers do
		table.insert(names, attacker.DisplayName)
	end
	local attackerNames = table.concat(names, " i ")

	if #attackers > 0 and rng:NextNumber() < Chicks.winChance(power, defense) then
		-- Łup to najwyżej stealPercent gotówki ofiary, dzielony po równo między napastników.
		local total = math.floor(victimData.Cash * Chicks.war.stealPercent)
		local share = math.floor(total / #attackers)
		victimData.Cash -= share * #attackers
		victimData.WarShieldUntil = now + Chicks.war.victimShield
		PlayerData.MarkChanged(victim)
		RaidService.AddLog(victim, { kind = "warLost", name = attackerNames, amount = share * #attackers })
		Remotes.notify(victim, string.format("🐥⚔️ Pisklaki: %s pokonały Twoją obronę! -%s", attackerNames, Format.money(share * #attackers)))
		SoundFx.at("lose", (PlotService.Get(victim) and PlotService.Get(victim).origin.Position) or Vector3.zero)
		for _, attacker in attackers do
			local data = PlayerData.Get(attacker)
			winXp(data, now)
			PlayerData.AddCash(attacker, share)
			RaidService.AddLog(attacker, { kind = "warWon", name = victim.DisplayName, amount = share })
			local split = #attackers > 1 and string.format(" (łup podzielony na %d)", #attackers) or ""
			Remotes.notify(attacker, string.format("🏆 Wygrana z %s! +%s%s", victim.DisplayName, Format.money(share), split))
			Remotes.PlaySound:FireClient(attacker, "win")
			finishArmy(attacker)
		end
	else
		for _, attacker in attackers do
			injure(PlayerData.Get(attacker), now)
			Remotes.notify(attacker, string.format("💔 %s odparł atak. Pisklaki leczą się %d s.", victim.DisplayName, Chicks.war.injuredTime))
			Remotes.PlaySound:FireClient(attacker, "lose")
			finishArmy(attacker)
		end
		if #attackers > 0 then
			RaidService.AddLog(victim, { kind = "warDefended", name = attackerNames })
			Remotes.notify(victim, string.format("🛡️ Twoja baza odparła pisklaki: %s!", attackerNames))
			Remotes.PlaySound:FireClient(victim, "win")
		end
	end
end

local function sendToWar(player: Player, target)
	local data = PlayerData.Get(player)
	local plot = PlotService.Get(player)
	if not data or not plot then
		return
	end
	local now = os.time()
	if atWar[player] then
		Remotes.notify(player, "Twoja armia jest już w drodze.")
		return
	end
	if (data.WarCooldownUntil or 0) > now then
		Remotes.notify(player, string.format("Pisklaki odpoczywają jeszcze %d s.", data.WarCooldownUntil - now))
		return
	end
	local power, count = armyPower(data, now)
	if count == 0 then
		Remotes.notify(player, "Nie masz zdrowych pisklaków. Wykluj je za jajka 🥚.")
		return
	end

	if type(target) == "number" then
		local victim = Players:GetPlayerByUserId(target)
		local victimData = victim and victim ~= player and PlayerData.Get(victim)
		local victimPlot = victim and PlotService.Get(victim)
		if not victimData or not victimPlot then
			Remotes.notify(player, "Ten gracz już wyszedł.")
			return
		end
		if AllianceService.AreAllies(player, victim) then
			Remotes.notify(player, "Nie możesz atakować sojusznika.")
			return
		end
		local battle = battles[victim.UserId]
		if battle then
			local allied = false
			for attacker in battle.attackers do
				if AllianceService.AreAllies(player, attacker) then
					allied = true
				end
			end
			if not allied then
				Remotes.notify(player, "Ktoś inny już atakuje tę bazę. Spróbuj za chwilę.")
				return
			end
			if battle.resolveAt - os.clock() < 1 then
				Remotes.notify(player, "Za późno, bitwa właśnie się rozstrzyga.")
				return
			end
		elseif (victimData.WarShieldUntil or 0) > now then
			Remotes.notify(player, string.format("%s ma tarczę jeszcze %d s.", victim.DisplayName, victimData.WarShieldUntil - now))
			return
		end

		atWar[player] = true
		player:SetAttribute("InBattle", true)
		victim:SetAttribute("InBattle", true)
		data.WarCooldownUntil = now + Chicks.war.cooldown
		PlayerData.MarkChanged(player)
		marchArmy(player, (victimPlot.origin * CFrame.new(CAMP_POSITION)).Position)
		if battle then
			battle.attackers[player] = power
			for attacker in battle.attackers do
				Remotes.notify(attacker, string.format("🤝 %s dołącza do ataku na %s (+%d siły)!", player.DisplayName, victim.DisplayName, power))
			end
			Remotes.notify(victim, string.format("🚨 %s dołącza do ataku na Twoją bazę!", player.DisplayName))
		else
			battle = {
				victim = victim,
				victimName = victim.DisplayName,
				attackers = { [player] = power },
				resolveAt = os.clock() + Chicks.war.travelTime,
			}
			battles[victim.UserId] = battle
			Remotes.notify(player, string.format("⚔️ %d pisklaków (siła %d) maszeruje na bazę %s. Sojusznicy mogą dołączyć!", count, power, victim.DisplayName))
			Remotes.notify(victim, string.format("🚨 Pisklaki gracza %s idą na Twoją bazę! Kup obronę albo poproś sojuszników o pomoc.", player.DisplayName))
			Remotes.PlaySound:FireClient(victim, "invite")
			local key = victim.UserId
			task.delay(Chicks.war.travelTime, function()
				local ok, err = pcall(resolveBattle, key)
				if not ok then
					warn("[ChickService]", err)
				end
			end)
		end
		return
	end

	-- Dziki obóz: walka w pojedynkę.
	local index = type(target) == "string" and tonumber(string.match(target, "^bandit:(%d+)$"))
	local bandit = index and Chicks.war.bandits[index]
	if not bandit then
		return
	end
	atWar[player] = true
	player:SetAttribute("InBattle", true)
	data.WarCooldownUntil = now + Chicks.war.cooldown
	PlayerData.MarkChanged(player)
	Remotes.notify(player, string.format("⚔️ %d pisklaków (siła %d) idzie na: %s (obrona %d)", count, power, bandit.name, bandit.power))
	-- Dzikie obozy są za krawędzią wyspy, w kierunku od środka.
	marchArmy(player, plot.origin.Position * 1.6)
	task.delay(Chicks.war.travelTime, function()
		local current = PlayerData.Get(player)
		if not current then
			atWar[player] = nil
			return
		end
		local resolveNow = os.time()
		if rng:NextNumber() < Chicks.winChance(power, bandit.power) then
			winXp(current, resolveNow)
			current.Eggs += bandit.eggs
			PlayerData.AddCash(player, bandit.cash)
			Remotes.notify(player, string.format("🏆 Pokonano: %s! +%s i 🥚 %d", bandit.name, Format.money(bandit.cash), bandit.eggs))
			Remotes.PlaySound:FireClient(player, "win")
		else
			injure(current, resolveNow)
			Remotes.notify(player, string.format("💔 Przegrana z %s. Pisklaki leczą się %d s.", bandit.name, Chicks.war.injuredTime))
			Remotes.PlaySound:FireClient(player, "lose")
		end
		finishArmy(player)
	end)
end

function ChickService.PlayerLeft(player: Player)
	ChickService.Clear(player)
end

function ChickService.Init()
	Remotes.HatchChick.OnServerEvent:Connect(hatch)
	Remotes.TrainChick.OnServerEvent:Connect(setTraining)
	Remotes.UpgradeCamp.OnServerEvent:Connect(upgradeCamp)
	Remotes.SendToWar.OnServerEvent:Connect(sendToWar)

	local getTargetsFunction = Instance.new("RemoteFunction")
	getTargetsFunction.Name = "GetWarTargets"
	getTargetsFunction.OnServerInvoke = getTargets
	getTargetsFunction.Parent = ReplicatedStorage:WaitForChild("Remotes")

	task.spawn(function()
		local sinceTrain = 0
		while true do
			task.wait(1)
			sinceTrain += 1
			if sinceTrain >= Chicks.trainTick then
				sinceTrain = 0
				local ok, err = pcall(trainTick)
				if not ok then
					warn("[ChickService]", err)
				end
			end
			local ok, err = pcall(wander)
			if not ok then
				warn("[ChickService]", err)
			end
		end
	end)
end

return ChickService
