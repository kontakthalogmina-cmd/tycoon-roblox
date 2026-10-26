-- GUI gracza: pieniądze, surowce, ulepszenia fabryki i kopalni, sklep z kilofami.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Ores = require(Config.Ores)
local Pickaxes = require(Config.Pickaxes)
local MineLevels = require(Config.MineLevels)
local FactoryLevels = require(Config.FactoryLevels)
local Products = require(Config.Products)
local Format = require(Shared.Format)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local COLORS = {
	panel = Color3.fromRGB(28, 30, 38),
	section = Color3.fromRGB(40, 43, 54),
	text = Color3.fromRGB(240, 240, 245),
	muted = Color3.fromRGB(170, 175, 190),
	green = Color3.fromRGB(60, 170, 90),
	blue = Color3.fromRGB(60, 120, 220),
	robux = Color3.fromRGB(0, 160, 120),
	disabled = Color3.fromRGB(80, 82, 92),
}

local function make(className: string, props, children)
	local inst = Instance.new(className)
	for k, v in props or {} do
		inst[k] = v
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function padding(px)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = COLORS.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
	}
	for k, v in props do
		defaults[k] = v
	end
	return make("TextLabel", defaults)
end

local function button(text: string, color: Color3)
	return make("TextButton", {
		Text = text,
		BackgroundColor3 = color,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		AutoButtonColor = true,
		Size = UDim2.new(1, 0, 0, 34),
	}, { corner(6) })
end

local gui = make("ScreenGui", {
	Name = "TycoonGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Górny pasek z pieniędzmi
local cashLabel = label({
	Text = "$0",
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0.6, 0),
})
local incomeLabel = label({
	Text = "+$0/s",
	TextColor3 = Color3.fromRGB(120, 230, 140),
	TextXAlignment = Enum.TextXAlignment.Center,
	Position = UDim2.fromScale(0, 0.6),
	Size = UDim2.new(1, 0, 0.4, 0),
})
make("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(220, 64),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.15,
}, { corner(10), cashLabel, incomeLabel })

-- Lewy panel: surowce
local oreRows = {}
local orePanel = make("Frame", {
	Parent = gui,
	Position = UDim2.new(0, 12, 0.3, 0),
	Size = UDim2.fromOffset(170, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.15,
}, {
	corner(10),
	padding(10),
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	label({ Text = "Surowce", Font = Enum.Font.GothamBold, LayoutOrder = 0 }),
})
for i, ore in Ores.list do
	oreRows[ore.id] = label({
		Text = ore.name .. ": 0",
		TextColor3 = ore.color:Lerp(Color3.new(1, 1, 1), 0.35),
		LayoutOrder = i,
		Parent = orePanel,
	})
end

-- Panel ulepszeń (otwierany przyciskiem)
local shopPanel = make("ScrollingFrame", {
	Parent = gui,
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 380, 0.7, 0),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	BackgroundColor3 = COLORS.panel,
}, {
	corner(12),
	padding(12),
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	make("UISizeConstraint", { MaxSize = Vector2.new(380, 600) }),
})

local function section(title: string, order: number)
	local frame = make("Frame", {
		Parent = shopPanel,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COLORS.section,
	}, {
		corner(8),
		padding(10),
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		label({ Text = title, Font = Enum.Font.GothamBold, TextSize = 18, LayoutOrder = 0 }),
	})
	return frame
end

local function info(parent, order)
	return label({
		Parent = parent,
		LayoutOrder = order,
		TextColor3 = COLORS.muted,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
	})
end

-- Fabryka
local factorySection = section("🏭 Fabryka", 1)
local factoryInfo = info(factorySection, 1)
local factoryCost = info(factorySection, 2)
local factoryOreButton = button("Ulepsz za surowce", COLORS.green)
factoryOreButton.LayoutOrder = 3
factoryOreButton.Parent = factorySection
local factoryRobuxButton = button("Ulepsz za Robux", COLORS.robux)
factoryRobuxButton.LayoutOrder = 4
factoryRobuxButton.Parent = factorySection

-- Kopalnia
local mineSection = section("⛏️ Kopalnia", 2)
local mineInfo = info(mineSection, 1)
local mineButton = button("Ulepsz kopalnię", COLORS.blue)
mineButton.LayoutOrder = 2
mineButton.Parent = mineSection

-- Kilofy
local pickaxeSection = section("🪓 Kilofy", 3)
local pickaxeRows = {}
for i, pickaxe in Pickaxes.list do
	local text = label({
		Text = string.format("%s\nkopie poziom %d, siła %d", pickaxe.name, pickaxe.tier, pickaxe.damage),
		TextWrapped = true,
		Size = UDim2.new(0.6, 0, 1, 0),
		TextSize = 14,
	})
	local btn = button("", COLORS.blue)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.fromScale(1, 0.5)
	btn.Size = UDim2.new(0.38, 0, 0, 32)
	make("Frame", {
		Parent = pickaxeSection,
		LayoutOrder = i,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
	}, { text, btn })
	pickaxeRows[pickaxe.id] = btn
end

-- Robux (ID produktów z Products.lua)
local cashPackButton = button("Pakiet gotówki za Robux", COLORS.robux)
local robuxSection = section("💎 Sklep Robux", 4)
cashPackButton.LayoutOrder = 1
cashPackButton.Parent = robuxSection

local function setupProductButton(btn: TextButton, product, baseText: string)
	if product.productId == 0 then
		btn.Text = baseText .. " (brak ID produktu)"
		btn.BackgroundColor3 = COLORS.disabled
		btn.Active = false
		return
	end
	task.spawn(function()
		local ok, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(product.productId, Enum.InfoType.Product)
		end)
		if ok and productInfo.PriceInRobux then
			btn.Text = string.format("%s (R$ %d)", baseText, productInfo.PriceInRobux)
		end
	end)
	btn.Text = baseText
	btn.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, product.productId)
	end)
end
setupProductButton(factoryRobuxButton, Products.FactoryUpgrade, "Ulepsz za Robux")
setupProductButton(cashPackButton, Products.CashPack, "Pakiet gotówki")

-- Przycisk otwierający panel
local toggleButton = button("Ulepszenia", COLORS.green)
toggleButton.Parent = gui
toggleButton.AnchorPoint = Vector2.new(0.5, 1)
toggleButton.Position = UDim2.new(0.5, 0, 1, -16)
toggleButton.Size = UDim2.fromOffset(180, 44)
toggleButton.TextSize = 18
toggleButton.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	toggleButton.Text = shopPanel.Visible and "Zamknij" or "Ulepszenia"
end)

-- Komunikaty
local toast = label({
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -70),
	Size = UDim2.fromOffset(420, 36),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 1,
	TextTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.GothamBold,
	Text = "",
})
corner(8).Parent = toast
local toastToken = 0
Remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text: string)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.2
	task.delay(2.5, function()
		if token == toastToken then
			local tweenInfo = TweenInfo.new(0.4)
			TweenService:Create(toast, tweenInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end)

-- Akcje
factoryOreButton.Activated:Connect(function()
	Remotes.UpgradeFactory:FireServer()
end)
mineButton.Activated:Connect(function()
	Remotes.UpgradeMine:FireServer()
end)

local state = nil
for id, btn in pickaxeRows do
	btn.Activated:Connect(function()
		if not state then
			return
		end
		if state.OwnedPickaxes[id] then
			Remotes.EquipPickaxe:FireServer(id)
		else
			Remotes.BuyPickaxe:FireServer(id)
		end
	end)
end

local function costText(cost)
	local parts = {}
	for _, ore in Ores.list do
		local amount = cost[ore.id]
		if amount then
			local have = state.Ores[ore.id] or 0
			table.insert(parts, string.format("%s %d/%d", ore.name, have, amount))
		end
	end
	return table.concat(parts, ", ")
end

local function render()
	cashLabel.Text = Format.money(state.Cash)
	incomeLabel.Text = "+" .. Format.money(FactoryLevels[state.FactoryLevel].income) .. "/s"

	for _, ore in Ores.list do
		oreRows[ore.id].Text = string.format("%s: %s", ore.name, Format.number(state.Ores[ore.id] or 0))
	end

	-- Fabryka
	local nextFactory = FactoryLevels[state.FactoryLevel + 1]
	factoryInfo.Text = string.format(
		"Poziom %d/%d, produkcja %s/s",
		state.FactoryLevel,
		#FactoryLevels,
		Format.money(FactoryLevels[state.FactoryLevel].income)
	)
	if nextFactory then
		factoryCost.Text = string.format(
			"Następny poziom: %s/s\nKoszt: %s",
			Format.money(nextFactory.income),
			costText(nextFactory.cost)
		)
		factoryOreButton.Visible = true
		factoryRobuxButton.Visible = true
	else
		factoryCost.Text = "Maksymalny poziom!"
		factoryOreButton.Visible = false
		factoryRobuxButton.Visible = false
	end

	-- Kopalnia
	local mineLevel = MineLevels[state.MineLevel]
	local nextMine = MineLevels[state.MineLevel + 1]
	local unlocked = {}
	for _, ore in Ores.list do
		if ore.minMineLevel <= state.MineLevel then
			table.insert(unlocked, ore.name)
		end
	end
	mineInfo.Text = string.format(
		"Poziom %d/%d, bloki: %d\nSurowce: %s",
		state.MineLevel,
		#MineLevels,
		mineLevel.slots,
		table.concat(unlocked, ", ")
	)
	if nextMine then
		mineButton.Text = "Ulepsz kopalnię (" .. Format.money(nextMine.price) .. ")"
		mineButton.BackgroundColor3 = state.Cash >= nextMine.price and COLORS.blue or COLORS.disabled
		mineButton.Visible = true
	else
		mineButton.Visible = false
	end

	-- Kilofy
	for _, pickaxe in Pickaxes.list do
		local btn = pickaxeRows[pickaxe.id]
		if state.EquippedPickaxe == pickaxe.id then
			btn.Text = "Założony"
			btn.BackgroundColor3 = COLORS.disabled
		elseif state.OwnedPickaxes[pickaxe.id] then
			btn.Text = "Załóż"
			btn.BackgroundColor3 = COLORS.green
		else
			btn.Text = Format.money(pickaxe.price)
			btn.BackgroundColor3 = state.Cash >= pickaxe.price and COLORS.blue or COLORS.disabled
		end
	end
end

Remotes:WaitForChild("DataUpdate").OnClientEvent:Connect(function(snapshot)
	state = snapshot
	render()
end)
