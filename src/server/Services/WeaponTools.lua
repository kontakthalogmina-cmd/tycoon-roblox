-- Narzędzia walki w plecaku gracza: jajko do rzucania (zawsze) i wybrany brainrot karabin.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weapons = require(ReplicatedStorage.Shared.Config.Weapons)

local PlayerData = require(script.Parent.PlayerData)

local WeaponTools = {}

WeaponTools.EGG_TOOL = "Jajko"

local function welded(handle: BasePart, tool: Tool, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Massless = true
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = tool
	return p
end

-- Błysk z lufy: iskry + światło włączane na ułamek sekundy przy strzale (CombatService).
local function addMuzzleFlash(muzzle: Attachment, color: Color3)
	local flash = Instance.new("ParticleEmitter")
	flash.Name = "Flash"
	flash.Rate = 0
	flash.Lifetime = NumberRange.new(0.05, 0.1)
	flash.Speed = NumberRange.new(4, 8)
	flash.SpreadAngle = Vector2.new(25, 25)
	flash.Size = NumberSequence.new(0.5, 0)
	flash.LightEmission = 1
	flash.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), color)
	flash.EmissionDirection = Enum.NormalId.Right
	flash.Parent = muzzle
	local light = Instance.new("PointLight")
	light.Name = "FlashLight"
	light.Color = color
	light.Range = 10
	light.Brightness = 3
	light.Enabled = false
	light.Parent = muzzle
end

-- Brainrot Karabin Maszynowy: różowy korpus, bęben z amunicją, chłodzona lufa,
-- płetwa rekina (Tralalero) na górze i napis BRAINROT na boku.
local function buildBrainrotSMG(rifle)
	local tool = Instance.new("Tool")
	tool.Name = rifle.name
	tool.ToolTip = rifle.name .. " (strzela brainrotami!)"
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", rifle.id)
	tool.Grip = CFrame.new(0, -0.4, 0.6)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 1.1, 0.6)
	handle.Color = Color3.fromRGB(35, 30, 40)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.CFrame = CFrame.new(0, 100, 0)
	handle.Parent = tool

	local pink = rifle.color
	local dark = Color3.fromRGB(35, 32, 40)
	local body = welded(handle, tool, Vector3.new(0.75, 0.95, 3), CFrame.new(0, 0.65, -0.7), pink, Enum.Material.SmoothPlastic)
	welded(handle, tool, Vector3.new(0.77, 0.14, 3.02), CFrame.new(0, 1.12, -0.7), Color3.fromRGB(255, 215, 60), Enum.Material.Neon)
	for _, x in { -0.39, 0.39 } do
		welded(handle, tool, Vector3.new(0.04, 0.12, 2.4), CFrame.new(x, 0.55, -0.8), Color3.fromRGB(90, 230, 255), Enum.Material.Neon)
	end
	-- Bęben z amunicją pod spodem
	local drum = welded(handle, tool, Vector3.new(0.65, 1.4, 1.4), CFrame.new(0, -0.05, -1.25), Color3.fromRGB(255, 200, 40), Enum.Material.Foil)
	drum.Shape = Enum.PartType.Cylinder
	welded(handle, tool, Vector3.new(0.7, 0.5, 0.5), CFrame.new(0, -0.05, -1.25), dark, Enum.Material.Metal).Shape = Enum.PartType.Cylinder
	-- Kolba
	welded(handle, tool, Vector3.new(0.45, 0.75, 1.3), CFrame.new(0, 0.55, 1.35), dark, Enum.Material.SmoothPlastic)
	welded(handle, tool, Vector3.new(0.5, 0.95, 0.25), CFrame.new(0, 0.5, 2.05), pink, Enum.Material.SmoothPlastic)
	-- Osłona lufy z otworami i sama lufa
	local shroud = welded(handle, tool, Vector3.new(1.7, 0.6, 0.6), CFrame.new(0, 0.75, -3) * CFrame.Angles(0, math.pi / 2, 0), dark, Enum.Material.DiamondPlate)
	shroud.Shape = Enum.PartType.Cylinder
	for i = 0, 2 do
		welded(handle, tool, Vector3.new(0.62, 0.62, 0.12), CFrame.new(0, 0.75, -2.45 - i * 0.5), Color3.fromRGB(255, 90, 160), Enum.Material.Neon)
	end
	local barrel = welded(handle, tool, Vector3.new(0.7, 0.32, 0.32), CFrame.new(0, 0.75, -4.1) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Name = "Barrel"
	-- Celownik
	welded(handle, tool, Vector3.new(0.3, 0.35, 0.6), CFrame.new(0, 1.35, -0.4), dark, Enum.Material.Metal)
	welded(handle, tool, Vector3.new(0.18, 0.18, 0.05), CFrame.new(0, 1.38, -0.72), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	-- Płetwa rekina Tralalero
	local fin = Instance.new("WedgePart")
	fin.Size = Vector3.new(0.14, 0.75, 1)
	fin.Color = Color3.fromRGB(80, 160, 255)
	fin.Material = Enum.Material.SmoothPlastic
	fin.CanCollide = false
	fin.Massless = true
	fin.CFrame = handle.CFrame * CFrame.new(0, 1.55, 0.6)
	local finWeld = Instance.new("WeldConstraint")
	finWeld.Part0 = handle
	finWeld.Part1 = fin
	finWeld.Parent = fin
	fin.Parent = tool
	-- Napis na boku korpusu
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Text = "BRAINROT"
		label.Parent = gui
		gui.Parent = body
	end

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0.4, 0, 0) -- lufa leży wzdłuż swojej osi X, która patrzy do przodu
	muzzle.Parent = barrel
	addMuzzleFlash(muzzle, pink)

	local equip = Instance.new("Sound")
	equip.Name = "EquipSound"
	equip.SoundId = "rbxasset://sounds/unsheath.wav"
	equip.Volume = 0.5
	equip.Parent = handle
	tool.Equipped:Connect(function()
		equip:Play()
	end)
	return tool
end

local function buildEggTool()
	local tool = Instance.new("Tool")
	tool.Name = WeaponTools.EGG_TOOL
	tool.ToolTip = "Rzuć jajkiem (bez limitu)"
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1.3, 1)
	handle.Color = Color3.fromRGB(250, 245, 230)
	handle.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = handle
	handle.Parent = tool
	return tool
end

-- Karabin z prostych części: kolba, korpus, lufa i świecące paski w kolorze broni.
local function buildRifle(rifle)
	local tool = Instance.new("Tool")
	tool.Name = rifle.name
	tool.ToolTip = string.format("%s (obrażenia %d)", rifle.name, rifle.damage)
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", rifle.id)
	tool.Grip = CFrame.new(0, -0.4, 0.6)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 1.1, 0.6)
	handle.Color = Color3.fromRGB(40, 40, 45)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.CFrame = CFrame.new(0, 100, 0)
	handle.Parent = tool

	welded(handle, tool, Vector3.new(0.6, 0.7, 2.6), CFrame.new(0, 0.6, -0.6), rifle.color, Enum.Material.SmoothPlastic)
	welded(handle, tool, Vector3.new(0.5, 0.8, 1.2), CFrame.new(0, 0.4, 1.2), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
	local barrel = welded(handle, tool, Vector3.new(0.25, 0.25, 2), CFrame.new(0, 0.75, -2.8), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	barrel.Name = "Barrel"
	welded(handle, tool, Vector3.new(0.62, 0.15, 2.2), CFrame.new(0, 0.98, -0.6), rifle.color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Neon)
	welded(handle, tool, Vector3.new(0.3, 0.4, 0.8), CFrame.new(0, 1.1, -0.4), Color3.fromRGB(20, 20, 25), Enum.Material.Glass)
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0, -1.05)
	muzzle.Parent = barrel
	return tool
end

local function removeExisting(player: Player)
	for _, container in { player:FindFirstChild("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and (child.Name == WeaponTools.EGG_TOOL or child:GetAttribute("WeaponId")) then
					child:Destroy()
				end
			end
		end
	end
end

-- Daje jajko do rzucania i aktualnie wybrany karabin.
function WeaponTools.Give(player: Player)
	local data = PlayerData.Get(player)
	local backpack = player:FindFirstChild("Backpack")
	if not data or not backpack then
		return
	end
	removeExisting(player)
	buildEggTool().Parent = backpack
	local rifle = Weapons.byId[data.EquippedWeapon]
	if rifle and data.OwnedWeapons[rifle.id] then
		local build = rifle.brainrot and buildBrainrotSMG or buildRifle
		build(rifle).Parent = backpack
	end
end

function WeaponTools.Setup(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait(0.3)
		WeaponTools.Give(player)
	end)
	if player.Character then
		WeaponTools.Give(player)
	end
end

return WeaponTools
