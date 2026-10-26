-- Widoczny kilof w ręce gracza (Tool). Wygląd głowicy zależy od założonego kilofa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pickaxes = require(ReplicatedStorage.Shared.Config.Pickaxes)

local PlayerData = require(script.Parent.PlayerData)

local PickaxeTool = {}

local TOOL_NAME = "Kilof"
local HANDLE_LENGTH = 4.2

local function weldedPart(handle: BasePart, parent: Instance, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, className: string?)
	local p = Instance.new(className or "Part")
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
	p.Parent = parent
	return p
end

local function build(pickaxe)
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = pickaxe.name
	tool.CanBeDropped = false
	tool:SetAttribute("PickaxeId", pickaxe.id)
	-- Ręka trzyma trzonek przy dolnym końcu (oś Z), głowica jest na +Z i wskazuje w górę
	-- względem przedramienia, jak młotek.
	tool.Grip = CFrame.new(0, 0, -HANDLE_LENGTH / 2 + 0.6) * CFrame.Angles(math.rad(90), 0, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.35, HANDLE_LENGTH)
	handle.Color = Color3.fromRGB(120, 80, 45)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CFrame = CFrame.new(0, 100, 0)
	handle.Parent = tool

	-- Owijka na uchwycie
	weldedPart(handle, tool, Vector3.new(0.42, 0.42, 1.1), CFrame.new(0, 0, -HANDLE_LENGTH / 2 + 0.6), Color3.fromRGB(60, 40, 30), Enum.Material.Fabric)

	-- Głowica: środek i dwa zakrzywione ramiona zakończone szpicem.
	local headZ = HANDLE_LENGTH / 2 - 0.25
	weldedPart(handle, tool, Vector3.new(0.6, 0.7, 0.7), CFrame.new(0, 0, headZ), pickaxe.color, pickaxe.material)
	for _, side in { 1, -1 } do
		local arm = CFrame.new(0, side * 0.95, headZ - 0.12) * CFrame.Angles(side * math.rad(12), 0, 0)
		weldedPart(handle, tool, Vector3.new(0.45, 1.3, 0.45), arm, pickaxe.color, pickaxe.material)
		local tipRotation = side == 1 and CFrame.Angles(0, 0, 0) or CFrame.Angles(math.pi, 0, 0)
		weldedPart(
			handle,
			tool,
			Vector3.new(0.45, 0.7, 0.45),
			arm * CFrame.new(0, side * 0.95, 0) * tipRotation,
			pickaxe.color,
			pickaxe.material,
			"WedgePart"
		)
	end
	return tool
end

local function removeExisting(player: Player)
	for _, container in { player:FindFirstChild("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child.Name == TOOL_NAME then
					child:Destroy()
				end
			end
		end
	end
end

-- Daje graczowi kilof zgodny z danymi i od razu go zakłada.
function PickaxeTool.Give(player: Player)
	local data = PlayerData.Get(player)
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if not data or not character or not backpack then
		return
	end
	removeExisting(player)
	local pickaxe = Pickaxes.byId[data.EquippedPickaxe] or Pickaxes.list[1]
	local tool = build(pickaxe)
	tool.Parent = backpack
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

function PickaxeTool.Setup(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait(0.2)
		PickaxeTool.Give(player)
	end)
	if player.Character then
		PickaxeTool.Give(player)
	end
end

return PickaxeTool
