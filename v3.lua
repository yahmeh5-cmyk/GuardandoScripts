--[=[
    AdminMobile.client.lua
    Coloque este arquivo em StarterPlayer > StarterPlayerScripts.

    Importante:
    Este painel roda no cliente. ESP, Fly, Speed e Noclip alteram apenas a
    experiÃªncia local e nÃ£o substituem validaÃ§Ãµes no servidor.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- =========================
-- CONFIGURAÃ‡ÃƒO
-- =========================
local CONFIG = {
    WalkSpeed = 32,
    FlySpeed = 65,
    PanelWidth = 292,
    Accent = Color3.fromRGB(111, 78, 246),
    Background = Color3.fromRGB(24, 22, 31),
    Surface = Color3.fromRGB(35, 32, 45),
    SurfaceAlt = Color3.fromRGB(44, 40, 57),
    Text = Color3.fromRGB(246, 243, 250),
    Muted = Color3.fromRGB(167, 160, 181),
    Success = Color3.fromRGB(92, 211, 148),
    Danger = Color3.fromRGB(239, 106, 101),
}

-- =========================
-- ESTADO
-- =========================
local state = {
    Open = true,
    ESP = false,
    Fly = false,
    Speed = false,
    Noclip = false,
    InfiniteJump = false,
    FullBright = false,
}

local connections = {}
local espObjects = {}
local flyVelocity
local flyGyro
local humanoid
local rootPart
local normalLighting = {}

-- =========================
-- UTILITÃRIOS
-- =========================
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function getCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoid = character:FindFirstChildOfClass("Humanoid")
    rootPart = character:FindFirstChild("HumanoidRootPart")
    return character
end

local function notify(text, color)
    local label = Instance.new("TextLabel")
    label.Name = "AdminToast"
    label.Size = UDim2.fromOffset(250, 38)
    label.Position = UDim2.new(0.5, -125, 0, 22)
    label.BackgroundColor3 = CONFIG.Surface
    label.BackgroundTransparency = 0.04
    label.TextColor3 = color or CONFIG.Text
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.ZIndex = 100
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label

    task.delay(2.2, function()
        if label then label:Destroy() end
    end)
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or CONFIG.SurfaceAlt,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

-- =========================
-- ESP
-- =========================
local function clearESP(player)
    local object = espObjects[player]
    if object then
        object:Destroy()
        espObjects[player] = nil
    end
end

local function addESP(player)
    if player == LocalPlayer or not state.ESP then return end
    clearESP(player)

    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AdminESP"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(170, 42)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = CONFIG.Background,
        BackgroundTransparency = 0.18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0.65,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Text = player.DisplayName .. "  @" .. player.Name,
    }, billboard)
    corner(label, 8)

    local outline = Instance.new("Highlight")
    outline.Name = "AdminESPHighlight"
    outline.Adornee = character
    outline.FillColor = CONFIG.Accent
    outline.FillTransparency = 0.82
    outline.OutlineColor = CONFIG.Accent
    outline.OutlineTransparency = 0.1
    outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    outline.Parent = character

    espObjects[player] = billboard
end

local function setESP(enabled)
    state.ESP = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            addESP(player)
        end
        notify("ESP ativado", CONFIG.Success)
    else
        for _, player in ipairs(Players:GetPlayers()) do
            clearESP(player)
            local character = player.Character
            local highlight = character and character:FindFirstChild("AdminESPHighlight")
            if highlight then highlight:Destroy() end
        end
        notify("ESP desativado", CONFIG.Muted)
    end
end

-- =========================
-- MOVIMENTO
-- =========================
local function setSpeed(enabled)
    state.Speed = enabled
    getCharacter()
    if humanoid then
        humanoid.WalkSpeed = enabled and CONFIG.WalkSpeed or 16
    end
    notify(enabled and ("Speed: " .. CONFIG.WalkSpeed) or "Speed normal", enabled and CONFIG.Success or CONFIG.Muted)
end

local function setNoclip(enabled)
    state.Noclip = enabled
    notify(enabled and "Noclip ativado" or "Noclip desativado", enabled and CONFIG.Success or CONFIG.Muted)
end

local function setFly(enabled)
    state.Fly = enabled
    getCharacter()

    if enabled and rootPart then
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Name = "AdminFlyVelocity"
        flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.Parent = rootPart

        flyGyro = Instance.new("BodyGyro")
        flyGyro.Name = "AdminFlyGyro"
        flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyGyro.P = 9000
        flyGyro.CFrame = rootPart.CFrame
        flyGyro.Parent = rootPart
        notify("Fly ativado", CONFIG.Success)
    else
        if flyVelocity then flyVelocity:Destroy() end
        if flyGyro then flyGyro:Destroy() end
        flyVelocity = nil
        flyGyro = nil
        notify("Fly desativado", CONFIG.Muted)
    end
end

local function setInfiniteJump(enabled)
    state.InfiniteJump = enabled
    notify(enabled and "Pulo infinito ativado" or "Pulo infinito desativado", enabled and CONFIG.Success or CONFIG.Muted)
end

local function setFullBright(enabled)
    state.FullBright = enabled
    local Lighting = game:GetService("Lighting")
    if enabled then
        normalLighting.Brightness = Lighting.Brightness
        normalLighting.ClockTime = Lighting.ClockTime
        normalLighting.FogEnd = Lighting.FogEnd
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        notify("Fullbright ativado", CONFIG.Success)
    else
        Lighting.Brightness = normalLighting.Brightness or 2
        Lighting.ClockTime = normalLighting.ClockTime or 14
        Lighting.FogEnd = normalLighting.FogEnd or 1000
        notify("Fullbright desativado", CONFIG.Muted)
    end
end

-- =========================
-- INTERFACE MOBILE
-- =========================
local oldGui = CoreGui:FindFirstChild("AdminMobileGui")
if oldGui then oldGui:Destroy() end

local gui = make("ScreenGui", {
    Name = "AdminMobileGui",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, CoreGui)

local panel = make("Frame", {
    Name = "Panel",
    Size = UDim2.fromOffset(CONFIG.PanelWidth, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.new(1, -16, 0, 80),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = CONFIG.Background,
}, gui)
corner(panel, 18)
stroke(panel, CONFIG.SurfaceAlt, 1)

local padding = make("UIPadding", {
    PaddingTop = UDim.new(0, 15),
    PaddingBottom = UDim.new(0, 15),
    PaddingLeft = UDim.new(0, 15),
    PaddingRight = UDim.new(0, 15),
}, panel)

local list = make("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, panel)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
}, panel)

make("TextLabel", {
    Size = UDim2.new(1, -44, 0, 22),
    BackgroundTransparency = 1,
    Text = "ADMIN DECK",
    TextColor3 = CONFIG.Text,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(0, 23),
    Size = UDim2.new(1, -44, 0, 16),
    BackgroundTransparency = 1,
    Text = "controles locais Â· mobile",
    TextColor3 = CONFIG.Muted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
}, header)

local close = make("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, 0, 0, 0),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = CONFIG.Surface,
    Text = "Ã—",
    TextColor3 = CONFIG.Muted,
    TextSize = 22,
    Font = Enum.Font.GothamMedium,
}, header)
corner(close, 10)

local function createSection(text, order)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CONFIG.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        LayoutOrder = order,
    }, panel)
end

local function createToggle(labelText, description, key, callback, order)
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CONFIG.Surface,
        LayoutOrder = order,
    }, panel)
    corner(row, 12)

    make("TextLabel", {
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -65, 0, 18),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = CONFIG.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
    }, row)

    make("TextLabel", {
        Position = UDim2.fromOffset(12, 26),
        Size = UDim2.new(1, -65, 0, 14),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = CONFIG.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
    }, row)

    local toggle = make("TextButton", {
        Name = "Toggle",
        Size = UDim2.fromOffset(38, 23),
        Position = UDim2.new(1, -11, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = CONFIG.SurfaceAlt,
        Text = "",
        AutoButtonColor = false,
    }, row)
    corner(toggle, 99)

    local knob = make("Frame", {
        Size = UDim2.fromOffset(17, 17),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = CONFIG.Muted,
    }, toggle)
    corner(knob, 99)

    local function render(value)
        toggle.BackgroundColor3 = value and CONFIG.Accent or CONFIG.SurfaceAlt
        knob.BackgroundColor3 = value and Color3.fromRGB(255, 255, 255) or CONFIG.Muted
        knob.Position = value and UDim2.new(1, -20, 0, 3) or UDim2.fromOffset(3, 3)
    end

    render(state[key])
    toggle.Activated:Connect(function()
        local value = not state[key]
        callback(value)
        render(value)
    end)
end

createSection("MOVIMENTO", 2)
createToggle("Speed", "altera a velocidade local", "Speed", setSpeed, 3)
createToggle("Fly", "voe usando o direcional e cÃ¢mera", "Fly", setFly, 4)
createToggle("Noclip", "atravesse partes localmente", "Noclip", setNoclip, 5)
createToggle("Pulo infinito", "pule no ar pelo botÃ£o de pulo", "InfiniteJump", setInfiniteJump, 6)

createSection("VISUAL", 7)
createToggle("ESP jogadores", "nomes e destaque atravÃ©s de paredes", "ESP", setESP, 8)
createToggle("Fullbright", "remove escuridÃ£o e neblina local", "FullBright", setFullBright, 9)

local reset = make("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = CONFIG.Danger,
    Text = "RESETAR CONTROLES",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 10,
}, panel)
corner(reset, 12)

local openButton = make("TextButton", {
    Name = "OpenButton",
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(1, -16, 0, 80),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = CONFIG.Accent,
    Text = "AD",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, gui)
corner(openButton, 16)

-- =========================
-- INTERAÃ‡ÃƒO
-- =========================
close.Activated:Connect(function()
    state.Open = false
    panel.Visible = false
    openButton.Visible = true
end)

openButton.Activated:Connect(function()
    state.Open = true
    panel.Visible = true
    openButton.Visible = false
end)

reset.Activated:Connect(function()
    if state.ESP then setESP(false) end
    if state.Fly then setFly(false) end
    if state.Speed then setSpeed(false) end
    if state.Noclip then setNoclip(false) end
    if state.InfiniteJump then setInfiniteJump(false) end
    if state.FullBright then setFullBright(false) end
    notify("Controles resetados", CONFIG.Success)
end)

-- Arrastar o painel em celular ou PC
local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

-- =========================
-- LOOPS DE CONTROLE
-- =========================
connect(RunService.Stepped, function()
    if state.Noclip then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

connect(RunService.RenderStepped, function()
    if state.Fly and flyVelocity and flyGyro and rootPart then
        local move = Vector3.zero
        local cameraCFrame = Camera.CFrame
        local forward = cameraCFrame.LookVector
        local right = cameraCFrame.RightVector

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end

        flyVelocity.Velocity = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
        flyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + cameraCFrame.LookVector)
    end
end)

connect(UserInputService.JumpRequest, function()
    if state.InfiniteJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

connect(Players.PlayerAdded, function(player)
    connect(player.CharacterAdded, function()
        task.wait(0.5)
        if state.ESP then addESP(player) end
    end)
end)

connect(Players.PlayerRemoving, function(player)
    clearESP(player)
end)

connect(LocalPlayer.CharacterAdded, function()
    task.wait(0.4)
    getCharacter()
    if state.Speed then humanoid.WalkSpeed = CONFIG.WalkSpeed end
    if state.Fly then setFly(false) end
end)

getCharacter()
notify("Admin Deck carregado", CONFIG.Success)
