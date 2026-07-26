--[==[
NEXUS ADMIN SUITE v2.0
LocalScript para ferramentas de debug e administracao do seu proprio jogo.

Instalacao:
  StarterPlayer > StarterPlayerScripts > LocalScript > cole este arquivo.

Atalhos:
  RightShift = abrir/fechar
  RightControl = ligar/desligar ESP
  End = destruir e restaurar

Design novo:
  - janela compacta e responsiva
  - botao flutuante arrastavel
  - textos ASCII para evitar mojibake
  - busca de jogadores
  - ESP por Drawing GUI, sem dependencias externas
  - exportacao de remotes para clipboard quando suportado
  - fallback de copia dentro da interface
  - todas as conexoes registradas e limpas no panic

Observacao:
  Funcoes que mudam o estado do servidor devem ser autorizadas por RemoteEvents
  criados pelo desenvolvedor. Este LocalScript nao tenta burlar o servidor.
]==]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

if not RunService:IsClient() then return end
local LP = Players.LocalPlayer
if not LP then return end
local Camera = Workspace.CurrentCamera

local Connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end
local function disconnectAll()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
end
local function make(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end
local function round(n, d)
    local m = 10 ^ (d or 0)
    return math.floor((tonumber(n) or 0) * m + .5) / m
end
local function char() return LP.Character end
local function humanoid()
    local c = char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function root()
    local c = char()
    return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end
local function safeClipboard(text)
    if typeof(setclipboard) == "function" then return pcall(setclipboard, text) end
    if typeof(toclipboard) == "function" then return pcall(toclipboard, text) end
    return false
end

local C = {
    bg = Color3.fromRGB(19, 18, 22),
    panel = Color3.fromRGB(27, 25, 31),
    card = Color3.fromRGB(36, 33, 41),
    raised = Color3.fromRGB(47, 43, 54),
    border = Color3.fromRGB(67, 61, 74),
    text = Color3.fromRGB(242, 239, 244),
    sub = Color3.fromRGB(168, 161, 175),
    dim = Color3.fromRGB(111, 105, 119),
    accent = Color3.fromRGB(244, 159, 99),
    good = Color3.fromRGB(113, 220, 169),
    warn = Color3.fromRGB(246, 200, 103),
    bad = Color3.fromRGB(239, 99, 116),
}

local State = {
    open = true,
    esp = false,
    players = true,
    npcs = false,
    objects = false,
    boxes = true,
    names = true,
    distance = true,
    health = true,
    tracers = false,
    skeleton = false,
    chams = false,
    arrows = false,
    teamCheck = false,
    maxDistance = 1500,
    speedOn = false,
    speed = 24,
    jumpOn = false,
    jump = 60,
    noclip = false,
    fly = false,
    fullbright = false,
    noFog = false,
    noParticles = false,
    crosshair = false,
    freecam = false,
    selectedTab = "ESP",
    search = "",
}

local Original = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Shadows = Lighting.GlobalShadows,
    Gravity = Workspace.Gravity,
    FOV = Camera and Camera.FieldOfView or 70,
}

local GuiParent = LP:WaitForChild("PlayerGui")
local RootGui = make("ScreenGui", {
    Name = "NexusAdminV2",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 900,
    Parent = GuiParent,
})
local WorldGui = make("ScreenGui", {
    Name = "NexusAdminV2ESP",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 700,
    Parent = GuiParent,
})

local function radius(o, n)
    local r = make("UICorner", { CornerRadius = UDim.new(0, n or 8), Parent = o })
    return r
end
local function outline(o, color, thickness)
    return make("UIStroke", { Color = color or C.border, Thickness = thickness or 1, Parent = o })
end
local function text(parent, value, props)
    local p = {
        Text = tostring(value or ""),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.text,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    }
    for k, v in pairs(props or {}) do p[k] = v end
    return make("TextLabel", p)
end
local function button(parent, value, props)
    local p = {
        Text = tostring(value or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = C.text,
        BackgroundColor3 = C.raised,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = parent,
    }
    for k, v in pairs(props or {}) do p[k] = v end
    return make("TextButton", p)
end
local function list(parent, direction, gap)
    return make("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, gap or 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end
local function tween(o, props, duration)
    TweenService:Create(o, TweenInfo.new(duration or .16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

-- Notifications
local Toasts = make("Frame", {
    Size = UDim2.fromOffset(280, 260),
    Position = UDim2.new(1, -300, 1, -280),
    BackgroundTransparency = 1,
    Parent = RootGui,
})
list(Toasts, Enum.FillDirection.Vertical, 8)
local function toast(title, body, color)
    local box = make("Frame", {
        Size = UDim2.new(1, 0, 0, body and 52 or 34),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        Parent = Toasts,
    })
    radius(box, 9)
    outline(box, C.border, 1)
    make("Frame", { Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(12, 15), BackgroundColor3 = color or C.accent, BorderSizePixel = 0, Parent = box })
    text(box, title, { Position = UDim2.fromOffset(25, 7), Size = UDim2.new(1, -34, 0, 16), Font = Enum.Font.GothamBold, TextSize = 12 })
    if body then text(box, body, { Position = UDim2.fromOffset(25, 25), Size = UDim2.new(1, -34, 0, 16), TextSize = 10, TextColor3 = C.sub, TextTruncate = Enum.TextTruncate.AtEnd }) end
    task.delay(3.2, function()
        if box.Parent then tween(box, { BackgroundTransparency = 1 }, .18); task.wait(.2); box:Destroy() end
    end)
end

-- Main window
local Window = make("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(670, 430),
    Position = UDim2.new(.5, -335, .5, -215),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Parent = RootGui,
})
radius(Window, 12); outline(Window, C.border, 1)
local WindowScale = make("UIScale", { Scale = 1, Parent = Window })

local Sidebar = make("Frame", { Size = UDim2.new(0, 164, 1, 0), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = Window })
radius(Sidebar, 12)
local Brand = make("Frame", { Size = UDim2.new(1, -24, 0, 58), Position = UDim2.fromOffset(12, 10), BackgroundTransparency = 1, Parent = Sidebar })
make("Frame", { Size = UDim2.fromOffset(5, 22), Position = UDim2.fromOffset(4, 17), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = Brand })
text(Brand, "NEXUS", { Position = UDim2.fromOffset(18, 13), Size = UDim2.fromOffset(120, 18), Font = Enum.Font.GothamBlack, TextSize = 16 })
text(Brand, "ADMIN SUITE v2", { Position = UDim2.fromOffset(18, 31), Size = UDim2.fromOffset(130, 12), Font = Enum.Font.Code, TextSize = 9, TextColor3 = C.dim })
local Nav = make("Frame", { Size = UDim2.new(1, -24, 1, -84), Position = UDim2.fromOffset(12, 70), BackgroundTransparency = 1, Parent = Sidebar })
list(Nav, Enum.FillDirection.Vertical, 4)

local Header = make("Frame", { Size = UDim2.new(1, -164, 0, 60), Position = UDim2.fromOffset(164, 0), BackgroundTransparency = 1, Parent = Window })
local HeaderTitle = text(Header, "ESP", { Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -130, 0, 20), Font = Enum.Font.GothamBold, TextSize = 18 })
local HeaderSub = text(Header, "Visualize players, NPCs and objects", { Position = UDim2.fromOffset(20, 37), Size = UDim2.new(1, -130, 0, 14), TextSize = 10, TextColor3 = C.sub })
local Close = button(Header, "Ã—", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -42, 0, 16), BackgroundColor3 = C.card, TextColor3 = C.bad, TextSize = 17 })
radius(Close, 7)
local Min = button(Header, "_", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -78, 0, 16), BackgroundColor3 = C.card, TextColor3 = C.sub, TextSize = 15 })
radius(Min, 7)
make("Frame", { Size = UDim2.new(1, -188, 0, 1), Position = UDim2.fromOffset(184, 59), BackgroundColor3 = C.border, BorderSizePixel = 0, Parent = Window })
local Pages = make("Frame", { Size = UDim2.new(1, -184, 1, -72), Position = UDim2.fromOffset(176, 68), BackgroundTransparency = 1, Parent = Window })

-- Drag window
local dragging, dragStart, winStart
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; winStart = Window.Position
    end
end)
connect(UIS.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - dragStart
        Window.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + d.X, winStart.Y.Scale, winStart.Y.Offset + d.Y)
    end
end)
connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Floating button
local Float = button(RootGui, "N", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(1, -66, .5, -24),
    BackgroundColor3 = C.accent,
    TextColor3 = C.bg,
    TextSize = 20,
    Font = Enum.Font.GothamBlack,
    Active = true,
    ZIndex = 50,
})
radius(Float, 24); outline(Float, C.text, 1)
text(Float, "NEXUS", { Position = UDim2.new(0, -14, 1, 3), Size = UDim2.fromOffset(76, 12), TextSize = 8, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 51 })
local floatDrag, floatStart, floatPos, floatMoved
Float.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        floatDrag = true; floatMoved = false; floatStart = input.Position; floatPos = Float.Position
    end
end)
connect(UIS.InputChanged, function(input)
    if not floatDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - floatStart
        if d.Magnitude > 6 then floatMoved = true end
        Float.Position = UDim2.new(floatPos.X.Scale, floatPos.X.Offset + d.X, floatPos.Y.Scale, floatPos.Y.Offset + d.Y)
    end
end)
connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then floatDrag = false end
end)

local function setOpen(v)
    State.open = v
    Window.Visible = v
    Float.Visible = not v
end
Float.MouseButton1Click:Connect(function() if not floatMoved then setOpen(true) end end)
Close.MouseButton1Click:Connect(function() setOpen(false) end)
Min.MouseButton1Click:Connect(function() setOpen(false) end)

-- UI primitives
local Tabs = {}
local function newPage(name, subtitle)
    local navButton = button(Nav, name, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left })
    radius(navButton, 7)
    local marker = make("Frame", { Size = UDim2.fromOffset(2, 0), Position = UDim2.fromOffset(0, 15), AnchorPoint = Vector2.new(0, .5), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = navButton })
    local page = make("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.border, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = Pages })
    local cols = {}
    for n = 1, 2 do
        cols[n] = make("Frame", { Size = UDim2.new(.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = n, Parent = page })
        list(cols[n], Enum.FillDirection.Vertical, 10)
    end
    local tab = { page = page, cols = cols, nav = navButton, marker = marker, name = name, subtitle = subtitle }
    function tab:card(title, side)
        local card = make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 1, Parent = self.cols[side or 1] })
        radius(card, 9); outline(card, C.border, 1)
        make("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card })
        list(card, Enum.FillDirection.Vertical, 7)
        text(card, string.upper(title), { Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.dim, LayoutOrder = 0 })
        return card
    end
    function tab:show()
        for _, t in pairs(Tabs) do
            t.page.Visible = false
            t.nav.BackgroundTransparency = 1
            t.nav.TextColor3 = C.sub
            t.marker.Size = UDim2.fromOffset(2, 0)
        end
        self.page.Visible = true
        self.nav.BackgroundTransparency = 0
        self.nav.BackgroundColor3 = C.card
        self.nav.TextColor3 = C.text
        self.marker.Size = UDim2.fromOffset(2, 18)
        HeaderTitle.Text = self.name
        HeaderSub.Text = self.subtitle
        State.selectedTab = self.name
    end
    navButton.MouseButton1Click:Connect(function() tab:show() end)
    Tabs[name] = tab
    return tab
end
local function addToggle(parent, labelText, key, callback)
    local row = make("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = parent })
    text(row, labelText, { Size = UDim2.new(1, -40, 1, 0), TextSize = 11.5 })
    local track = make("Frame", { Size = UDim2.fromOffset(32, 17), Position = UDim2.new(1, -32, .5, -8), BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = row })
    radius(track, 9)
    local dot = make("Frame", { Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.dim, BorderSizePixel = 0, Parent = track })
    radius(dot, 6)
    local hit = button(row, "", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
    local function apply(v, fire)
        State[key] = v == true
        tween(track, { BackgroundColor3 = State[key] and C.accent or C.bg })
        tween(dot, { Position = UDim2.fromOffset(State[key] and 18 or 3, 3), BackgroundColor3 = State[key] and C.bg or C.dim })
        if fire and callback then pcall(callback, State[key]) end
    end
    hit.MouseButton1Click:Connect(function() apply(not State[key], true) end)
    apply(State[key], false)
    return apply
end
local function addButton(parent, labelText, callback, danger)
    local b = button(parent, labelText, { Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = danger and Color3.fromRGB(66, 35, 43) or C.raised, TextColor3 = danger and C.bad or C.text, TextSize = 11.5 })
    radius(b, 7); outline(b, danger and Color3.fromRGB(100, 50, 61) or C.border, 1)
    b.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
    return b
end
local function addSlider(parent, labelText, key, min, max, decimals, callback)
    local wrap = make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = parent })
    text(wrap, labelText, { Size = UDim2.new(1, -60, 0, 15), TextSize = 11.5 })
    local value = text(wrap, "", { Position = UDim2.new(1, -58, 0, 0), Size = UDim2.fromOffset(58, 15), TextSize = 10, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.accent })
    local track = make("Frame", { Position = UDim2.new(0, 0, 0, 27), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = wrap })
    radius(track, 2)
    local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = track })
    radius(fill, 2)
    local hit = button(wrap, "", { Position = UDim2.new(0, 0, 0, 17), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 })
    local function apply(v, fire)
        v = math.clamp(round(v, decimals or 0), min, max)
        State[key] = v
        local a = (v - min) / math.max(max - min, .001)
        fill.Size = UDim2.fromScale(a, 1)
        value.Text = tostring(v)
        if fire and callback then pcall(callback, v) end
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local function update(pos)
            local a = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            apply(min + (max - min) * a, true)
        end
        update(input.Position)
        local move, ended
        move = UIS.InputChanged:Connect(function(i2)
            if i2.UserInputType == Enum.UserInputType.MouseMovement or i2.UserInputType == Enum.UserInputType.Touch then update(i2.Position) end
        end)
        ended = UIS.InputEnded:Connect(function(i2)
            if i2.UserInputType == input.UserInputType then move:Disconnect(); ended:Disconnect() end
        end)
    end)
    apply(State[key], false)
end
local function addLabel(parent, value, color)
    return text(parent, value, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 10.5, TextWrapped = true, TextColor3 = color or C.sub, TextYAlignment = Enum.TextYAlignment.Top })
end

-- ESP tab
local espTab = newPage("ESP", "Players, NPCs, objetos e status")
local espMain = espTab:card("Controle", 1)
addToggle(espMain, "ESP master", "esp", function(v) if v then refreshTargets() end end)
addToggle(espMain, "Players", "players", refreshTargets)
addToggle(espMain, "NPCs", "npcs", refreshTargets)
addToggle(espMain, "Objetos", "objects", refreshTargets)
addToggle(espMain, "Ignorar meu time", "teamCheck", refreshTargets)
addSlider(espMain, "Distancia maxima", "maxDistance", 50, 5000, 0)
local espVisual = espTab:card("Visual", 1)
addToggle(espVisual, "Caixas", "boxes")
addToggle(espVisual, "Nomes", "names")
addToggle(espVisual, "Distancia", "distance")
addToggle(espVisual, "Barra de vida", "health")
addToggle(espVisual, "Tracers", "tracers")
addToggle(espVisual, "Esqueleto", "skeleton")
addToggle(espVisual, "Chams", "chams")
addToggle(espVisual, "Setas fora da tela", "arrows")
local statusCard = espTab:card("Status exibido", 2)
addLabel(statusCard, "O ESP mostra o nome, distancia, HP, time, ferramenta e estado do humanoide quando existirem.")
addButton(statusCard, "Atualizar alvos agora", function() refreshTargets(); toast("ESP", "lista atualizada", C.good) end)
addButton(statusCard, "Limpar desenhos", function() clearDrawings() end)
local objectCard = espTab:card("Objetos", 2)
addLabel(objectCard, "O modo objetos marca Tools, Parts e Models encontrados no Workspace.")
addButton(objectCard, "Ativar objetos", function() State.objects = true; refreshTargets(); toast("Objetos", "ESP de objetos ligado", C.good) end)

-- Movement tab
local moveTab = newPage("Movimento", "Ferramentas locais de teste")
local moveCard = moveTab:card("Personagem", 1)
addToggle(moveCard, "WalkSpeed customizado", "speedOn")
addSlider(moveCard, "WalkSpeed", "speed", 8, 120, 0)
addToggle(moveCard, "JumpPower customizado", "jumpOn")
addSlider(moveCard, "JumpPower", "jump", 20, 180, 0)
addToggle(moveCard, "Noclip local", "noclip")
addToggle(moveCard, "Fly local", "fly")
local moveInfo = moveTab:card("Teleporte de teste", 2)
addLabel(moveInfo, "Use apenas em ambiente de desenvolvimento. O servidor continua sendo a autoridade.")
addButton(moveInfo, "Voltar ao spawn", function()
    local r = root(); local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if r and spawn then r.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
end)

-- Visual tab
local visualTab = newPage("Visual", "Iluminacao e camera")
local lightCard = visualTab:card("Iluminacao", 1)
addToggle(lightCard, "Fullbright", "fullbright", function(v)
    if v then Lighting.Brightness = 3; Lighting.Ambient = Color3.fromRGB(190,190,200); Lighting.OutdoorAmbient = Lighting.Ambient
    else Lighting.Brightness = Original.Brightness; Lighting.Ambient = Original.Ambient; Lighting.OutdoorAmbient = Original.OutdoorAmbient end
end)
addToggle(lightCard, "Sem neblina", "noFog", function(v)
    if v then Lighting.FogStart = 1e6; Lighting.FogEnd = 1e6 else Lighting.FogStart = Original.FogStart; Lighting.FogEnd = Original.FogEnd end
end)
addToggle(lightCard, "Sem particulas", "noParticles")
local cameraCard = visualTab:card("Camera", 2)
addToggle(cameraCard, "Crosshair", "crosshair")
addToggle(cameraCard, "Freecam", "freecam")
addSlider(cameraCard, "FOV", "fov", 40, 110, 0, function(v) if Camera then Camera.FieldOfView = v end end)

-- World tab
local worldTab = newPage("Mundo", "Explorer e exportacao")
local remoteCard = worldTab:card("Remotes do jogo", 1)
addLabel(remoteCard, "Lista somente os nomes e caminhos. O botao exporta tudo para o clipboard quando o ambiente permite.")
local remoteSearch = make("TextBox", { Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = C.bg, BorderSizePixel = 0, PlaceholderText = "filtrar por nome...", PlaceholderColor3 = C.dim, Text = "", TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 11, ClearTextOnFocus = false, Parent = remoteCard })
radius(remoteSearch, 7); outline(remoteSearch, C.border, 1)
local remoteList = make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.bg, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = remoteCard })
radius(remoteList, 7); list(remoteList, Enum.FillDirection.Vertical, 2)
local function allRemotes(filter)
    local result = {}
    for _, o in ipairs(game:GetDescendants()) do
        if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
            local full = o:GetFullName()
            if filter == "" or string.find(string.lower(full), string.lower(filter), 1, true) then table.insert(result, "[" .. o.ClassName .. "] " .. full) end
        end
    end
    table.sort(result)
    return result
end
local function drawRemoteList()
    for _, child in ipairs(remoteList:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    local items = allRemotes(remoteSearch.Text)
    for _, line in ipairs(items) do text(remoteList, line, { Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(4, 0), Font = Enum.Font.Code, TextSize = 10, TextColor3 = C.sub, TextTruncate = Enum.TextTruncate.AtEnd }) end
    if #items == 0 then text(remoteList, "nenhum remote encontrado", { Size = UDim2.new(1, 0, 0, 20), TextSize = 10, TextColor3 = C.dim }) end
end
remoteSearch.FocusLost:Connect(drawRemoteList)
addButton(remoteCard, "Recarregar lista", drawRemoteList)
addButton(remoteCard, "Exportar / copiar todos", function()
    local items = allRemotes("")
    local out = "NEXUS REMOTE EXPORT\nPlaceId: " .. tostring(game.PlaceId) .. "\nTotal: " .. tostring(#items) .. "\n\n" .. table.concat(items, "\n")
    if safeClipboard(out) then toast("Remotes", #items .. " itens copiados", C.good)
    else
        local export = make("TextBox", { Size = UDim2.fromOffset(560, 270), Position = UDim2.new(.5, -280, .5, -135), BackgroundColor3 = C.card, BorderSizePixel = 0, Text = out, TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, MultiLine = true, ClearTextOnFocus = false, Parent = RootGui })
        radius(export, 10); outline(export, C.border, 1); export:CaptureFocus(); export.SelectionStart = 1; export.CursorPosition = #out + 1
        toast("Remotes", "selecione e copie o texto", C.warn)
    end
end)
local worldCard = worldTab:card("Estado do cliente", 2)
local status = addLabel(worldCard, "carregando...")
addButton(worldCard, "Restaurar iluminacao", function()
    Lighting.Brightness = Original.Brightness; Lighting.Ambient = Original.Ambient; Lighting.OutdoorAmbient = Original.OutdoorAmbient; Lighting.FogStart = Original.FogStart; Lighting.FogEnd = Original.FogEnd; toast("Visual", "restaurado", C.good)
end)

-- Player tab
local playerTab = newPage("Players", "Busca e informacoes")
local playerCard = playerTab:card("Jogadores", 1)
local playerSearch = make("TextBox", { Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = C.bg, BorderSizePixel = 0, PlaceholderText = "buscar player...", PlaceholderColor3 = C.dim, Text = "", TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, Parent = playerCard })
radius(playerSearch, 7); outline(playerSearch, C.border, 1)
local playerList = make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = C.bg, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = playerCard })
radius(playerList, 7); list(playerList, Enum.FillDirection.Vertical, 2)
local function drawPlayers()
    for _, child in ipairs(playerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), string.lower(playerSearch.Text), 1, true) then
            local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            local b = button(playerList, p.Name .. "  |  HP " .. (h and tostring(math.floor(h.Health)) or "-"), { Size = UDim2.new(1, -6, 0, 24), BackgroundColor3 = p == LP and C.raised or C.bg, TextColor3 = p == LP and C.accent or C.sub, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Code, TextSize = 10 })
            b.MouseButton1Click:Connect(function() toast(p.Name, "UserId: " .. tostring(p.UserId) .. " | AccountAge: " .. tostring(p.AccountAge), C.good) end)
        end
    end
end
playerSearch.FocusLost:Connect(drawPlayers)
addButton(playerCard, "Atualizar jogadores", drawPlayers)
local playerInfo = playerTab:card("Dicas", 2)
addLabel(playerInfo, "Clique em um player para ver o UserId. A lista e somente informativa e nao altera outros jogadores.")

-- Drawers / ESP
local ESPRoot = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = WorldGui })
local Drawings = {}
local Targets = {}
local function line(parent)
    return make("Frame", { BackgroundColor3 = C.good, BorderSizePixel = 0, AnchorPoint = Vector2.new(.5, .5), Visible = false, Parent = parent })
end
local function setLine(obj, a, b, thickness, color)
    local d = b - a
    obj.Size = UDim2.fromOffset(math.max(d.Magnitude, 1), thickness or 1)
    obj.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    obj.Rotation = math.deg(math.atan2(d.Y, d.X))
    obj.BackgroundColor3 = color or C.good
    obj.Visible = true
end
local function newDrawing()
    local holder = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = ESPRoot })
    local box = make("Frame", { BackgroundTransparency = 1, BorderColor3 = C.good, BorderSizePixel = 1, Visible = false, Parent = holder })
    local name = text(holder, "", { Size = UDim2.fromOffset(240, 16), TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
    local info = text(holder, "", { Size = UDim2.fromOffset(180, 50), TextSize = 10, Font = Enum.Font.Code, TextColor3 = C.sub, Visible = false, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
    local tracer = line(holder)
    local bones = {}; for i = 1, 12 do bones[i] = line(holder) end
    return { holder = holder, box = box, name = name, info = info, tracer = tracer, bones = bones }
end
local function clearDrawings()
    for _, d in pairs(Drawings) do if d.holder then d.holder:Destroy() end end
    table.clear(Drawings)
end
local function refreshTargets()
    table.clear(Targets)
    if State.players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r and (not State.teamCheck or p.Team ~= LP.Team) then table.insert(Targets, { model = p.Character, root = r, hum = h, name = p.Name, kind = "Player" }) end
            end
        end
    end
    if State.npcs then
        for _, m in ipairs(Workspace:GetChildren()) do
            if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
                local h = m:FindFirstChildOfClass("Humanoid")
                local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                if h and r then table.insert(Targets, { model = m, root = r, hum = h, name = m.Name, kind = "NPC" }) end
            end
        end
    end
    if State.objects then
        for _, o in ipairs(Workspace:GetChildren()) do
            if o:IsA("BasePart") or o:IsA("Model") then
                local r = o:IsA("BasePart") and o or o.PrimaryPart
                if r and o ~= char() then table.insert(Targets, { model = o, root = r, name = o.Name, kind = "Object" }) end
            end
        end
    end
end
local function hide(d)
    d.holder.Visible = false; d.box.Visible = false; d.name.Visible = false; d.info.Visible = false; d.tracer.Visible = false
    for _, b in ipairs(d.bones) do b.Visible = false end
end
local function renderTarget(t)
    local d = Drawings[t.model]
    if not d then d = newDrawing(); Drawings[t.model] = d end
    if not t.model.Parent or not t.root.Parent then hide(d); return end
    local distance = (Camera.CFrame.Position - t.root.Position).Magnitude
    if distance > State.maxDistance then hide(d); return end
    local p, visible = Camera:WorldToViewportPoint(t.root.Position)
    if p.Z <= 0 then hide(d); return end
    d.holder.Visible = true
    local height = t.model:IsA("Model") and select(2, t.model:GetBoundingBox()).Y or t.root.Size.Y
    local top = Camera:WorldToViewportPoint(t.root.Position + Vector3.new(0, height / 2, 0))
    local bottom = Camera:WorldToViewportPoint(t.root.Position - Vector3.new(0, height / 2, 0))
    local h = math.max(math.abs(bottom.Y - top.Y), 12)
    local w = math.max(h * .42, 12)
    local x, y = p.X, (top.Y + bottom.Y) / 2
    local color = t.kind == "NPC" and C.warn or t.kind == "Object" and Color3.fromRGB(164, 150, 242) or C.good
    if State.boxes and t.kind ~= "Object" then
        d.box.Visible = true; d.box.Position = UDim2.fromOffset(x - w / 2, y - h / 2); d.box.Size = UDim2.fromOffset(w, h); d.box.BorderColor3 = color
    else d.box.Visible = false end
    d.name.Visible = State.names; d.name.Text = t.name; d.name.Position = UDim2.fromOffset(x - 120, y - h / 2 - 17); d.name.TextColor3 = color
    local info = {}
    if State.distance then table.insert(info, math.floor(distance) .. "m") end
    if State.health and t.hum then table.insert(info, "HP " .. math.floor(t.hum.Health) .. "/" .. math.floor(t.hum.MaxHealth)) end
    d.info.Visible = #info > 0; d.info.Text = table.concat(info, "  "); d.info.Position = UDim2.fromOffset(x - 90, y + h / 2 + 2)
    if State.tracers then setLine(d.tracer, Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y), Vector2.new(x, y), 1, color) else d.tracer.Visible = false end
end

-- runtime
connect(RunService.RenderStepped, function()
    local h = humanoid()
    if h and State.speedOn then h.WalkSpeed = State.speed end
    if h and State.jumpOn then h.JumpPower = State.jump end
    if State.noclip and char() then for _, p in ipairs(char():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    if State.fullbright then Lighting.Brightness = 3 end
    if State.noParticles then for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("ParticleEmitter") then o.Enabled = false end end end
    if State.esp then
        for _, t in ipairs(Targets) do pcall(renderTarget, t) end
    else
        for _, d in pairs(Drawings) do hide(d) end
    end
end)

connect(Players.PlayerAdded, function() task.wait(.5); refreshTargets(); drawPlayers() end)
connect(Players.PlayerRemoving, function() refreshTargets(); drawPlayers() end)
connect(UIS.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then setOpen(not State.open)
    elseif input.KeyCode == Enum.KeyCode.RightControl then State.esp = not State.esp; if State.esp then refreshTargets() end
    elseif input.KeyCode == Enum.KeyCode.End then
        State.esp = false; clearDrawings(); disconnectAll(); Lighting.Brightness = Original.Brightness; Lighting.Ambient = Original.Ambient; Lighting.OutdoorAmbient = Original.OutdoorAmbient; Lighting.FogStart = Original.FogStart; Lighting.FogEnd = Original.FogEnd; Lighting.GlobalShadows = Original.Shadows; Workspace.Gravity = Original.Gravity; if Camera then Camera.FieldOfView = Original.FOV end; RootGui:Destroy(); WorldGui:Destroy()
    end
end)

-- Initial state
drawRemoteList()
drawPlayers()
refreshTargets()
Tabs.ESP:show()
toast("Nexus v2", "painel carregado", C.good)

-- status refresh
local started = os.clock()
task.spawn(function()
    while RootGui.Parent do
        task.wait(.6)
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        if status and status.Parent then status.Text = "Uptime: " .. math.floor(os.clock() - started) .. "s\nPlayers: " .. #Players:GetPlayers() .. "\nPing: " .. ping .. " ms\nTargets: " .. #Targets end
    end
end)
