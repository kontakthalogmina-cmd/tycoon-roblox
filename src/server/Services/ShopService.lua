-- Zakupy za $: poziomy kopalni, kilofy, szczęście i skórki jajek.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MineLevels = require(ReplicatedStorage.Shared.Config.MineLevels)
local Pickaxes = require(ReplicatedStorage.Shared.Config.Pickaxes)
local LuckLevels = require(ReplicatedStorage.Shared.Config.LuckLevels)
local EggSkins = require(ReplicatedStorage.Shared.Config.EggSkins)

local PlayerData = require(script.Parent.PlayerData)
local MineService = require(script.Parent.MineService)
local PickaxeTool = require(script.Parent.PickaxeTool)
local Remotes = require(script.Parent.Remotes)

local ShopService = {}

function ShopService.UpgradeMine(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local nextLevel = MineLevels[data.MineLevel + 1]
	if not nextLevel then
		Remotes.notify(player, "Kopalnia ma już maksymalny poziom.")
		return
	end
	if data.Cash < nextLevel.price then
		Remotes.notify(player, "Za mało pieniędzy na ulepszenie kopalni.")
		return
	end
	data.Cash -= nextLevel.price
	data.MineLevel += 1
	PlayerData.MarkChanged(player)
	MineService.Refresh(player)
	Remotes.notify(player, string.format("Kopalnia ulepszona do poziomu %d!", data.MineLevel))
end

function ShopService.BuyPickaxe(player: Player, pickaxeId)
	local data = PlayerData.Get(player)
	local pickaxe = type(pickaxeId) == "string" and Pickaxes.byId[pickaxeId]
	if not data or not pickaxe then
		return
	end
	if data.OwnedPickaxes[pickaxe.id] then
		return
	end
	if data.Cash < pickaxe.price then
		Remotes.notify(player, "Za mało pieniędzy na " .. pickaxe.name .. ".")
		return
	end
	data.Cash -= pickaxe.price
	data.OwnedPickaxes[pickaxe.id] = true
	data.EquippedPickaxe = pickaxe.id
	PlayerData.MarkChanged(player)
	PickaxeTool.Give(player)
	Remotes.notify(player, "Kupiono: " .. pickaxe.name)
end

function ShopService.EquipPickaxe(player: Player, pickaxeId)
	local data = PlayerData.Get(player)
	if not data or type(pickaxeId) ~= "string" or not data.OwnedPickaxes[pickaxeId] then
		return
	end
	if not Pickaxes.byId[pickaxeId] then
		return
	end
	data.EquippedPickaxe = pickaxeId
	PlayerData.MarkChanged(player)
	PickaxeTool.Give(player)
end

function ShopService.UpgradeLuck(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	local nextLevel = LuckLevels[data.LuckLevel + 1]
	if not nextLevel then
		Remotes.notify(player, "Szczęście ma już maksymalny poziom.")
		return
	end
	if data.Cash < nextLevel.price then
		Remotes.notify(player, "Za mało pieniędzy na szczęście.")
		return
	end
	data.Cash -= nextLevel.price
	data.LuckLevel += 1
	PlayerData.MarkChanged(player)
	Remotes.notify(player, string.format("Szczęście x%s!", tostring(nextLevel.luck)))
end

function ShopService.BuyEggSkin(player: Player, skinId)
	local data = PlayerData.Get(player)
	local skin = type(skinId) == "string" and EggSkins.byId[skinId]
	if not data or not skin or data.OwnedEggSkins[skin.id] then
		return
	end
	if data.Cash < skin.price then
		Remotes.notify(player, "Za mało pieniędzy na skórkę " .. skin.name .. ".")
		return
	end
	data.Cash -= skin.price
	data.OwnedEggSkins[skin.id] = true
	data.EquippedEggSkin = skin.id
	PlayerData.MarkChanged(player)
	Remotes.notify(player, "Nowa skórka jajek: " .. skin.name)
end

function ShopService.EquipEggSkin(player: Player, skinId)
	local data = PlayerData.Get(player)
	if not data or type(skinId) ~= "string" or not data.OwnedEggSkins[skinId] or not EggSkins.byId[skinId] then
		return
	end
	data.EquippedEggSkin = skinId
	PlayerData.MarkChanged(player)
end

return ShopService
