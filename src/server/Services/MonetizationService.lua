-- Developer Products (Robux): obsługa ProcessReceipt.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Config.Products)

local PlayerData = require(script.Parent.PlayerData)
local FactoryService = require(script.Parent.FactoryService)
local Remotes = require(script.Parent.Remotes)

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

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
