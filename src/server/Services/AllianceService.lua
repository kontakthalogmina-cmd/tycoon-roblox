-- Sojusze graczy na serwerze. Zaproszenie pokazuje okienko: Akceptuj / Ignoruj / Blokuj.
-- Sojusznicy nie mogą sobie szkodzić (jajka, karabiny, obrona działki, napady),
-- a pisklaki sojuszników mogą razem napaść na tę samą bazę i dzielą się łupem.
-- Sojusz trwa do wyjścia z serwera; zablokowani gracze są zapisywani na stałe.
local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local AllianceService = {}

AllianceService.MAX_MEMBERS = 4
local INVITE_COOLDOWN = 30 -- sekundy między zaproszeniami do tej samej osoby
local INVITE_TIMEOUT = 20 -- po tylu sekundach zaproszenie wygasa

local allianceOf = {} -- [Player] = { members = { Player } }
local pending = {} -- [target Player] = { [from Player] = os.clock() wysłania }
local lastInvite = {} -- [from Player] = { [target Player] = os.clock() }

local function members(player: Player)
	local alliance = allianceOf[player]
	return alliance and alliance.members or { player }
end

function AllianceService.AreAllies(a: Player?, b: Player?): boolean
	if not a or not b or a == b then
		return false
	end
	local alliance = allianceOf[a]
	return alliance ~= nil and alliance == allianceOf[b]
end

function AllianceService.Members(player: Player)
	return members(player)
end

local function sendState(player: Player)
	local list = {}
	for _, member in members(player) do
		if member ~= player then
			table.insert(list, { userId = member.UserId, name = member.DisplayName })
		end
	end
	Remotes.AllianceState:FireClient(player, { allies = list })
end

local function broadcast(alliance)
	for _, member in alliance.members do
		sendState(member)
	end
end

local function leave(player: Player, silent: boolean?)
	local alliance = allianceOf[player]
	if not alliance then
		return
	end
	allianceOf[player] = nil
	local index = table.find(alliance.members, player)
	if index then
		table.remove(alliance.members, index)
	end
	if #alliance.members == 1 then
		-- Sam w sojuszu = brak sojuszu.
		local last = alliance.members[1]
		allianceOf[last] = nil
		sendState(last)
		Remotes.notify(last, "Sojusz się rozpadł.")
	else
		broadcast(alliance)
		for _, member in alliance.members do
			Remotes.notify(member, player.DisplayName .. " opuścił sojusz.")
		end
	end
	if not silent and player.Parent then
		sendState(player)
		Remotes.notify(player, "Opuściłeś sojusz.")
	end
end

local function isBlocked(target: Player, from: Player)
	local data = PlayerData.Get(target)
	return data and data.BlockedPlayers[tostring(from.UserId)] == true
end

local function invite(from: Player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == from then
		return
	end
	if AllianceService.AreAllies(from, target) then
		Remotes.notify(from, target.DisplayName .. " już jest w Twoim sojuszu.")
		return
	end
	if #members(from) >= AllianceService.MAX_MEMBERS then
		Remotes.notify(from, string.format("Sojusz może mieć najwyżej %d graczy.", AllianceService.MAX_MEMBERS))
		return
	end
	local now = os.clock()
	lastInvite[from] = lastInvite[from] or {}
	local last = lastInvite[from][target]
	if last and now - last < INVITE_COOLDOWN then
		Remotes.notify(from, string.format("Poczekaj %d s przed kolejnym zaproszeniem.", math.ceil(INVITE_COOLDOWN - (now - last))))
		return
	end
	lastInvite[from][target] = now
	-- Zablokowany gracz nie wie, że jest zablokowany: zaproszenie po prostu przepada.
	Remotes.notify(from, "Wysłano zaproszenie do " .. target.DisplayName .. ".")
	if isBlocked(target, from) then
		return
	end
	pending[target] = pending[target] or {}
	pending[target][from] = now
	Remotes.AllianceInvite:FireClient(target, { userId = from.UserId, name = from.DisplayName, timeout = INVITE_TIMEOUT })
end

local function join(player: Player, inviter: Player)
	if allianceOf[player] then
		leave(player, true)
	end
	local alliance = allianceOf[inviter]
	if not alliance then
		alliance = { members = { inviter } }
		allianceOf[inviter] = alliance
	end
	table.insert(alliance.members, player)
	allianceOf[player] = alliance
	broadcast(alliance)
	for _, member in alliance.members do
		Remotes.notify(member, "🤝 " .. player.DisplayName .. " dołączył do sojuszu!")
	end
end

local function respond(player: Player, fromUserId, answer)
	if type(fromUserId) ~= "number" or type(answer) ~= "string" then
		return
	end
	local from = Players:GetPlayerByUserId(fromUserId)
	local invites = pending[player]
	local sentAt = from and invites and invites[from]
	if invites and from then
		invites[from] = nil
	end
	if answer == "block" then
		local data = PlayerData.Get(player)
		if data then
			data.BlockedPlayers[tostring(fromUserId)] = true
			PlayerData.MarkChanged(player)
		end
		Remotes.notify(player, "Zablokowano zaproszenia od tego gracza.")
		return
	end
	if answer ~= "accept" or not from or not sentAt then
		return
	end
	if os.clock() - sentAt > INVITE_TIMEOUT + 5 then
		Remotes.notify(player, "Zaproszenie wygasło.")
		return
	end
	if #members(from) >= AllianceService.MAX_MEMBERS then
		Remotes.notify(player, "Ten sojusz jest już pełny.")
		return
	end
	join(player, from)
end

local function unblockAll(player: Player)
	local data = PlayerData.Get(player)
	if data then
		data.BlockedPlayers = {}
		PlayerData.MarkChanged(player)
		Remotes.notify(player, "Odblokowano wszystkich graczy.")
	end
end

function AllianceService.PlayerAdded(player: Player)
	sendState(player)
end

function AllianceService.PlayerLeft(player: Player)
	leave(player, true)
	pending[player] = nil
	lastInvite[player] = nil
	for _, invites in pending do
		invites[player] = nil
	end
	for _, sent in lastInvite do
		sent[player] = nil
	end
end

function AllianceService.Init()
	Remotes.AllianceInviteSend.OnServerEvent:Connect(invite)
	Remotes.AllianceRespond.OnServerEvent:Connect(respond)
	Remotes.AllianceLeave.OnServerEvent:Connect(function(player)
		leave(player)
	end)
	Remotes.AllianceUnblock.OnServerEvent:Connect(unblockAll)
end

return AllianceService
