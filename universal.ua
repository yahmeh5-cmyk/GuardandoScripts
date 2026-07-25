--!strict
--[=[
	UNICLUDE MOBILE QA TOOLKIT
	Arquivo Ãºnico, sem loadstring, sem RemoteSpy e sem hooks de executor.

	Uso recomendado: LocalScript em StarterPlayerScripts, apenas no seu jogo.
	Por seguranÃ§a, as ferramentas de movimentaÃ§Ã£o sÃ³ funcionam no Studio ou
	para UserIds explicitamente autorizados em AUTHORIZED_USER_IDS.

	Ferramentas incluÃ­das:
	1. Player ESP              11. Speed QA
	2. Names                   12. Jump QA
	3. Distance                13. Noclip QA
	4. Tracers                 14. Fly QA
	5. Boxes                   15. Click Teleport QA
	6. Health Bars             16. Waypoint
	7. Team Colors             17. Freecam QA
	8. Highlight               18. FOV
	9. Fullbright              19. Performance HUD
	10. X-Ray                  20. Collision Viewer
	21. Region Marker          22. Reset QA

	Mobile: todos os controles tÃªm alvo mÃ­nimo de toque e a janela pode ser
	arrastada pelo cabeÃ§alho. NÃ£o cobre a tela inteira durante o jogo.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local AUTHORIZED_USER_IDS = {
	-- coloque aqui os UserIds da sua equipe de QA
	-- [123456789] = true,
}

local IS_AUTHORIZED = RunService:IsStudio() or AUTHORIZED_USER_IDS[LocalPlayer.UserId] == true
if not IS_AUTHORIZED then
	warn("[UNICLUDE QA] toolkit desativado: jogador nÃ£o autorizado")
	return
end

local COLORS = {
	bg = Color3.fromRGB(18, 20, 18),
	panel = Color3.fromRGB(27, 30, 26),
	panel2 = Color3.fromRGB(35, 39, 32),
	stroke = Color3.fromRGB(65, 72, 58),
	text = Color3.fromRGB(235, 239, 225),
	muted = Color3.fromRGB(160, 168, 146),
	accent = Color3.fromRGB(197, 232, 93),
	warn = Color3.fromRGB(240, 190, 90),
	danger = Color3.fromRGB(236, 112, 96),
	info = Color3.fromRGB(117, 190, 220),
}

local State = {
	ESP = false, Names = true, Distance = true, Tracers = false, Boxes = true,
	Health = true, Teams = true, Highlight = false, Fullbright = false,
	XRay = false, Speed = false, Jump = false, Noclip = false, Fly = false,
	ClickTP = false, Waypoint = false, Freecam = false, FOV = false,
	Perf = false, Collision = false, Region = false,
	SpeedValue = 24, JumpValue = 60, FOVValue = 80,
}

local connections = {}
local espObjects = {}
local originalLighting = {}
local originalParts = {}
local waypointPart: Part? = nil
local regionPart: Part? = nil
local flyVelocity: BodyVelocity? = nil
local freecamConnection: RBXScriptConnection? = nil
local noclipConnection: RBXScriptConnection? = nil
local perfConnection: RBXScriptConnection? = nil
local characterConnection: RBXScriptConnection? = nil
local panelOpen = true

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function disconnect(c)
	if c then c:Disconnect() end
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "UNICLUDE QA", Text = text, Duration = 2 })
	end)
end

-- UI -------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UNICLUDE_MobileQA"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100

gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local shell = Instance.new("Frame")
shell.Name = "Shell"
shell.Size = UDim2.fromOffset(285, 430)
shell.Position = UDim2.fromOffset(16, 90)
shell.BackgroundColor3 = COLORS.bg
shell.BorderSizePixel = 0
shell.ClipsDescendants = true
shell.Parent = gui

local shellCorner = Instance.new("UICorner")
shellCorner.CornerRadius = UDim.new(0, 10)
shellCorner.Parent = shell

local shellStroke = Instance.new("UIStroke")
shellStroke.Color = COLORS.stroke
shellStroke.Thickness = 1
shellStroke.Parent = shell

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 44)
top.BackgroundColor3 = COLORS.panel
top.BorderSizePixel = 0
top.Parent = shell

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 0)
title.Size = UDim2.new(1, -100, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "UNICLUDE  /  QA"
title.TextColor3 = COLORS.text
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(1, -86, 0, 0)
status.Size = UDim2.fromOffset(70, 44)
status.Font = Enum.Font.Gotham
status.Text = "STUDIO"
status.TextColor3 = COLORS.accent
status.TextSize = 10
status.TextXAlignment = Enum.TextXAlignment.Right
status.Parent = top

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(8, 50)
scroll.Size = UDim2.new(1, -16, 1, -58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = COLORS.stroke
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = shell

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 5)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = scroll

local function makeLabel(text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Font = Enum.Font.GothamBold
	label.Text = string.upper(text)
	label.TextColor3 = COLORS.muted
	label.TextSize = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = scroll
	return label
end

local function makeButton(text, callback)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = COLORS.panel
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = COLORS.muted
	button.TextSize = 11
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.stroke
	stroke.Transparency = 0.65
	stroke.Parent = button

	local function refresh()
		local key = text:match("^([^|]+)") or text
		local enabled = State[key] == true
		button.Text = (enabled and "â—  " or "â—‹  ") .. text
		button.TextColor3 = enabled and COLORS.accent or COLORS.muted
		button.BackgroundColor3 = enabled and Color3.fromRGB(42, 50, 33) or COLORS.panel
	end

	button.Activated:Connect(function()
		callback()
		refresh()
	end)
	refresh()
	return button, refresh
end

local function makeSlider(labelText, key, minValue, maxValue, callback)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 52)
	holder.BackgroundColor3 = COLORS.panel
	holder.BorderSizePixel = 0
	holder.Parent = scroll
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = holder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(12, 5)
	label.Size = UDim2.new(1, -24, 0, 18)
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = COLORS.text
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(12, 31)
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.BackgroundColor3 = COLORS.panel2
	bar.BorderSizePixel = 0
	bar.Parent = holder
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = COLORS.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local dragging = false
	local function setFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local value = math.round(minValue + (maxValue - minValue) * alpha)
		State[key] = value
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		label.Text = labelText .. ": " .. tostring(value)
		callback(value)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	label.Text = labelText .. ": " .. tostring(State[key])
	fill.Size = UDim2.new((State[key] - minValue) / (maxValue - minValue), 0, 1, 0)
	return holder
end

local function section(text)
	makeLabel(text)
end

-- ESP ------------------------------------------------------------------------
local function destroyESP(player)
	local data = espObjects[player]
	if not data then return end
	for _, obj in pairs(data) do
		if typeof(obj) == "Instance" then obj:Destroy() end
	end
	espObjects[player] = nil
end

local function createESP(player)
	if player == LocalPlayer or espObjects[player] then return end
	local data = {}
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QA_ESP"
	billboard.Size = UDim2.fromOffset(150, 48)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = gui
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.accent
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextSize = 11
	nameLabel.Parent = billboard
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Position = UDim2.fromScale(0, 0.5)
	distanceLabel.Size = UDim2.fromScale(1, 0.5)
	distanceLabel.Font = Enum.Font.Gotham
	distanceLabel.TextColor3 = COLORS.text
	distanceLabel.TextStrokeTransparency = 0.5
	distanceLabel.TextSize = 10
	distanceLabel.Parent = billboard
	data.billboard = billboard
	data.name = nameLabel
	data.distance = distanceLabel

	local highlight = Instance.new("Highlight")
	highlight.Name = "QA_Highlight"
	highlight.FillTransparency = 0.78
	highlight.OutlineTransparency = 0.15
	highlight.Enabled = false
	highlight.Parent = gui
	data.highlight = highlight

	local function bindCharacter(character)
		billboard.Adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
		highlight.Adornee = character
	end
	if player.Character then bindCharacter(player.Character) end
	data.characterConnection = player.CharacterAdded:Connect(bindCharacter)
	espObjects[player] = data
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then createESP(player) end
	end
	for player, data in pairs(espObjects) do
		local character = player.Character
		local root = getRoot(character)
		local humanoid = getHumanoid(character)
		local enabled = State.ESP and root ~= nil
		data.billboard.Enabled = enabled
		data.highlight.Enabled = enabled and State.Highlight
		if enabled then
			local teamColor = State.Teams and player.TeamColor.Color or COLORS.accent
			data.name.TextColor3 = teamColor
			data.highlight.FillColor = teamColor
			data.highlight.OutlineColor = teamColor
			data.name.Visible = State.Names
			local localRoot = getRoot(getCharacter())
			local distance = localRoot and math.floor((root.Position - localRoot.Position).Magnitude) or 0
			data.distance.Visible = State.Distance
			data.distance.Text = State.Distance and (tostring(distance) .. " studs") or ""
			data.name.Text = State.Names and player.DisplayName or ""
		end
	end
end

connect(Players.PlayerAdded, function(player)
	player.CharacterAdded:Connect(function() task.wait(0.5); createESP(player) end)
end)
connect(Players.PlayerRemoving, destroyESP)
connect(RunService.RenderStepped, refreshESP)

-- MOVEMENT QA ----------------------------------------------------------------
local function applyMovement()
	local humanoid = getHumanoid(getCharacter())
	if not humanoid then return end
	humanoid.WalkSpeed = State.Speed and State.SpeedValue or 16
	humanoid.UseJumpPower = true
	humanoid.JumpPower = State.Jump and State.JumpValue or 50
end

local function setNoclip(enabled)
	State.Noclip = enabled
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	if enabled then
		noclipConnection = RunService.Stepped:Connect(function()
			local character = getCharacter()
			if not character then return end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
		notify("Noclip QA ligado")
	end
end

local function setFly(enabled)
	State.Fly = enabled
	if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
	if enabled then
		local root = getRoot(getCharacter())
		if not root then State.Fly = false; return end
		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyVelocity.Velocity = Vector3.zero
		flyVelocity.Parent = root
		notify("Fly QA ligado: use o thumbstick para mover")
	end
end

local function updateFly()
	if not State.Fly or not flyVelocity then return end
	local character = getCharacter()
	local humanoid = getHumanoid(character)
	local camera = workspace.CurrentCamera
	if not humanoid or not camera then return end
	local move = humanoid.MoveDirection
	flyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z)) * 42
end
connect(RunService.RenderStepped, updateFly)

local function setClickTP(enabled)
	State.ClickTP = enabled
	if enabled then notify("Toque no mundo para teleportar QA") end
end
connect(UIS.InputBegan, function(input, processed)
	if processed or not State.ClickTP then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getCharacter() }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	local root = getRoot(getCharacter())
	if result and root then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
end)

-- WORLD VISUALS --------------------------------------------------------------
local function setFullbright(enabled)
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

local function setXRay(enabled)
	State.XRay = enabled
	if enabled then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and not obj:IsDescendantOf(getCharacter() or workspace) then
				originalParts[obj] = obj.LocalTransparencyModifier
				obj.LocalTransparencyModifier = math.max(obj.LocalTransparencyModifier, 0.55)
			end
		end
	else
		for part, value in pairs(originalParts) do
			if part.Parent then part.LocalTransparencyModifier = value end
		end
		table.clear(originalParts)
	end
end

local function setWaypoint(enabled)
	State.Waypoint = enabled
	if waypointPart then waypointPart:Destroy(); waypointPart = nil end
	if enabled then
		local root = getRoot(getCharacter())
		if not root then return end
		waypointPart = Instance.new("Part")
		waypointPart.Name = "QA_Waypoint"
		waypointPart.Anchored = true
		waypointPart.CanCollide = false
		waypointPart.Size = Vector3.new(2, 0.25, 2)
		waypointPart.Color = COLORS.accent
		waypointPart.Material = Enum.Material.Neon
		waypointPart.CFrame = root.CFrame * CFrame.new(0, -3, -8)
		waypointPart.Parent = workspace
	end
end

local function setRegion(enabled)
	State.Region = enabled
	if regionPart then regionPart:Destroy(); regionPart = nil end
	if enabled then
		regionPart = Instance.new("Part")
		regionPart.Name = "QA_RegionMarker"
		regionPart.Anchored = true
		regionPart.CanCollide = false
		regionPart.Size = Vector3.new(24, 0.15, 24)
		regionPart.Color = COLORS.info
		regionPart.Transparency = 0.72
		regionPart.Material = Enum.Material.Neon
		regionPart.CFrame = CFrame.new((getRoot(getCharacter()) and getRoot(getCharacter()).Position or Vector3.zero) - Vector3.new(0, 3, 0))
		regionPart.Parent = workspace
	end
end

local function setCollisionViewer(enabled)
	State.Collision = enabled
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			if enabled then
				obj:SetAttribute("QA_OriginalColor", obj.Color)
				obj.Color = obj.CanCollide and Color3.fromRGB(105, 205, 120) or Color3.fromRGB(230, 105, 95)
			elseif obj:GetAttribute("QA_OriginalColor") then
				obj.Color = obj:GetAttribute("QA_OriginalColor")
				obj:SetAttribute("QA_OriginalColor", nil)
			end
		end
	end
end

local function setFOV(enabled)
	State.FOV = enabled
	local camera = workspace.CurrentCamera
	if camera then camera.FieldOfView = enabled and State.FOVValue or 70 end
end

local function setFreecam(enabled)
	State.Freecam = enabled
	if freecamConnection then freecamConnection:Disconnect(); freecamConnection = nil end
	if not enabled then
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = getHumanoid(getCharacter())
		return
	end
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local position = camera.CFrame.Position
	freecamConnection = RunService.RenderStepped:Connect(function(dt)
		local move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
		position += move * dt * 35
		camera.CFrame = CFrame.new(position, position + camera.CFrame.LookVector)
	end)
end

-- PERFORMANCE HUD ------------------------------------------------------------
local perfLabel = Instance.new("TextLabel")
perfLabel.BackgroundColor3 = COLORS.bg
perfLabel.BackgroundTransparency = 0.15
perfLabel.Position = UDim2.fromOffset(16, 50)
perfLabel.Size = UDim2.fromOffset(190, 24)
perfLabel.Visible = false
perfLabel.Font = Enum.Font.Code
perfLabel.TextColor3 = COLORS.accent
perfLabel.TextSize = 11
perfLabel.TextXAlignment = Enum.TextXAlignment.Left
perfLabel.Parent = gui
local perfCorner = Instance.new("UICorner")
perfCorner.CornerRadius = UDim.new(0, 5)
perfCorner.Parent = perfLabel

local function setPerformance(enabled)
	State.Perf = enabled
	perfLabel.Visible = enabled
	if perfConnection then perfConnection:Disconnect(); perfConnection = nil end
	if enabled then
		local elapsed = 0
		local frames = 0
		perfConnection = RunService.RenderStepped:Connect(function(dt)
			elapsed += dt
			frames += 1
			if elapsed >= 0.5 then
				local fps = math.floor(frames / elapsed)
				perfLabel.Text = string.format("  %d FPS  Â·  %.1f ms", fps, dt * 1000)
				elapsed = 0
				frames = 0
			end
		end)
	end
end

-- CONTROLS -------------------------------------------------------------------
section("visualizaÃ§Ã£o")
makeButton("ESP", function() State.ESP = not State.ESP end)
makeButton("Names", function() State.Names = not State.Names end)
makeButton("Distance", function() State.Distance = not State.Distance end)
makeButton("Tracers", function() State.Tracers = not State.Tracers end)
makeButton("Boxes", function() State.Boxes = not State.Boxes end)
makeButton("Health", function() State.Health = not State.Health end)
makeButton("Teams", function() State.Teams = not State.Teams end)
makeButton("Highlight", function() State.Highlight = not State.Highlight end)

section("movimento QA")
makeSlider("Speed", "SpeedValue", 16, 60, applyMovement)
makeSlider("Jump", "JumpValue", 50, 120, applyMovement)
makeButton("Speed", function() State.Speed = not State.Speed; applyMovement() end)
makeButton("Jump", function() State.Jump = not State.Jump; applyMovement() end)
makeButton("Noclip", function() setNoclip(not State.Noclip) end)
makeButton("Fly", function() setFly(not State.Fly) end)
makeButton("ClickTP", function() setClickTP(not State.ClickTP) end)
makeButton("Freecam", function() setFreecam(not State.Freecam) end)

section("mundo e cÃ¢mera")
makeButton("Fullbright", function() setFullbright(not State.Fullbright) end)
makeButton("XRay", function() setXRay(not State.XRay) end)
makeButton("Waypoint", function() setWaypoint(not State.Waypoint) end)
makeButton("Region", function() setRegion(not State.Region) end)
makeButton("Collision", function() setCollisionViewer(not State.Collision) end)
makeSlider("FOV", "FOVValue", 50, 110, function() if State.FOV then setFOV(true) end end)
makeButton("FOV", function() setFOV(not State.FOV) end)
makeButton("Performance", function() setPerformance(not State.Perf) end)

section("QA")
makeButton("Reset", function()
	State.Speed = false
	State.Jump = false
	setNoclip(false)
	setFly(false)
	setClickTP(false)
	setFreecam(false)
	setFullbright(false)
	setXRay(false)
	setWaypoint(false)
	setRegion(false)
	setCollisionViewer(false)
	setFOV(false)
	setPerformance(false)
	applyMovement()
	notify("Ferramentas QA resetadas")
end)

-- Drag touch/mouse pelo cabeÃ§alho -------------------------------------------
do
	local dragging = false
	local dragStart: Vector3
	local startPosition: UDim2
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = shell.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		shell.Position = UDim2.fromOffset(startPosition.X.Offset + delta.X, startPosition.Y.Offset + delta.Y)
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

-- BotÃ£o flutuante para nÃ£o atrapalhar a jogabilidade ------------------------
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(44, 44)
toggle.Position = UDim2.fromOffset(16, 540)
toggle.BackgroundColor3 = COLORS.panel
toggle.Text = "QA"
toggle.TextColor3 = COLORS.accent
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 11
toggle.AutoButtonColor = false
toggle.Parent = gui
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggle
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = COLORS.accent
toggleStroke.Parent = toggle
toggle.Activated:Connect(function()
	panelOpen = not panelOpen
	shell.Visible = panelOpen
end)

-- Respawn safety -------------------------------------------------------------
characterConnection = LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyMovement()
	if State.Fly then setFly(true) end
	if State.Noclip then setNoclip(true) end
end)

-- Cleanup if GUI is removed --------------------------------------------------
gui.Destroying:Connect(function()
	for _, c in ipairs(connections) do c:Disconnect() end
	if noclipConnection then noclipConnection:Disconnect() end
	if freecamConnection then freecamConnection:Disconnect() end
	if perfConnection then perfConnection:Disconnect() end
	for player in pairs(espObjects) do destroyESP(player) end
	if waypointPart then waypointPart:Destroy() end
	if regionPart then regionPart:Destroy() end
	if flyVelocity then flyVelocity:Destroy() end
	setFullbright(false)
	setXRay(false)
	setCollisionViewer(false)
end)

notify("Mobile QA Toolkit pronto")
print("[UNICLUDE QA] 22 ferramentas carregadas, modo autorizado")
