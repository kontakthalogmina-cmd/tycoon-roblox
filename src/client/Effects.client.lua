-- Efekty liczone po stronie gracza: tęczowe i pulsujące jajka oraz własne niewidzialne pułapki.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RAINBOW_SPEED = 0.5 -- pełne okrążenie barw na 2 sekundy

local pulseBase = {} -- [BasePart] = Color3
local OWNER_TRANSPARENCY = 0.6 -- jak widać własne pułapki (obcy ich nie widzą)
local userId = Players.LocalPlayer.UserId

local function ownerId(inst: Instance)
	local model = inst:FindFirstAncestorWhichIsA("Model")
	return model and model:GetAttribute("OwnerId")
end

local function setColor(inst: Instance, color: Color3)
	if inst:IsA("BasePart") then
		inst.Color = color
	elseif inst:IsA("TextLabel") then
		inst.TextColor3 = color
	elseif inst:IsA("PointLight") then
		inst.Color = color
	end
end

CollectionService:GetInstanceRemovedSignal("Pulse"):Connect(function(inst)
	pulseBase[inst] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i, inst in CollectionService:GetTagged("Rainbow") do
		-- Każdy obiekt lekko przesunięty w fazie, żeby nie mieniły się identycznie.
		local hue = (t * RAINBOW_SPEED + i * 0.07) % 1
		setColor(inst, Color3.fromHSV(hue, 0.85, 1))
	end
	local pulse = (math.sin(t * 6) + 1) / 2
	for _, inst in CollectionService:GetTagged("Pulse") do
		if inst:IsA("BasePart") then
			pulseBase[inst] = pulseBase[inst] or inst.Color
			inst.Color = pulseBase[inst]:Lerp(Color3.fromRGB(30, 0, 10), pulse * 0.7)
		end
	end
	-- Serwer trzyma pułapki niewidzialne (1); właściciel widzi je półprzezroczyste.
	-- Gdy pułapka się ujawnia (0), zostawiamy ją w pełni widoczną.
	for _, inst in CollectionService:GetTagged("OwnerVisible") do
		if inst:IsA("BasePart") and inst.Transparency == 1 and ownerId(inst) == userId then
			inst.LocalTransparencyModifier = 0
			inst.Transparency = OWNER_TRANSPARENCY
		end
	end
end)
