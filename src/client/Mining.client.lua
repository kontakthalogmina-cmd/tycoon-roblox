-- Kopanie kilofem: animacja zamachu ręką, odłamki skały i wysłanie uderzenia do serwera.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Pickaxes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Pickaxes"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MineHit = Remotes:WaitForChild("MineHit")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local HIT_DISTANCE = 15
local equippedPickaxe = Pickaxes.list[1]
local swinging = false
local lastSwing = 0
local originalC0 = {} -- [Motor6D] = CFrame
local boundTools = setmetatable({}, { __mode = "k" })

Remotes:WaitForChild("DataUpdate").OnClientEvent:Connect(function(snapshot)
	equippedPickaxe = Pickaxes.byId[snapshot.EquippedPickaxe] or Pickaxes.list[1]
end)

-- Staw barku prawej ręki i oś, wokół której podnosi się rękę (R15 albo R6).
local function getShoulder(character: Model)
	local upperArm = character:FindFirstChild("RightUpperArm")
	local r15 = upperArm and upperArm:FindFirstChild("RightShoulder")
	if r15 then
		return r15, function(angle)
			return CFrame.Angles(angle, 0, 0)
		end
	end
	local torso = character:FindFirstChild("Torso")
	local r6 = torso and torso:FindFirstChild("Right Shoulder")
	if r6 then
		return r6, function(angle)
			return CFrame.Angles(0, 0, angle)
		end
	end
	return nil
end

local function findOreNode(target: Instance?)
	local node = target
	while node and node ~= workspace do
		if node:IsA("Model") and node:GetAttribute("OreId") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function hitEffect(node: Model)
	local rock = node.PrimaryPart
	local debris = rock and rock:FindFirstChild("Debris")
	if debris then
		debris:Emit(10)
	end
end

local function tryHit()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local node = findOreNode(mouse.Target)
	if not root or not node then
		return
	end
	if (root.Position - node:GetPivot().Position).Magnitude > HIT_DISTANCE then
		return
	end
	hitEffect(node)
	MineHit:FireServer(node)
end

local function swing()
	local now = os.clock()
	if swinging or now - lastSwing < equippedPickaxe.cooldown then
		return
	end
	swinging = true
	lastSwing = now

	local character = player.Character
	local shoulder, rotate = nil, nil
	if character then
		shoulder, rotate = getShoulder(character)
	end
	if not shoulder then
		tryHit()
		swinging = false
		return
	end
	originalC0[shoulder] = originalC0[shoulder] or shoulder.C0
	local base = originalC0[shoulder]
	local total = math.max(equippedPickaxe.cooldown, 0.25)

	-- Zamach w górę, uderzenie w dół, powrót.
	local up = TweenService:Create(shoulder, TweenInfo.new(total * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		C0 = base * rotate(math.rad(70)),
	})
	local down = TweenService:Create(shoulder, TweenInfo.new(total * 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		C0 = base * rotate(math.rad(-45)),
	})
	local back = TweenService:Create(shoulder, TweenInfo.new(total * 0.4, Enum.EasingStyle.Sine), { C0 = base })

	up:Play()
	up.Completed:Wait()
	down:Play()
	down.Completed:Wait()
	tryHit()
	back:Play()
	back.Completed:Wait()
	swinging = false
end

local function bindTool(tool: Instance)
	if tool:IsA("Tool") and tool.Name == "Kilof" and not boundTools[tool] then
		boundTools[tool] = true
		tool.Activated:Connect(function()
			task.spawn(swing)
		end)
	end
end

local function onCharacter(character: Model)
	originalC0 = {}
	swinging = false
	for _, child in character:GetChildren() do
		bindTool(child)
	end
	character.ChildAdded:Connect(bindTool)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end
