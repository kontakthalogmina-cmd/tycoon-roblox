-- Zakupy za $: poziomy kopalni i kilofy.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MineLevels = require(ReplicatedStorage.Shared.Config.MineLevels)
local Pickaxes = require(ReplicatedStorage.Shared.Config.Pickaxes)

local PlayerData = require(script.Parent.PlayerData)
local MineService = require(script.Parent.MineService)
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
end

return ShopService
