-- GUI gracza: licznik pieniędzy, surowce, komunikaty i sklep z ulepszeniami.
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
local LuckLevels = require(Config.LuckLevels)
local EggSkins = require(Config.EggSkins)
local EggRarities = require(Config.EggRarities)
local LineConfig = require(Config.ProductionLine)
local EggOdds = require(Shared.EggOdds)
local Format = require(Shared.Format)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local localNotify = Instance.new("BindableEvent")
localNotify.Name = "LocalNotify"
localNotify.Parent = ReplicatedStorage

local TITLE_FONT = Enum.Font.FredokaOne
local BODY_FONT = Enum.Font.GothamMedium

local C = {
	window = Color3.fromRGB(24, 26, 36),
	sidebar = Color3.fromRGB(18, 20, 28),
	card = Color3.fromRGB(36, 39, 54),
	cardStroke = Color3.fromRGB(62, 66, 90),
	text = Color3.fromRGB(245, 245, 250),
	muted = Color3.fromRGB(165, 170, 190),
	green = Color3.fromRGB(70, 200, 100),
	blue = Color3.fromRGB(70, 140, 255),
	orange = Color3.fromRGB(255, 150, 40),
	robux = Color3.fromRGB(0, 180, 130),
	red = Color3.fromRGB(230, 70, 80),
	disabled = Color3.fromRGB(78, 80, 95),
	gold = Color3.fromRGB(255, 210, 70),
}

---------------------------------------------------------------------------
-- Pomocnicze
---------------------------------------------------------------------------

local function make(className: string, props, children)
	local inst = Instance.new(className)
	for k, v in props or {} do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius)
	return make("UICorner", { CornerRadius = radius or UDim.new(0, 10) })
end

local function stroke(color, thickness)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(px)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function text(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = BODY_FONT,
		TextColor3 = C.text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
		RichText = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return make("TextLabel", defaults)
end

local function lighten(color: Color3, amount: number)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function hex(color: Color3)
	return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

-- Przycisk z gradientem, obrysem i powiększeniem po najechaniu.
-- Uwaga: UIGradient barwi także tekst przycisku, dlatego gradient jest tylko
-- jasno-szary (cieniowanie), a kolor przycisku siedzi w BackgroundColor3.
local SHADE = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205))

local function button(label: string, color: Color3, size: UDim2?)
	local btn = make("TextButton", {
		Text = label,
		Font = TITLE_FONT,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.55,
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Size = size or UDim2.fromOffset(150, 42),
	}, {
		corner(UDim.new(0, 10)),
		make("UIStroke", {
			Name = "Stroke",
			Color = color:Lerp(Color3.new(0, 0, 0), 0.4),
			Thickness = 2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		make("UIGradient", {
			Name = "Gradient",
			Rotation = 90,
			Color = SHADE,
		}),
		make("UIScale", { Name = "Scale" }),
	})
	local scale = btn.Scale
	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.05 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.95 }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.05 }):Play()
	end)
	return btn
end

local function setButtonColor(btn: TextButton, color: Color3)
	btn.BackgroundColor3 = color
	btn.Stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.4)
end

-- Pasek postępu (np. poziom 3/10).
local function progressBar(parent: Instance, order: number, color: Color3)
	local fill = make("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromScale(0, 1),
	}, { corner(UDim.new(1, 0)) })
	local caption = text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = TITLE_FONT,
		TextSize = 14,
		ZIndex = 2,
	})
	make("Frame", {
		Parent = parent,
		LayoutOrder = order,
		BackgroundColor3 = Color3.fromRGB(15, 16, 22),
		Size = UDim2.new(1, 0, 0, 20),
	}, { corner(UDim.new(1, 0)), fill, caption })
	return function(current: number, max: number)
		fill.Size = UDim2.fromScale(math.clamp(current / max, 0.04, 1), 1)
		caption.Text = string.format("Poziom %d / %d", current, max)
	end
end

-- Karta z ikoną po lewej, tekstami w środku i przyciskiem po prawej.
local function card(parent: Instance, order: number, iconColor: Color3, iconText: string?)
	local icon = make("Frame", {
		Size = UDim2.fromOffset(56, 56),
		Position = UDim2.new(0, 0, 0.5, -28),
		BackgroundColor3 = iconColor,
	}, {
		corner(UDim.new(1, 0)),
		stroke(lighten(iconColor, 0.4), 2),
		make("UIGradient", { Rotation = 45, Color = ColorSequence.new(lighten(iconColor, 0.35), iconColor) }),
	})
	if iconText then
		text({
			Parent = icon,
			Text = iconText,
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 28,
			Font = Enum.Font.GothamBold,
		})
	end
	local title = text({
		Font = TITLE_FONT,
		TextSize = 20,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
	})
	local desc = text({
		TextColor3 = C.muted,
		TextSize = 14,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})
	local middle = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(68, 0),
		Size = UDim2.new(1, -68 - 150, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		title,
		desc,
	})
	local btn = button("", C.blue, UDim2.fromOffset(138, 42))
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.fromScale(1, 0.5)
	local frame = make("Frame", {
		Parent = parent,
		LayoutOrder = order,
		BackgroundColor3 = C.card,
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		corner(UDim.new(0, 12)),
		stroke(C.cardStroke, 1.5),
		padding(10),
		make("UISizeConstraint", { MinSize = Vector2.new(0, 76) }),
		icon,
		middle,
		btn,
	})
	return { frame = frame, icon = icon, title = title, desc = desc, button = btn }
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------

local gui = make("ScreenGui", {
	Name = "TycoonGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local cashLabel = text({
	Text = "$0",
	Font = TITLE_FONT,
	TextSize = 32,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 36),
	TextColor3 = C.gold,
	TextStrokeTransparency = 0.6,
})
local statsLabel = text({
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 14,
	TextColor3 = C.muted,
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 0, 18),
})
local cashScale = make("UIScale")
make("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(280, 62),
	BackgroundColor3 = C.window,
	BackgroundTransparency = 0.1,
}, {
	corner(UDim.new(0, 16)),
	stroke(Color3.fromRGB(255, 200, 60), 2),
	cashScale,
	cashLabel,
	statsLabel,
})

-- Surowce po lewej
local oreRows = {}
local orePanel = make("Frame", {
	Parent = gui,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(170, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = C.window,
	BackgroundTransparency = 0.15,
}, {
	corner(UDim.new(0, 14)),
	stroke(C.cardStroke, 1.5),
	padding(10),
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	text({ Text = "SUROWCE", Font = TITLE_FONT, TextSize = 18, LayoutOrder = 0 }),
})
for i, ore in Ores.list do
	local dot = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = ore.color,
	}, { corner(UDim.new(1, 0)), stroke(lighten(ore.color, 0.4), 1) })
	local label = text({ Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = 15 })
	make("Frame", {
		Parent = orePanel,
		LayoutOrder = i,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
	}, { dot, label })
	oreRows[ore.id] = label
end

-- Komunikaty
local toast = text({
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 82),
	Size = UDim2.fromOffset(0, 38),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = C.window,
	BackgroundTransparency = 1,
	TextTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = TITLE_FONT,
	TextSize = 18,
	Text = "",
})
corner(UDim.new(0, 12)).Parent = toast
make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = toast })
local toastToken = 0
local function showToast(message: string)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.15
	task.delay(2.5, function()
		if token == toastToken then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end
Remotes:WaitForChild("Notify").OnClientEvent:Connect(showToast)
localNotify.Event:Connect(showToast)

---------------------------------------------------------------------------
-- Okno sklepu
---------------------------------------------------------------------------

local overlay = make("TextButton", {
	Parent = gui,
	Visible = false,
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 5,
})

local windowScale = make("UIScale")
local window = make("Frame", {
	Parent = overlay,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.82),
	BackgroundColor3 = C.window,
	Active = true,
}, {
	corner(UDim.new(0, 18)),
	stroke(Color3.fromRGB(255, 190, 60), 3),
	make("UISizeConstraint", { MaxSize = Vector2.new(760, 500) }),
	windowScale,
})

-- Nagłówek
local header = make("Frame", {
	Parent = window,
	Size = UDim2.new(1, 0, 0, 56),
	BackgroundColor3 = Color3.fromRGB(255, 160, 40),
}, {
	corner(UDim.new(0, 18)),
	make("UIGradient", { Rotation = 0, Color = ColorSequence.new(Color3.fromRGB(255, 190, 50), Color3.fromRGB(255, 120, 40)) }),
	text({
		Text = "🛒  SKLEP Z ULEPSZENIAMI",
		Font = TITLE_FONT,
		TextSize = 26,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 1, 0),
		TextStrokeTransparency = 0.5,
	}),
})
-- Zaokrąglenie tylko u góry: zasłaniamy dolne rogi paskiem.
make("Frame", {
	Parent = header,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 1, -18),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = Color3.new(1, 1, 1),
}, { make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 190, 50), Color3.fromRGB(255, 120, 40)) }) })
local closeButton = button("X", C.red, UDim2.fromOffset(40, 40))
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.ZIndex = 2
closeButton.Parent = header

-- Zakładki po lewej
local sidebar = make("Frame", {
	Parent = window,
	Position = UDim2.fromOffset(10, 66),
	Size = UDim2.new(0, 150, 1, -76),
	BackgroundColor3 = C.sidebar,
}, {
	corner(UDim.new(0, 12)),
	padding(8),
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local content = make("ScrollingFrame", {
	Parent = window,
	Position = UDim2.fromOffset(170, 66),
	Size = UDim2.new(1, -180, 1, -76),
	BackgroundTransparency = 1,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = C.cardStroke,
	BorderSizePixel = 0,
})

local tabs = {}
local tabButtons = {}
local currentTab = nil

local function newPage()
	return make("Frame", {
		Parent = content,
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
end

local function selectTab(id: string)
	currentTab = id
	for tabId, page in tabs do
		page.Visible = tabId == id
	end
	for tabId, btn in tabButtons do
		setButtonColor(btn, tabId == id and btn:GetAttribute("Accent") or C.disabled)
	end
	content.CanvasPosition = Vector2.zero
end

local function addTab(id: string, label: string, accent: Color3, order: number)
	local page = newPage()
	tabs[id] = page
	local btn = button(label, accent, UDim2.new(1, 0, 0, 44))
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextSize = 17
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = btn })
	btn:SetAttribute("Accent", accent)
	btn.LayoutOrder = order
	btn.Parent = sidebar
	btn.Activated:Connect(function()
		selectTab(id)
	end)
	tabButtons[id] = btn
	return page
end

local function sectionTitle(parent, order, label)
	return text({ Parent = parent, LayoutOrder = order, Text = label, Font = TITLE_FONT, TextSize = 22, Size = UDim2.new(1, 0, 0, 28) })
end

local state = nil

-- Zakładka: Fabryka -----------------------------------------------------
local factoryPage = addTab("factory", "🏭 Fabryka", C.orange, 1)
sectionTitle(factoryPage, 0, "Fabryka jajek")
local factoryCard = card(factoryPage, 1, C.orange, "🏭")
local setFactoryProgress = progressBar(factoryPage, 2, C.orange)
local factoryCostTitle = text({ Parent = factoryPage, LayoutOrder = 3, Font = TITLE_FONT, TextSize = 17, Text = "Koszt ulepszenia:" })
local factoryCostRow = make("Frame", {
	Parent = factoryPage,
	LayoutOrder = 4,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
}, {
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6) }),
})
local factoryRobux = card(factoryPage, 5, C.robux, "R$")
factoryRobux.title.Text = "Ulepszenie za Robux"
factoryRobux.desc.Text = "Natychmiast podnosi fabrykę o jeden poziom, bez surowców."

-- Zakładka: Kopalnia ----------------------------------------------------
local minePage = addTab("mine", "🪨 Kopalnia", C.blue, 2)
sectionTitle(minePage, 0, "Kopalnia")
local mineCard = card(minePage, 1, Color3.fromRGB(110, 100, 95), "🪨")
local setMineProgress = progressBar(minePage, 2, C.blue)
local mineOres = text({ Parent = minePage, LayoutOrder = 3, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = C.muted })

-- Zakładka: Kilofy ------------------------------------------------------
local pickaxePage = addTab("pickaxes", "⛏️ Kilofy", Color3.fromRGB(150, 110, 70), 3)
sectionTitle(pickaxePage, 0, "Kilofy")
local pickaxeCards = {}
for i, pickaxe in Pickaxes.list do
	local c = card(pickaxePage, i, pickaxe.color, "⛏️")
	c.title.Text = pickaxe.name
	local canMine = {}
	for _, ore in Ores.list do
		if ore.tier <= pickaxe.tier then
			table.insert(canMine, string.format('<font color="%s">%s</font>', hex(lighten(ore.color, 0.3)), ore.name))
		end
	end
	c.desc.Text = string.format("Siła %d  •  Kopie: %s", pickaxe.damage, table.concat(canMine, ", "))
	c.button.Activated:Connect(function()
		if state and state.OwnedPickaxes[pickaxe.id] then
			Remotes.EquipPickaxe:FireServer(pickaxe.id)
		else
			Remotes.BuyPickaxe:FireServer(pickaxe.id)
		end
	end)
	pickaxeCards[pickaxe.id] = c
end

-- Zakładka: Szczęście ---------------------------------------------------
local luckPage = addTab("luck", "🍀 Szczęście", C.green, 4)
sectionTitle(luckPage, 0, "Szczęście")
local luckCard = card(luckPage, 1, C.green, "🍀")
local setLuckProgress = progressBar(luckPage, 2, C.green)
text({ Parent = luckPage, LayoutOrder = 3, Font = TITLE_FONT, TextSize = 17, Text = "Szanse na jajka:" })
local oddsGrid = make("Frame", {
	Parent = luckPage,
	LayoutOrder = 4,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
}, {
	make("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 30), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local oddsLabels = {}
for i, rarity in EggRarities do
	local row = make("Frame", { Parent = oddsGrid, LayoutOrder = i, BackgroundColor3 = C.card }, {
		corner(UDim.new(0, 8)),
		make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	local nameLabel = text({ Parent = row, Size = UDim2.fromScale(0.65, 1), Font = TITLE_FONT, TextColor3 = rarity.color, Text = string.format("%s  x%d", rarity.name, rarity.multiplier) })
	if rarity.effect == "rainbow" then
		game:GetService("CollectionService"):AddTag(nameLabel, "Rainbow")
	end
	oddsLabels[i] = text({ Parent = row, Position = UDim2.fromScale(0.65, 0), Size = UDim2.fromScale(0.35, 1), TextXAlignment = Enum.TextXAlignment.Right })
end

-- Zakładka: Skórki jajek ------------------------------------------------
local skinPage = addTab("skins", "🥚 Skórki", Color3.fromRGB(200, 110, 255), 5)
sectionTitle(skinPage, 0, "Skórki jajek")
text({ Parent = skinPage, LayoutOrder = 1, TextColor3 = C.muted, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Text = "Skórka zmienia wygląd zwykłych jajek i podnosi wartość wszystkich jajek." })
local skinGrid = make("Frame", {
	Parent = skinPage,
	LayoutOrder = 2,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
}, {
	make("UIGridLayout", { CellSize = UDim2.fromOffset(170, 200), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local skinButtons = {}
for i, skin in EggSkins.list do
	local egg = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(56, 72),
		BackgroundColor3 = skin.color,
	}, {
		corner(UDim.new(0.5, 0)),
		stroke(lighten(skin.color, 0.4), 2),
	})
	if skin.rainbow then
		make("UIGradient", {
			Parent = egg,
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 230, 110)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 70, 255)),
			}),
		})
	else
		make("UIGradient", { Parent = egg, Rotation = 45, Color = ColorSequence.new(lighten(skin.color, 0.35), skin.color) })
	end
	local btn = button("", C.blue, UDim2.new(1, -20, 0, 38))
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -10)
	make("Frame", {
		Parent = skinGrid,
		LayoutOrder = i,
		BackgroundColor3 = C.card,
	}, {
		corner(UDim.new(0, 12)),
		stroke(C.cardStroke, 1.5),
		egg,
		text({ Text = skin.name, Font = TITLE_FONT, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, 22) }),
		text({
			Text = string.format("+%d%% wartości", math.floor((skin.bonus - 1) * 100 + 0.5)),
			TextColor3 = C.muted,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromOffset(0, 110),
			Size = UDim2.new(1, 0, 0, 18),
		}),
		btn,
	})
	btn.Activated:Connect(function()
		if state and state.OwnedEggSkins[skin.id] then
			Remotes.EquipEggSkin:FireServer(skin.id)
		else
			Remotes.BuyEggSkin:FireServer(skin.id)
		end
	end)
	skinButtons[skin.id] = btn
end

-- Zakładka: Robux -------------------------------------------------------
local robuxPage = addTab("robux", "💎 Robux", C.robux, 6)
sectionTitle(robuxPage, 0, "Sklep Robux")
local robuxFactory = card(robuxPage, 1, C.orange, "🏭")
robuxFactory.title.Text = "Ulepszenie fabryki"
robuxFactory.desc.Text = "Fabryka +1 poziom od razu."
local robuxCash = card(robuxPage, 2, C.gold, "💰")
robuxCash.title.Text = "Pakiet gotówki"
robuxCash.desc.Text = string.format("Gotówka równa %d minutom produkcji fabryki.", Products.CashPack.incomeSeconds // 60)

local function setupProductButton(btn: TextButton, product)
	if product.productId == 0 then
		btn.Text = "Wkrótce"
		setButtonColor(btn, C.disabled)
		return
	end
	btn.Text = "R$ ..."
	setButtonColor(btn, C.robux)
	task.spawn(function()
		local ok, productInfo = pcall(function()
			return MarketplaceService:GetProductInfo(product.productId, Enum.InfoType.Product)
		end)
		if ok and productInfo.PriceInRobux then
			btn.Text = "R$ " .. productInfo.PriceInRobux
		end
	end)
	btn.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, product.productId)
	end)
end
setupProductButton(factoryRobux.button, Products.FactoryUpgrade)
setupProductButton(robuxFactory.button, Products.FactoryUpgrade)
setupProductButton(robuxCash.button, Products.CashPack)

-- Otwieranie i zamykanie ------------------------------------------------
local function openShop(tab: string?)
	selectTab(tab or currentTab or "factory")
	overlay.Visible = true
	windowScale.Scale = 0.85
	TweenService:Create(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local function closeShop()
	overlay.Visible = false
end

closeButton.Activated:Connect(closeShop)
overlay.Activated:Connect(closeShop)
Remotes:WaitForChild("OpenShop").OnClientEvent:Connect(function()
	openShop()
end)

local shopButton = button("🛒  SKLEP", C.orange, UDim2.fromOffset(190, 54))
shopButton.TextSize = 24
shopButton.AnchorPoint = Vector2.new(0.5, 1)
shopButton.Position = UDim2.new(0.5, 0, 1, -18)
shopButton.Parent = gui
shopButton.Activated:Connect(function()
	if overlay.Visible then
		closeShop()
	else
		openShop()
	end
end)

-- Akcje w zakładkach
factoryCard.button.Activated:Connect(function()
	Remotes.UpgradeFactory:FireServer()
end)
mineCard.button.Activated:Connect(function()
	Remotes.UpgradeMine:FireServer()
end)
luckCard.button.Activated:Connect(function()
	Remotes.UpgradeLuck:FireServer()
end)

---------------------------------------------------------------------------
-- Odświeżanie
---------------------------------------------------------------------------

local costChips = {}

local function renderFactory(eggValue: number)
	local level = state.FactoryLevel
	local nextLevel = FactoryLevels[level + 1]
	setFactoryProgress(level, #FactoryLevels)
	factoryCard.title.Text = "Poziom " .. level
	for _, chip in costChips do
		chip:Destroy()
	end
	table.clear(costChips)

	if not nextLevel then
		factoryCard.desc.Text = string.format("Zwykłe jajko: %s. Maksymalny poziom!", Format.money(eggValue))
		factoryCard.button.Visible = false
		factoryCostTitle.Visible = false
		factoryRobux.frame.Visible = false
		return
	end
	factoryCard.desc.Text = string.format(
		"Zwykłe jajko: %s  →  <font color=\"#7CFF9A\">%s</font>",
		Format.money(eggValue),
		Format.money(nextLevel.income * LineConfig.interval)
	)
	factoryCard.button.Visible = true
	factoryCostTitle.Visible = true
	factoryRobux.frame.Visible = Products.FactoryUpgrade.productId ~= 0

	local affordable = true
	for _, ore in Ores.list do
		local amount = nextLevel.cost[ore.id]
		if amount then
			local have = state.Ores[ore.id] or 0
			local enough = have >= amount
			affordable = affordable and enough
			local chip = make("Frame", {
				Parent = factoryCostRow,
				BackgroundColor3 = C.card,
				Size = UDim2.fromOffset(0, 32),
				AutomaticSize = Enum.AutomaticSize.X,
			}, {
				corner(UDim.new(1, 0)),
				stroke(enough and C.green or C.red, 1.5),
				make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }),
				make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6) }),
				make("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundColor3 = ore.color }, { corner(UDim.new(1, 0)) }),
				text({
					Size = UDim2.fromOffset(0, 32),
					AutomaticSize = Enum.AutomaticSize.X,
					Font = TITLE_FONT,
					TextColor3 = enough and C.text or Color3.fromRGB(255, 140, 140),
					Text = string.format("%s %s/%s", ore.name, Format.number(have), Format.number(amount)),
				}),
			})
			table.insert(costChips, chip)
		end
	end
	factoryCard.button.Text = "Ulepsz"
	setButtonColor(factoryCard.button, affordable and C.green or C.disabled)
end

local function renderMine()
	local level = state.MineLevel
	local nextLevel = MineLevels[level + 1]
	setMineProgress(level, #MineLevels)
	mineCard.title.Text = "Poziom " .. level
	local unlocked, locked = {}, {}
	for _, ore in Ores.list do
		local name = string.format('<font color="%s">%s</font>', hex(lighten(ore.color, 0.3)), ore.name)
		if ore.minMineLevel <= level then
			table.insert(unlocked, name)
		else
			table.insert(locked, string.format("%s (poz. %d)", ore.name, ore.minMineLevel))
		end
	end
	mineOres.Text = "Rudy w kopalni: " .. table.concat(unlocked, ", ")
		.. (#locked > 0 and ("\nDo odblokowania: " .. table.concat(locked, ", ")) or "")
	if nextLevel then
		mineCard.desc.Text = string.format(
			"Skał: %d → %d, odradzanie %ss → %ss",
			MineLevels[level].slots,
			nextLevel.slots,
			tostring(MineLevels[level].respawn),
			tostring(nextLevel.respawn)
		)
		mineCard.button.Visible = true
		mineCard.button.Text = Format.money(nextLevel.price)
		setButtonColor(mineCard.button, state.Cash >= nextLevel.price and C.blue or C.disabled)
	else
		mineCard.desc.Text = string.format("Skał: %d. Maksymalny poziom!", MineLevels[level].slots)
		mineCard.button.Visible = false
	end
end

local function renderPickaxes()
	for _, pickaxe in Pickaxes.list do
		local btn = pickaxeCards[pickaxe.id].button
		if state.EquippedPickaxe == pickaxe.id then
			btn.Text = "W ręce"
			setButtonColor(btn, C.disabled)
		elseif state.OwnedPickaxes[pickaxe.id] then
			btn.Text = "Weź"
			setButtonColor(btn, C.green)
		else
			btn.Text = Format.money(pickaxe.price)
			setButtonColor(btn, state.Cash >= pickaxe.price and C.blue or C.disabled)
		end
	end
end

local function renderLuck(luck: number)
	local nextLevel = LuckLevels[state.LuckLevel + 1]
	setLuckProgress(state.LuckLevel, #LuckLevels)
	luckCard.title.Text = string.format("Szczęście +%d%%", math.floor((luck - 1) * 100 + 0.5))
	local chances = EggOdds.chances(luck)
	for i in EggRarities do
		local pct = chances[i] * 100
		oddsLabels[i].Text = pct >= 1 and string.format("%.1f%%", pct) or string.format("%.2f%%", pct)
	end
	if nextLevel then
		luckCard.desc.Text = string.format("Następny poziom: +%d%% szansy na lepsze jajka.", math.floor((nextLevel.luck - 1) * 100 + 0.5))
		luckCard.button.Visible = true
		luckCard.button.Text = Format.money(nextLevel.price)
		setButtonColor(luckCard.button, state.Cash >= nextLevel.price and C.green or C.disabled)
	else
		luckCard.desc.Text = "Maksymalne szczęście!"
		luckCard.button.Visible = false
	end
end

local function renderSkins()
	for _, skin in EggSkins.list do
		local btn = skinButtons[skin.id]
		if state.EquippedEggSkin == skin.id then
			btn.Text = "Założona"
			setButtonColor(btn, C.disabled)
		elseif state.OwnedEggSkins[skin.id] then
			btn.Text = "Załóż"
			setButtonColor(btn, C.green)
		else
			btn.Text = Format.money(skin.price)
			setButtonColor(btn, state.Cash >= skin.price and C.blue or C.disabled)
		end
	end
end

local lastCash = 0
local function render()
	local luck = LuckLevels[state.LuckLevel].luck
	local eggValue = FactoryLevels[state.FactoryLevel].income * LineConfig.interval

	cashLabel.Text = Format.money(state.Cash)
	if state.Cash > lastCash then
		cashScale.Scale = 1.08
		TweenService:Create(cashScale, TweenInfo.new(0.2), { Scale = 1 }):Play()
	end
	lastCash = state.Cash
	statsLabel.Text = string.format("🥚 jajko od %s   🍀 +%d%%", Format.money(eggValue), math.floor((luck - 1) * 100 + 0.5))

	for _, ore in Ores.list do
		local unlocked = ore.minMineLevel <= state.MineLevel
		local row = oreRows[ore.id]
		row.Text = string.format("%s  <b>%s</b>", ore.name, Format.number(state.Ores[ore.id] or 0))
		row.TextTransparency = unlocked and 0 or 0.55
	end

	renderFactory(eggValue)
	renderMine()
	renderPickaxes()
	renderLuck(luck)
	renderSkins()
end

Remotes:WaitForChild("DataUpdate").OnClientEvent:Connect(function(snapshot)
	state = snapshot
	render()
end)

selectTab("factory")
