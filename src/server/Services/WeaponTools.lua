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
		buildRifle(rifle).Parent = backpack
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
