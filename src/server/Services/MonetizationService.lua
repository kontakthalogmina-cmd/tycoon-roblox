-- Zakupy za Robux: Developer Products (ProcessReceipt) i Game Pass z brainrot pistoletem maszynowym.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Products = require(ReplicatedStorage.Shared.Config.Products)

local PlayerData = require(script.Parent.PlayerData)
local FactoryService = require(script.Parent.FactoryService)
local Remotes = require(script.Parent.Remotes)
local WeaponTools = require(script.Parent.WeaponTools)

local MonetizationService = {}

local function grantCashPack(player: Player)
	local data = PlayerData.Get(player)
	local amount = FactoryService.Income(data.FactoryLevel) * Products.CashPack.incomeSeconds
	PlayerData.AddCash(player, amount)
	Remotes.notify(player, "Dziękujemy za zakup! Otrzymujesz gotówkę.")
end

local function grantFactoryUpgrade(player: Player)
	if not FactoryService.GrantLevel(player) then
		-- Fabryka już na maksie: zamiast poziomu dajemy pakiet gotówki.
		grantCashPack(player)
	end
end

local handlers = {}
if Products.FactoryUpgrade.productId ~= 0 then
	handlers[Products.FactoryUpgrade.productId] = grantFactoryUpgrade
end
if Products.CashPack.productId ~= 0 then
	handlers[Products.CashPack.productId] = grantCashPack
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or not PlayerData.Get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if PlayerData.HasReceipt(player, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local handler = handlers[receipt.ProductId]
	if not handler then
		warn("[Monetization] Nieznany produkt:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(handler, player)
	if not ok then
		warn("[Monetization] Błąd przyznawania produktu:", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PlayerData.AddReceipt(player, receipt.PurchaseId)
	-- Potwierdzamy zakup dopiero po udanym zapisie.
	if not PlayerData.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Game Pass: brainrot pistolet maszynowy -------------------------------------

local function grantSMG(player: Player, announce: boolean)
	local data = PlayerData.Get(player)
	local weaponId = Products.BrainrotSMG.weaponId
	if not data or data.OwnedWeapons[weaponId] then
		return
	end
	data.OwnedWeapons[weaponId] = true
	data.EquippedWeapon = weaponId
	PlayerData.MarkChanged(player)
	WeaponTools.Give(player)
	if announce then
		Remotes.notify(player, "🔫 Masz Brainrot Karabin Maszynowy! Jest w plecaku.")
	end
end

-- Sprawdza przy wejściu, czy gracz ma już Game Pass (np. kupił go poza grą).
-- Poza Studio odbiera też karabin wzięty za darmo podczas testów w Studio (zapisał się w danych).
function MonetizationService.PlayerAdded(player: Player)
	local passId = Products.BrainrotSMG.gamePassId
	local owns = false
	if passId ~= 0 then
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if not ok then
			return -- Roblox nie odpowiedział: nic nie zmieniamy
		end
		owns = result
	end
	if owns then
		grantSMG(player, false)
	elseif not RunService:IsStudio() then
		local data = PlayerData.Get(player)
		local weaponId = Products.BrainrotSMG.weaponId
		if data and data.OwnedWeapons[weaponId] then
			data.OwnedWeapons[weaponId] = nil
			if data.EquippedWeapon == weaponId then
				data.EquippedWeapon = ""
			end
			PlayerData.MarkChanged(player)
			WeaponTools.Give(player)
		end
	end
end

-- W Studio, dopóki nie ma prawdziwego Game Passa, broń można wziąć za darmo do testów.
function MonetizationService.CanTestSMG(): boolean
	return Products.BrainrotSMG.gamePassId == 0 and RunService:IsStudio()
end

function MonetizationService.GrantSMG(player: Player)
	grantSMG(player, true)
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == Products.BrainrotSMG.gamePassId and passId ~= 0 then
			grantSMG(player, true)
		end
	end)
end

return MonetizationService
