--!strict
-- AdminMobile.client.lua
-- Coloque como LocalScript em StarterPlayerScripts.
-- IMPORTANTE: isto Ã© uma interface local para o seu prÃ³prio jogo.
-- Para seguranÃ§a real, valide permissÃµes e comandos no servidor com RemoteEvents.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Troque pelos UserIds dos administradores do seu jogo.
local ADMINS: {[number]: boolean} = {
    [LocalPlayer.UserId] = true, -- remova esta linha e use os IDs reais antes de publicar
}

if not ADMINS[LocalPlayer.UserId] then
    return
end

local COLORS = {
    bg = Color3.fromRGB(245, 247, 241),
    panel = Color3.fromRGB(255, 255, 252),
    soft = Color3.fromRGB(232, 238, 226),
    line = Color3.fromRGB(214, 222, 207),
    text = Color3.fromRGB(38, 48, 40),
    muted = Color3.fromRGB(105, 119, 105),
    accent = Color3.fromRGB(122, 190, 115),
    accentDark = Color3.fromRGB(47, 105, 54),
    danger = Color3.fromRGB(190, 78, 63),
    blue = Color3.fromRGB(66, 125, 192),
}

local State = {
    ESP = false,
    Fly = false,
    Noclip = false,
    InfiniteJump = false,
    Speed = false,
    SpeedValue = 32,
    FOV = false,
    FOVValue = 80,
}

local Connections: {[string]: RBXScriptConnection} = {}
local ESPObjects: {[Player]: BillboardGui} = {}
local flyVelocity: BodyVelocity? = nil
local flyGyro: BodyGyro? = nil
local toastToken = 0

local function disconnect(name: string)
    if Connections[name] then
        Connections[name]:Disconnect()
        Connections[name] = nil
    end
end

local function getCharacter(): Model?
    return LocalPlayer.Character
end

local function getHumanoid(): Humanoid?
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(): BasePart?
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function notify(text: string)
    toastToken += 1
    local token = toastToken
    local toast = PlayerGui:FindFirstChild("AdminToast")
    if not toast then return end
    local label = toast:FindFirstChild("Label") :: TextLabel?
    if not label then return end
    label.Text = text
    toast.Enabled = true
    task.delay(2.2, function()
        if token == toastToken then
            toast.Enabled = false
        end
    end)
end

local function make(className: string, properties: {[string]: any}, parent: Instance?): Instance
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    if parent then object.Parent = parent end
    return object
end

local function rounded(object: GuiObject, radius: number)
    make("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
end

local function stroke(object: GuiObject, color: Color3?, thickness: number?)
    make("UIStroke", {Color = color or COLORS.line, Thickness = thickness or 1}, object)
end

local screen = make("ScreenGui", {
    Name = "AdminMobileGui",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, PlayerGui) :: ScreenGui

local panel = make("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 16, 1, -16),
    Size = UDim2.new(0, 330, 0, 430),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
}, screen) :: Frame
rounded(panel, 22)
stroke(panel, COLORS.line, 1)

local scale = make("UIScale", {Scale = 1}, panel) :: UIScale
local function adaptScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    scale.Scale = math.clamp(width / 430, 0.82, 1)
end
adaptScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(adaptScale)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptScale) end

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundTransparency = 1,
}, panel) :: Frame
local title = make("TextLabel", {
    Position = UDim2.new(0, 18, 0, 14), Size = UDim2.new(1, -70, 0, 25),
    BackgroundTransparency = 1, Text = "CONTROLE DO SERVIDOR", TextColor3 = COLORS.text,
    Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left,
}, header) :: TextLabel
local subtitle = make("TextLabel", {
    Position = UDim2.new(0, 18, 0, 42), Size = UDim2.new(1, -70, 0, 18),
    BackgroundTransparency = 1, Text = "modo admin ativo â€¢ local", TextColor3 = COLORS.muted,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, header) :: TextLabel
local minimize = make("TextButton", {
    Position = UDim2.new(1, -54, 0, 16), Size = UDim2.new(0, 38, 0, 38),
    BackgroundColor3 = COLORS.soft, BorderSizePixel = 0, Text = "âˆ’", TextColor3 = COLORS.text,
    Font = Enum.Font.GothamBold, TextSize = 24, AutoButtonColor = true,
}, header) :: TextButton
rounded(minimize, 12)

local divider = make("Frame", {
    Position = UDim2.new(0, 16, 0, 75), Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = COLORS.line, BorderSizePixel = 0,
}, panel)

local scroll = make("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 88), Size = UDim2.new(1, -24, 1, -100),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.line, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel) :: ScrollingFrame
make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10)}, scroll)
local layout = make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll) :: UIListLayout

local function sectionLabel(text: string)
    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text,
        TextColor3 = COLORS.muted, Font = Enum.Font.GothamBold, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, scroll) :: TextLabel
    return label
end

local function setToggleVisual(button: TextButton, enabled: boolean)
    button.BackgroundColor3 = enabled and COLORS.accentDark or COLORS.soft
    button.Text = enabled and "ON" or "OFF"
    button.TextColor3 = enabled and COLORS.panel or COLORS.muted
end

local function toggleRow(labelText: string, hint: string, key: string, callback: (boolean) -> ())
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = COLORS.bg, BorderSizePixel = 0,
    }, scroll) :: Frame
    rounded(row, 14)
    stroke(row, COLORS.line, 1)
    local label = make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 8), Size = UDim2.new(1, -85, 0, 20),
        BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.text,
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 29), Size = UDim2.new(1, -85, 0, 17),
        BackgroundTransparency = 1, Text = hint, TextColor3 = COLORS.muted,
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local button = make("TextButton", {
        Position = UDim2.new(1, -66, 0.5, -15), Size = UDim2.new(0, 53, 0, 30),
        BackgroundColor3 = COLORS.soft, BorderSizePixel = 0, Text = "OFF",
        Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = true,
    }, row) :: TextButton
    rounded(button, 10)
    button.Activated:Connect(function()
        State[key] = not State[key]
        setToggleVisual(button, State[key] == true)
        callback(State[key] == true)
    end)
    return row
end

local function valueRow(labelText: string, hint: string, initial: number, minValue: number, maxValue: number, callback: (number) -> ())
    local row = make("Frame", {Size = UDim2.new(1, 0, 0, 68), BackgroundColor3 = COLORS.bg, BorderSizePixel = 0}, scroll) :: Frame
    rounded(row, 14); stroke(row, COLORS.line, 1)
    make("TextLabel", {Position = UDim2.new(0, 13, 0, 8), Size = UDim2.new(1, -100, 0, 20), BackgroundTransparency = 1, Text = labelText, TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, row)
    make("TextLabel", {Position = UDim2.new(0, 13, 0, 31), Size = UDim2.new(1, -100, 0, 17), BackgroundTransparency = 1, Text = hint, TextColor3 = COLORS.muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local value = make("TextLabel", {Position = UDim2.new(1, -75, 0, 13), Size = UDim2.new(0, 60, 0, 28), BackgroundTransparency = 1, Text = tostring(initial), TextColor3 = COLORS.accentDark, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right}, row) :: TextLabel
    local minus = make("TextButton", {Position = UDim2.new(0, 13, 1, -31), Size = UDim2.new(0, 25, 0, 22), BackgroundColor3 = COLORS.soft, BorderSizePixel = 0, Text = "âˆ’", TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 18}, row) :: TextButton
    local plus = make("TextButton", {Position = UDim2.new(0, 43, 1, -31), Size = UDim2.new(0, 25, 0, 22), BackgroundColor3 = COLORS.soft, BorderSizePixel = 0, Text = "+", TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 16}, row) :: TextButton
    rounded(minus, 8); rounded(plus, 8)
    local current = initial
    local function update(delta: number)
        current = math.clamp(current + delta, minValue, maxValue)
        value.Text = tostring(current)
        callback(current)
    end
    minus.Activated:Connect(function() update(-1) end)
    plus.Activated:Connect(function() update(1) end)
    return row
end

local function removeESP(player: Player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function addESP(player: Player)
    if player == LocalPlayer or not State.ESP then return end
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end
    removeESP(player)
    local billboard = make("BillboardGui", {Name = "AdminESP", Adornee = head, Size = UDim2.new(0, 150, 0, 38), StudsOffset = Vector3.new(0, 2.8, 0), AlwaysOnTop = true, MaxDistance = 500}, head) :: BillboardGui
    local label = make("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = COLORS.accentDark, BackgroundTransparency = 0.08, BorderSizePixel = 0, Text = player.DisplayName .. "  â€¢  @" .. player.Name, TextColor3 = COLORS.panel, Font = Enum.Font.GothamBold, TextSize = 11, TextStrokeTransparency = 0.7}, billboard) :: TextLabel
    rounded(label, 8)
    ESPObjects[player] = billboard
end

local function setESP(enabled: boolean)
    if enabled then
        for _, player in Players:GetPlayers() do addESP(player) end
        disconnect("playerAdded")
        Connections.playerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function() task.wait(0.5); addESP(player) end)
        end)
        disconnect("espRefresh")
        Connections.espRefresh = RunService.Heartbeat:Connect(function()
            for player in pairs(ESPObjects) do
                if not player.Parent or not player.Character then removeESP(player) end
            end
        end)
    else
        disconnect("playerAdded"); disconnect("espRefresh")
        for player in pairs(ESPObjects) do removeESP(player) end
    end
end

local function setSpeed(enabled: boolean)
    local humanoid = getHumanoid()
    if humanoid then humanoid.WalkSpeed = enabled and State.SpeedValue or 16 end
end

local function setNoclip(enabled: boolean)
    if enabled then
        disconnect("noclip")
        Connections.noclip = RunService.Stepped:Connect(function()
            local character = getCharacter()
            if character then
                for _, object in character:GetDescendants() do
                    if object:IsA("BasePart") then object.CanCollide = false end
                end
            end
        end)
    else
        disconnect("noclip")
        local character = getCharacter()
        if character then
            for _, object in character:GetDescendants() do
                if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" then object.CanCollide = true end
            end
        end
    end
end

local function setFly(enabled: boolean)
    local root = getRoot()
    if not root then return end
    if enabled then
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.Parent = root
        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyGyro.P = 1e4
        flyGyro.CFrame = root.CFrame
        flyGyro.Parent = root
        disconnect("fly")
        Connections.fly = RunService.RenderStepped:Connect(function()
            if not State.Fly or not flyVelocity or not flyGyro then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
            flyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * 48 or Vector3.zero
            flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + camera.CFrame.LookVector)
        end)
    else
        disconnect("fly")
        if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
        if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    end
end

sectionLabel("MOVIMENTO")
toggleRow("Fly", "WASD + EspaÃ§o / Ctrl", "Fly", function(enabled) setFly(enabled); notify(enabled and "Fly ativado" or "Fly desativado") end)
toggleRow("Noclip", "Atravesse objetos e paredes", "Noclip", function(enabled) setNoclip(enabled); notify(enabled and "Noclip ativado" or "Noclip desativado") end)
toggleRow("Pulo infinito", "Pule no ar pelo botÃ£o de pulo", "InfiniteJump", function(enabled) notify(enabled and "Pulo infinito ativado" or "Pulo infinito desativado") end)
valueRow("Velocidade", "Ative o controle abaixo", 32, 16, 80, function(value) State.SpeedValue = value; if State.Speed then setSpeed(true) end end)
toggleRow("Speed", "Velocidade atual: " .. tostring(State.SpeedValue), "Speed", function(enabled) setSpeed(enabled); notify(enabled and "Speed ativado" or "Speed desativado") end)

sectionLabel("VISIBILIDADE")
toggleRow("ESP jogadores", "Nome e distÃ¢ncia acima do jogador", "ESP", function(enabled) setESP(enabled); notify(enabled and "ESP ativado" or "ESP desativado") end)
toggleRow("Campo de visÃ£o", "Aumenta sua visÃ£o perifÃ©rica", "FOV", function(enabled)
    local camera = workspace.CurrentCamera
    if camera then camera.FieldOfView = enabled and State.FOVValue or 70 end
    notify(enabled and "Campo de visÃ£o ativado" or "Campo de visÃ£o normal")
end)
valueRow("FOV", "Ã‚ngulo da cÃ¢mera", 80, 70, 110, function(value) State.FOVValue = value; if State.FOV then local camera = workspace.CurrentCamera; if camera then camera.FieldOfView = value end end end)

sectionLabel("SEGURANÃ‡A")
local reset = make("TextButton", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(250, 235, 231), BorderSizePixel = 0, Text = "DESATIVAR TUDO", TextColor3 = COLORS.danger, Font = Enum.Font.GothamBold, TextSize = 12}, scroll) :: TextButton
rounded(reset, 12)
reset.Activated:Connect(function()
    State.ESP = false; State.Fly = false; State.Noclip = false; State.Speed = false; State.InfiniteJump = false; State.FOV = false
    setESP(false); setFly(false); setNoclip(false); setSpeed(false)
    local camera = workspace.CurrentCamera; if camera then camera.FieldOfView = 70 end
    notify("Todos os recursos foram desativados")
end)

local restore = make("TextButton", {Name = "Restore", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), Size = UDim2.new(0, 58, 0, 58), BackgroundColor3 = COLORS.text, BorderSizePixel = 0, Text = "âš™", TextColor3 = COLORS.panel, Font = Enum.Font.GothamBold, TextSize = 25, Visible = false}, screen) :: TextButton
rounded(restore, 18)
minimize.Activated:Connect(function() panel.Visible = false; restore.Visible = true end)
restore.Activated:Connect(function() panel.Visible = true; restore.Visible = false end)

local toastGui = make("ScreenGui", {Name = "AdminToast", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100}, PlayerGui) :: ScreenGui
local toastFrame = make("Frame", {Name = "Frame", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.new(0, 240, 0, 38), BackgroundColor3 = COLORS.text, BorderSizePixel = 0}, toastGui) :: Frame
rounded(toastFrame, 12)
local toastLabel = make("TextLabel", {Name = "Label", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", TextColor3 = COLORS.panel, Font = Enum.Font.GothamBold, TextSize = 12}, toastFrame) :: TextLabel
toastGui.Enabled = false

Connections.character = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.75)
    if State.Speed then setSpeed(true) end
    if State.Fly then setFly(true) end
    if State.Noclip then setNoclip(true) end
end)
Connections.jump = UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local humanoid = getHumanoid()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Arrastar o painel no celular ou PC.
do
    local dragging = false
    local dragStart: Vector2
    local startPosition: UDim2
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

notify("Painel admin carregado")
