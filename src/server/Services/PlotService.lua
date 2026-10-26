-- Przydziela graczom działki. Każda działka leży daleko od innych,
-- więc gracz widzi tylko swój teren.
local PlotBuilder = require(script.Parent.PlotBuilder)
local Remotes = require(script.Parent.Remotes)

local PlotService = {}

local PLOT_COUNT = 8
local PLOT_DISTANCE = 2000 -- odstęp między działkami (poza zasięgiem wzroku)

local plots = {}
local byPlayer = {} -- [Player] = plot

function PlotService.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace

	-- Mały plac startowy; gracz jest od razu przenoszony na swoją działkę.
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	for i = 1, PLOT_COUNT do
		local origin = CFrame.new(i * PLOT_DISTANCE, 0, 0)
		local plot = PlotBuilder.Build(i, origin, folder)
		plots[i] = plot
		plot.shopPrompt.Triggered:Connect(function(player)
			if player == plot.owner then
				Remotes.OpenShop:FireClient(player)
			else
				Remotes.notify(player, "To nie Twój sklep. Twoja budka stoi na Twojej działce.")
			end
		end)
	end
end

local function teleport(player: Player, plot)
	local character = player.Character
	if character then
		task.defer(function()
			character:PivotTo(plot.spawnCFrame)
		end)
	end
end

function PlotService.Assign(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plot.signLabel.Text = "Działka: " .. player.DisplayName
			byPlayer[player] = plot
			plot.connection = player.CharacterAdded:Connect(function()
				teleport(player, plot)
			end)
			teleport(player, plot)
			return plot
		end
	end
	return nil
end

function PlotService.Get(player: Player)
	return byPlayer[player]
end

function PlotService.Release(player: Player)
	local plot = byPlayer[player]
	if plot then
		if plot.connection then
			plot.connection:Disconnect()
			plot.connection = nil
		end
		plot.owner = nil
		plot.signLabel.Text = "Wolna działka"
		plot.factoryLabel.Text = "Fabryka"
		plot.mineLabel.Text = "Kopalnia"
		byPlayer[player] = nil
	end
end

PlotService.MAX_SLOTS = PlotBuilder.MAX_SLOTS
PlotService.PLOT_COUNT = PLOT_COUNT
-- Maks. liczbę graczy na serwerze ustaw w Game Settings na <= PLOT_COUNT.

return PlotService
