-- Kopanie kilofem: kliknięcie/dotknięcie z kilofem w ręce celuje w skałę z rudą,
-- od razu wysyła uderzenie do serwera i odgrywa zamach ręką.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Pickaxes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Pickaxes"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MineHit = Remotes:WaitForChild("MineHit")

local player = Players.LocalPlayer

local HIT_DISTANCE = 14 -- serwer akceptuje trochę więcej
local AUTO_TARGET_DISTANCE = 9 -- gdy kursor nie wskazuje skały, bierzemy najbliższą
local TOOL_NAME = "Kilof"

local equippedPickaxe = Pickaxes.list[1]
local lastSwing = 0
local originalC0 = {} -- [Motor6D] = CFrame
local lastHint = 0

Remotes:WaitForChild("DataUpdate").OnClientEvent:Connect(function(snapshot)
	equippedPickaxe = Pickaxes.byId[snapshot.EquippedPickaxe] or Pickaxes.list[1]
end)

-- Lokalny komunikat (wyświetla go Main.client), najwyżej raz na 2 s.
local function showHint(text: string)
	if os.clock() - lastHint < 2 then
		return
	end
	lastHint = os.clock()
	local localNotify = ReplicatedStorage:FindFirstChild("LocalNotify")
	if localNotify then
		localNotify:Fire(text)
	end
end

local function getPickaxeTool(character: Model?)
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool.Name == TOOL_NAME then
		return tool
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

local function nearestNode(position: Vector3)
	local best, bestDist = nil, AUTO_TARGET_DISTANCE
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		local ores = plot:FindFirstChild("Ores")
		if ores then
			for _, node in ores:GetChildren() do
				local dist = (node:GetPivot().Position - position).Magnitude
				if dist < bestDist then
					best, bestDist = node, dist
				end
			end
		end
	end
	return best
end

local function aimAt(screenPosition: Vector2, character: Model)
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	return result and findOreNode(result.Instance)
end

-- Staw barku prawej ręki i funkcja obrotu podnoszącego rękę (R15 albo R6).
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
	return nil, nil
end

-- Zamach w górę, uderzenie w dół i powrót dla jednej właściwości CFrame (C0 barku albo Grip kilofa).
local function swingProperty(target: Instance, property: string, base: CFrame, upRotation: CFrame, downRotation: CFrame, duration: number)
	local up = TweenService:Create(target, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		[property] = base * upRotation,
	})
	local down = TweenService:Create(target, TweenInfo.new(duration * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		[property] = base * downRotation,
	})
	local back = TweenService:Create(target, TweenInfo.new(duration * 0.4, Enum.EasingStyle.Sine), { [property] = base })
	up:Play()
	up.Completed:Wait()
	down:Play()
	down.Completed:Wait()
	back:Play()
end

local originalGrip = setmetatable({}, { __mode = "k" }) -- [Tool] = CFrame

local function playSwing(character: Model, duration: number)
	-- Kilof w dłoni obraca się zawsze, to działa przy każdym typie postaci.
	local tool = getPickaxeTool(character)
	if tool then
		originalGrip[tool] = originalGrip[tool] or tool.Grip
		task.spawn(swingProperty, tool, "Grip", originalGrip[tool], CFrame.Angles(math.rad(-55), 0, 0), CFrame.Angles(math.rad(45), 0, 0), duration)
	end
	-- Ręka: tylko gdy bark jest klasycznym Motor6D (nowe stawy Roblox nie mają C0).
	local shoulder, rotate = getShoulder(character)
	if shoulder and shoulder:IsA("Motor6D") then
		originalC0[shoulder] = originalC0[shoulder] or shoulder.C0
		swingProperty(shoulder, "C0", originalC0[shoulder], rotate(math.rad(70)), rotate(math.rad(-40)), duration)
	end
end

local function hitEffect(node: Model)
	local rock = node.PrimaryPart
	local debris = rock and rock:FindFirstChild("Debris")
	if debris then
		debris:Emit(12)
	end
	-- Krótkie drgnięcie skały (tylko u nas, serwer jej nie przesuwa).
	if rock then
		local base = rock.CFrame
		rock.CFrame = base * CFrame.new(math.random() * 0.3 - 0.15, 0, math.random() * 0.3 - 0.15)
		task.delay(0.06, function()
			if rock.Parent then
				rock.CFrame = base
			end
		end)
	end
end

local function trySwing(screenPosition: Vector2)
	local character = player.Character
	if not character then
		return
	end
	if not getPickaxeTool(character) then
		-- Kilof schowany w plecaku: wyjmujemy go automatycznie.
		local backpack = player:FindFirstChild("Backpack")
		local tool = backpack and backpack:FindFirstChild(TOOL_NAME)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if tool and humanoid then
			humanoid:EquipTool(tool)
		end
	end
	local now = os.clock()
	if now - lastSwing < equippedPickaxe.cooldown then
		return
	end
	lastSwing = now

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local node = aimAt(screenPosition, character)
	if node and (root.Position - node:GetPivot().Position).Magnitude > HIT_DISTANCE then
		showHint("Podejdź bliżej do skały!")
		node = nil
	end
	node = node or nearestNode(root.Position)

	task.spawn(function()
		local ok, err = pcall(playSwing, character, math.max(equippedPickaxe.cooldown, 0.3))
		if not ok then
			warn("[Mining] animacja zamachu:", err)
		end
	end)
	if node then
		-- Uderzenie liczy się od razu, animacja jest tylko dla oka.
		task.delay(0.12, function()
			if node.Parent then
				hitEffect(node)
				MineHit:FireServer(node)
			end
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		trySwing(Vector2.new(input.Position.X, input.Position.Y))
	end
end)

player.CharacterAdded:Connect(function()
	originalC0 = {}
end)
