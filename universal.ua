--[[
	UNICLUDE MOBILE QA TOOLKIT
	Arquivo Ãºnico para colar DENTRO de um LocalScript.

	Onde colocar:
	1. Roblox Studio > StarterPlayer > StarterPlayerScripts
	2. Insert Object > LocalScript
	3. Apague o conteÃºdo padrÃ£o e cole este arquivo

	TambÃ©m funciona em StarterGui. NÃ£o use Script normal.
	Ferramentas de movimento sÃ£o apenas QA do seu jogo: Studio ou UserId autorizado.
	NÃ£o usa loadstring, executor, hook, RemoteSpy ou bypass.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
if not player then
	warn("[UNICLUDE QA] LocalPlayer nÃ£o encontrado. Este arquivo precisa ser um LocalScript.")
	return
end

-- Adicione UserIds da sua equipe de QA aqui.
local AUTHORIZED_USER_IDS = {
	-- [123456789] = true,
}

local authorized = RunService:IsStudio() or AUTHORIZED_USER_IDS[player.UserId] == true
if not authorized then
	warn("[UNICLUDE QA] desativado para este jogador")
	return
end

local COLORS = {
	bg = Color3.fromRGB(18, 20, 18),
	panel = Color3.fromRGB(27, 30, 26),
	panel2 = Color3.fromRGB(37, 41, 34),
	stroke = Color3.fromRGB(72, 80, 63),
	text = Color3.fromRGB(235, 239, 225),
	muted = Color3.fromRGB(160, 168, 146),
	accent = Color3.fromRGB(197, 232, 93),
	warn = Color3.fromRGB(240, 190, 90),
	danger = Color3.fromRGB(236, 112, 96),
	info = Color3.fromRGB(117, 190, 220),
}

local State = {
	ESP = false,
	Names = true,
	Distance = true,
	Highlight = false,
	Fullbright = false,
	XRay = false,
	Speed = false,
	Jump = false,
	Noclip = false,
	Fly = false,
	ClickTP = false,
	Waypoint = false,
	Freecam = false,
	FOV = false,
	Performance = false,
	Collision = false,
	SpeedValue = 24,
	JumpValue = 60,
	FOVValue = 80,
}

local gui
local shell
local espData = {}
local connections = {}
local originalLighting = {}
local originalTransparency = {}
local noclipConnection
local flyVelocity
local freecamConnection
local performanceConnection
local waypoint
local regionMarker
local panelVisible = true
local destroyed = false

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function character()
	return player.Character
end

local function root()
	local model = character()
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
	local model = character()
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "UNICLUDE QA",
			Text = text,
			Duration = 2,
		})
	end)
end

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = object
	return corner
end

local function addStroke(object, color)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.stroke
	stroke.Transparency = 0.45
	stroke.Parent = object
	return stroke
end

-- UI -------------------------------------------------------------------------
local function createGui()
	local existing = player:WaitForChild("PlayerGui"):FindFirstChild("UNICLUDE_MobileQA")
	if existing then existing:Destroy() end

	gui = Instance.new("ScreenGui")
	gui.Name = "UNICLUDE_MobileQA"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Parent = player.PlayerGui

	shell = Instance.new("Frame")
	shell.Name = "Panel"
	shell.Size = UDim2.fromOffset(292, 470)
	shell.Position = UDim2.fromOffset(14, 84)
	shell.BackgroundColor3 = COLORS.bg
	shell.BorderSizePixel = 0
	shell.ClipsDescendants = true
	shell.Parent = gui
	addCorner(shell, 10)
	addStroke(shell, COLORS.stroke)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundColor3 = COLORS.panel
	header.BorderSizePixel = 0
	header.Parent = shell

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(14, 0)
	title.Size = UDim2.new(1, -28, 1, 0)
	title.Font = Enum.Font.GothamBold
	title.Text = "UNICLUDE  /  MOBILE QA"
	title.TextColor3 = COLORS.text
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Tools"
	scroll.Position = UDim2.fromOffset(8, 52)
	scroll.Size = UDim2.new(1, -16, 1, -60)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = COLORS.stroke
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = shell

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	local function label(text)
		local object = Instance.new("TextLabel")
		object.BackgroundTransparency = 1
		object.Size = UDim2.new(1, 0, 0, 21)
		object.Font = Enum.Font.GothamBold
		object.Text = string.upper(text)
		object.TextColor3 = COLORS.muted
		object.TextSize = 10
		object.TextXAlignment = Enum.TextXAlignment.Left
		object.Parent = scroll
		return object
	end

	local buttons = {}
	local function button(key, text, callback)
		local object = Instance.new("TextButton")
		object.Name = key
		object.Size = UDim2.new(1, 0, 0, 38)
		object.BackgroundColor3 = COLORS.panel
		object.BorderSizePixel = 0
		object.AutoButtonColor = false
		object.Font = Enum.Font.GothamMedium
		object.TextSize = 11
		object.TextXAlignment = Enum.TextXAlignment.Left
		object.Parent = scroll
		addCorner(object, 6)
		addStroke(object)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 12)
		pad.Parent = object

		local function refresh()
			local enabled = State[key] == true
			object.Text = (enabled and "â—  " or "â—‹  ") .. text
			object.TextColor3 = enabled and COLORS.accent or COLORS.muted
			object.BackgroundColor3 = enabled and Color3.fromRGB(42, 50, 33) or COLORS.panel
		end

		object.Activated:Connect(function()
			callback()
			refresh()
		end)
		buttons[key] = refresh
		refresh()
		return object
	end

	local function slider(key, text, minValue, maxValue, callback)
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, 0, 0, 52)
		holder.BackgroundColor3 = COLORS.panel
		holder.BorderSizePixel = 0
		holder.Parent = scroll
		addCorner(holder, 6)

		local valueLabel = Instance.new("TextLabel")
		valueLabel.BackgroundTransparency = 1
		valueLabel.Position = UDim2.fromOffset(12, 4)
		valueLabel.Size = UDim2.new(1, -24, 0, 18)
		valueLabel.Font = Enum.Font.GothamMedium
		valueLabel.TextColor3 = COLORS.text
		valueLabel.TextSize = 11
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = holder

		local bar = Instance.new("Frame")
		bar.Position = UDim2.fromOffset(12, 31)
		bar.Size = UDim2.new(1, -24, 0, 6)
		bar.BackgroundColor3 = COLORS.panel2
		bar.BorderSizePixel = 0
		bar.Parent = holder
		addCorner(bar, 20)

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = COLORS.accent
		fill.BorderSizePixel = 0
		fill.Parent = bar
		addCorner(fill, 20)

		local dragging = false
		local function update(x)
			local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local value = math.round(minValue + (maxValue - minValue) * alpha)
			State[key] = value
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			valueLabel.Text = text .. ": " .. tostring(value)
			callback(value)
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				update(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
				update(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		local alpha = (State[key] - minValue) / (maxValue - minValue)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLabel.Text = text .. ": " .. tostring(State[key])
	end

	label("visualizaÃ§Ã£o")
	button("ESP", "Player ESP", function() State.ESP = not State.ESP end)
	button("Names", "Nomes", function() State.Names = not State.Names end)
	button("Distance", "DistÃ¢ncia", function() State.Distance = not State.Distance end)
	button("Highlight", "Highlight", function() State.Highlight = not State.Highlight end)

	label("movimento de QA")
	slider("SpeedValue", "Velocidade", 16, 60, function() if State.Speed then applyMovement() end end)
	slider("JumpValue", "Pulo", 50, 120, function() if State.Jump then applyMovement() end end)
	button("Speed", "Speed QA", function() State.Speed = not State.Speed; applyMovement() end)
	button("Jump", "Jump QA", function() State.Jump = not State.Jump; applyMovement() end)
	button("Noclip", "Noclip QA", function() setNoclip(not State.Noclip) end)
	button("Fly", "Fly QA", function() setFly(not State.Fly) end)
	button("ClickTP", "Click Teleport QA", function() State.ClickTP = not State.ClickTP end)
	button("Freecam", "Freecam QA", function() setFreecam(not State.Freecam) end)

	label("mundo e cÃ¢mera")
	button("Fullbright", "Fullbright QA", function() setFullbright(not State.Fullbright) end)
	button("XRay", "X-Ray visual", function() setXRay(not State.XRay) end)
	button("Waypoint", "Waypoint", function() setWaypoint(not State.Waypoint) end)
	button("Collision", "Visualizador de colisÃ£o", function() setCollision(not State.Collision) end)
	slider("FOVValue", "FOV", 50, 110, function() if State.FOV then setFOV(true) end end)
	button("FOV", "FOV QA", function() setFOV(not State.FOV) end)
	button("Performance", "Performance HUD", function() setPerformance(not State.Performance) end)

	label("reset")
	button("Reset", "Resetar ferramentas", function() resetTools() end)

	return header
end

-- ESP ------------------------------------------------------------------------
local function removeESP(playerToRemove)
	local data = espData[playerToRemove]
	if not data then return end
	if data.billboard then data.billboard:Destroy() end
	if data.highlight then data.highlight:Destroy() end
	if data.characterConnection then data.characterConnection:Disconnect() end
	espData[playerToRemove] = nil
end

local function addESP(otherPlayer)
	if otherPlayer == player or espData[otherPlayer] then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QA_PlayerLabel"
	billboard.Size = UDim2.fromOffset(160, 40)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = gui

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0.5, 0)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 11
	name.TextStrokeTransparency = 0.5
	name.Parent = billboard

	local distance = Instance.new("TextLabel")
	distance.BackgroundTransparency = 1
	distance.Position = UDim2.fromScale(0, 0.5)
	distance.Size = UDim2.fromScale(1, 0.5)
	distance.Font = Enum.Font.Gotham
	distance.TextColor3 = COLORS.text
	distance.TextSize = 10
	distance.TextStrokeTransparency = 0.5
	distance.Parent = billboard

	local highlight = Instance.new("Highlight")
	highlight.Name = "QA_PlayerHighlight"
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.15
	highlight.Enabled = false
	highlight.Parent = gui

	local data = { billboard = billboard, name = name, distance = distance, highlight = highlight }
	data.characterConnection = otherPlayer.CharacterAdded:Connect(function(model)
		billboard.Adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
		highlight.Adornee = model
	end)
	if otherPlayer.Character then
		billboard.Adornee = otherPlayer.Character:FindFirstChild("Head") or otherPlayer.Character:FindFirstChild("HumanoidRootPart")
		highlight.Adornee = otherPlayer.Character
	end
	espData[otherPlayer] = data
end

local function updateESP()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then addESP(otherPlayer) end
	end
	local localRoot = root()
	for otherPlayer, data in pairs(espData) do
		local otherRoot = otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
		local enabled = State.ESP and otherRoot ~= nil
		data.billboard.Enabled = enabled
		data.highlight.Enabled = enabled and State.Highlight
		if enabled then
			local color = otherPlayer.TeamColor.Color
			data.name.Visible = State.Names
			data.name.Text = State.Names and otherPlayer.DisplayName or ""
			data.name.TextColor3 = color
			data.highlight.FillColor = color
			data.highlight.OutlineColor = color
			data.distance.Visible = State.Distance
			data.distance.Text = State.Distance and (math.floor((otherRoot.Position - localRoot.Position).Magnitude) .. " studs") or ""
		end
	end
end

-- MOVIMENTO ------------------------------------------------------------------
function applyMovement()
	local currentHumanoid = humanoid()
	if not currentHumanoid then return end
	currentHumanoid.WalkSpeed = State.Speed and State.SpeedValue or 16
	currentHumanoid.UseJumpPower = true
	currentHumanoid.JumpPower = State.Jump and State.JumpValue or 50
end

function setNoclip(enabled)
	State.Noclip = enabled
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	if enabled then
		noclipConnection = RunService.Stepped:Connect(function()
			local model = character()
			if not model then return end
			for _, object in ipairs(model:GetDescendants()) do
				if object:IsA("BasePart") then object.CanCollide = false end
			end
		end)
		notify("Noclip QA ligado")
	end
end

function setFly(enabled)
	State.Fly = enabled
	if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
	if enabled then
		local currentRoot = root()
		if not currentRoot then State.Fly = false; return end
		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		flyVelocity.Velocity = Vector3.zero
		flyVelocity.Parent = currentRoot
		notify("Fly QA ligado")
	end
end

local function updateFly()
	if not State.Fly or not flyVelocity then return end
	local currentHumanoid = humanoid()
	local camera = workspace.CurrentCamera
	if currentHumanoid and camera then
		local move = currentHumanoid.MoveDirection
		flyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z)) * 42
	end
end

function setFreecam(enabled)
	State.Freecam = enabled
	if freecamConnection then freecamConnection:Disconnect(); freecamConnection = nil end
	local camera = workspace.CurrentCamera
	if not enabled then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid()
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local position = camera.CFrame.Position
	freecamConnection = RunService.RenderStepped:Connect(function(deltaTime)
		local movement = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement += camera.CFrame.RightVector end
		position += movement * deltaTime * 35
		camera.CFrame = CFrame.new(position, position + camera.CFrame.LookVector)
	end)
end

-- WORLD ----------------------------------------------------------------------
function setFullbright(enabled)
	State.Fullbright = enabled
	if enabled then
		originalLighting.Brightness = Lighting.Brightness
		originalLighting.ClockTime = Lighting.ClockTime
		originalLighting.FogEnd = Lighting.FogEnd
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
	else
		for property, value in pairs(originalLighting) do Lighting[property] = value end
		table.clear(originalLighting)
	end
end

function setXRay(enabled)
	State.XRay = enabled
	if enabled then
		for _, object in ipairs(workspace:GetDescendants()) do
			if object:IsA("BasePart") and not object:IsDescendantOf(character() or workspace) then
				originalTransparency[object] = object.LocalTransparencyModifier
				object.LocalTransparencyModifier = math.max(object.LocalTransparencyModifier, 0.55)
			end
		end
	else
		for object, value in pairs(originalTransparency) do
			if object.Parent then object.LocalTransparencyModifier = value end
		end
		table.clear(originalTransparency)
	end
end

function setWaypoint(enabled)
	State.Waypoint = enabled
	if waypoint then waypoint:Destroy(); waypoint = nil end
	if enabled and root() then
		waypoint = Instance.new("Part")
		waypoint.Name = "QA_Waypoint"
		waypoint.Anchored = true
		waypoint.CanCollide = false
		waypoint.Size = Vector3.new(2, 0.2, 2)
		waypoint.Color = COLORS.accent
		waypoint.Material = Enum.Material.Neon
		waypoint.CFrame = root().CFrame * CFrame.new(0, -3, -8)
		waypoint.Parent = workspace
	end
end

function setCollision(enabled)
	State.Collision = enabled
	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") then
			if enabled then
				if object:GetAttribute("QA_OriginalColor") == nil then object:SetAttribute("QA_OriginalColor", object.Color) end
				object.Color = object.CanCollide and Color3.fromRGB(105, 205, 120) or Color3.fromRGB(230, 105, 95)
			else
				local original = object:GetAttribute("QA_OriginalColor")
				if typeof(original) == "Color3" then object.Color = original end
				object:SetAttribute("QA_OriginalColor", nil)
			end
		end
	end
end

function setFOV(enabled)
	State.FOV = enabled
	local camera = workspace.CurrentCamera
	if camera then camera.FieldOfView = enabled and State.FOVValue or 70 end
end

local performanceLabel
function setPerformance(enabled)
	State.Performance = enabled
	if performanceLabel then performanceLabel.Visible = enabled end
	if performanceConnection then performanceConnection:Disconnect(); performanceConnection = nil end
	if not enabled then return end

	local elapsed = 0
	local frames = 0
	performanceConnection = RunService.RenderStepped:Connect(function(deltaTime)
		elapsed += deltaTime
		frames += 1
		if elapsed >= 0.5 and performanceLabel then
			performanceLabel.Text = string.format("  %d FPS  Â·  %.1f ms", math.floor(frames / elapsed), deltaTime * 1000)
			elapsed = 0
			frames = 0
		end
	end)
end

function resetTools()
	State.Speed = false
	State.Jump = false
	setNoclip(false)
	setFly(false)
	setFreecam(false)
	setFullbright(false)
	setXRay(false)
	setWaypoint(false)
	setCollision(false)
	setFOV(false)
	setPerformance(false)
	State.ESP = false
	State.Highlight = false
	applyMovement()
	notify("Ferramentas resetadas")
end

-- TELEPORT POR TOQUE ---------------------------------------------------------
connect(UserInputService.InputBegan, function(input, processed)
	if processed or not State.ClickTP then return end
	if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character() }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if hit and root() then root().CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
end)

-- DRAG MOBILE ---------------------------------------------------------------
local function makeDraggable(handle, object)
	local dragging = false
	local startInput
	local startPosition
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startInput = input.Position
			startPosition = object.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position - startInput
		object.Position = UDim2.fromOffset(startPosition.X.Offset + delta.X, startPosition.Y.Offset + delta.Y)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- BOOT -----------------------------------------------------------------------
createGui()

performanceLabel = Instance.new("TextLabel")
performanceLabel.Size = UDim2.fromOffset(190, 25)
performanceLabel.Position = UDim2.fromOffset(14, 48)
performanceLabel.BackgroundColor3 = COLORS.bg
performanceLabel.BackgroundTransparency = 0.1
performanceLabel.Font = Enum.Font.Code
performanceLabel.TextColor3 = COLORS.accent
performanceLabel.TextSize = 11
performanceLabel.TextXAlignment = Enum.TextXAlignment.Left
performanceLabel.Visible = false
performanceLabel.Parent = gui
addCorner(performanceLabel, 5)

local header = shell:FindFirstChild("Header")
makeDraggable(header, shell)

-- ReconstrÃ³i os controles aqui, separado do construtor para as funÃ§Ãµes jÃ¡ existirem.
local scroll = shell:FindFirstChild("Tools")
local layout = scroll:FindFirstChildOfClass("UIListLayout")
local function uiLabel(text)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Size = UDim2.new(1, 0, 0, 21)
	object.Font = Enum.Font.GothamBold
	object.Text = string.upper(text)
	object.TextColor3 = COLORS.muted
	object.TextSize = 10
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Parent = scroll
end
local function uiButton(key, text, callback)
	local object = Instance.new("TextButton")
	object.Size = UDim2.new(1, 0, 0, 38)
	object.BackgroundColor3 = COLORS.panel
	object.BorderSizePixel = 0
	object.AutoButtonColor = false
	object.Font = Enum.Font.GothamMedium
	object.TextSize = 11
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.Parent = scroll
	addCorner(object, 6)
	addStroke(object)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = object
	local function refresh()
		local on = State[key] == true
		object.Text = (on and "â—  " or "â—‹  ") .. text
		object.TextColor3 = on and COLORS.accent or COLORS.muted
		object.BackgroundColor3 = on and Color3.fromRGB(42, 50, 33) or COLORS.panel
	end
	object.Activated:Connect(function() callback(); refresh() end)
	refresh()
end

uiLabel("visualizaÃ§Ã£o")
uiButton("ESP", "Player ESP", function() State.ESP = not State.ESP end)
uiButton("Names", "Nomes", function() State.Names = not State.Names end)
uiButton("Distance", "DistÃ¢ncia", function() State.Distance = not State.Distance end)
uiButton("Highlight", "Highlight", function() State.Highlight = not State.Highlight end)
uiLabel("movimento QA")
uiButton("Speed", "Speed QA", function() State.Speed = not State.Speed; applyMovement() end)
uiButton("Jump", "Jump QA", function() State.Jump = not State.Jump; applyMovement() end)
uiButton("Noclip", "Noclip QA", function() setNoclip(not State.Noclip) end)
uiButton("Fly", "Fly QA", function() setFly(not State.Fly) end)
uiButton("ClickTP", "Click Teleport QA", function() State.ClickTP = not State.ClickTP end)
uiButton("Freecam", "Freecam QA", function() setFreecam(not State.Freecam) end)
uiLabel("mundo e cÃ¢mera")
uiButton("Fullbright", "Fullbright QA", function() setFullbright(not State.Fullbright) end)
uiButton("XRay", "X-Ray visual", function() setXRay(not State.XRay) end)
uiButton("Waypoint", "Waypoint", function() setWaypoint(not State.Waypoint) end)
uiButton("Collision", "Visualizador de colisÃ£o", function() setCollision(not State.Collision) end)
uiButton("FOV", "FOV QA", function() setFOV(not State.FOV) end)
uiButton("Performance", "Performance HUD", function() setPerformance(not State.Performance) end)
uiLabel("controles")
uiButton("Reset", "Resetar ferramentas", resetTools)

local toggle = Instance.new("TextButton")
toggle.Name = "TogglePanel"
toggle.Size = UDim2.fromOffset(46, 46)
toggle.Position = UDim2.fromOffset(14, 545)
toggle.BackgroundColor3 = COLORS.panel
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Font = Enum.Font.GothamBold
toggle.Text = "QA"
toggle.TextColor3 = COLORS.accent
toggle.TextSize = 11
toggle.Parent = gui
addCorner(toggle, 50)
addStroke(toggle, COLORS.accent)
toggle.Activated:Connect(function()
	panelVisible = not panelVisible
	shell.Visible = panelVisible
end)

connect(Players.PlayerAdded, function(otherPlayer)
	otherPlayer.CharacterAdded:Connect(function() task.wait(0.4); addESP(otherPlayer) end)
end)
connect(Players.PlayerRemoving, removeESP)
connect(RunService.RenderStepped, updateESP)
connect(RunService.RenderStepped, updateFly)
connect(player.CharacterAdded, function()
	task.wait(0.5)
	applyMovement()
	if State.Fly then setFly(true) end
	if State.Noclip then setNoclip(true) end
end)

for _, otherPlayer in ipairs(Players:GetPlayers()) do
	addESP(otherPlayer)
end

-- RemoÃ§Ã£o segura pelo botÃ£o de fechar pelo prÃ³prio jogo.
gui.Destroying:Connect(function()
	if destroyed then return end
	destroyed = true
	resetTools()
	for _, connection in ipairs(connections) do connection:Disconnect() end
	for otherPlayer in pairs(espData) do removeESP(otherPlayer) end
end)

notify("Mobile QA pronto")
print("[UNICLUDE QA] LocalScript carregado com sucesso")
