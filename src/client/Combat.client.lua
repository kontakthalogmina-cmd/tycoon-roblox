-- Walka po stronie gracza: rzucanie jajkiem, strzelanie z karabinu (przytrzymaj, żeby strzelać seriami)
-- i przewracanie się po trafieniu jajkiem.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Weapons"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowEgg = Remotes:WaitForChild("ThrowEgg")
local FireWeapon = Remotes:WaitForChild("FireWeapon")

local player = Players.LocalPlayer
local EGG_TOOL = "Jajko"

local lastThrow = 0
local firing = false
local aimScreenPosition = Vector2.zero

local function heldTool()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
end

-- Punkt w świecie pod kursorem / palcem.
local function worldPoint(screenPosition: Vector2)
	local character = player.Character
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	return result and result.Position or ray.Origin + ray.Direction * 500
end

local function recoil(tool: Tool, angle: number, time: number)
	local base = tool:GetAttribute("BaseGrip") or tool.Grip
	tool:SetAttribute("BaseGrip", base)
	tool.Grip = base * CFrame.Angles(math.rad(angle), 0, 0)
	TweenService:Create(tool, TweenInfo.new(time), { Grip = base }):Play()
end

local function throw(tool: Tool, screenPosition: Vector2)
	local now = os.clock()
	if now - lastThrow < Weapons.throw.cooldown then
		return
	end
	lastThrow = now
	recoil(tool, -60, 0.25)
	ThrowEgg:FireServer(worldPoint(screenPosition))
end

local function startFiring(tool: Tool)
	local rifle = Weapons.byId[tool:GetAttribute("WeaponId")]
	if not rifle or firing then
		return
	end
	firing = true
	task.spawn(function()
		while firing and heldTool() == tool do
			recoil(tool, 6, rifle.fireRate * 0.8)
			FireWeapon:FireServer(worldPoint(aimScreenPosition))
			task.wait(rifle.fireRate)
		end
		firing = false
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local tool = heldTool()
	if not tool then
		return
	end
	aimScreenPosition = Vector2.new(input.Position.X, input.Position.Y)
	if tool.Name == EGG_TOOL then
		throw(tool, aimScreenPosition)
	elseif tool:GetAttribute("WeaponId") then
		startFiring(tool)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		aimScreenPosition = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		firing = false
	end
end)

-- Trafienie jajkiem: postać się przewraca i odlatuje, po chwili wstaje.
local knockToken = 0
Remotes:WaitForChild("Knockback").OnClientEvent:Connect(function(velocity: Vector3, duration: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end
	knockToken += 1
	local token = knockToken
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	root.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-4, 4), math.random(-8, 8))
	task.delay(duration, function()
		if token == knockToken and humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end)
